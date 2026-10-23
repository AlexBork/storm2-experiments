#!/bin/sh
# Create the artifact zip, by default storm2-experiments-artifact.zip in the current
# directory: the committed repository without .git, the saved image (-i, by default
# storm2-experiments.tar.gz in the current directory, see docker/build.sh), the zips
# of the Modest Toolset and the interval MDPs of imdps in
# experiments/imdps/benchmarks.tar.xz, which docker/build.sh unpacks. Loading the
# image is enough to run the artifact; the rest is for rebuilding it.
#   scripts/create_artifact.sh [-o FILE] [-i IMAGE]
set -eu
out=$PWD/storm2-experiments-artifact.zip
image=$PWD/storm2-experiments.tar.gz
while getopts o:i: opt; do
  case $opt in
    o) out=$(realpath "$OPTARG") ;;
    i) image=$(realpath "$OPTARG") ;;
    *) exit 1 ;;
  esac
done
cd "$(dirname "$0")/.."

# Only committed files go into the artifact
if [ -n "$(git status --porcelain)" ]; then
  echo "uncommitted changes, commit or stash them first:" >&2
  git status --short >&2
  exit 1
fi
if [ ! -f "$image" ]; then
  echo "no saved image $image, make it with docker/build.sh or pass it with -i" >&2
  exit 1
fi
if [ "$(stat -c %Y "$image")" -lt "$(git log -1 --format=%ct)" ]; then
  echo "warning: $image is older than the last commit, rebuild it with docker/build.sh if that commit changes the image" >&2
fi
(cd docker/modest && sha256sum -c SHA256SUMS)

# The models in experiments/imdps/benchmarks/index.json, compressed again only when
# the index changes; delete the archive to compress them again
models=experiments/imdps/benchmarks.tar.xz
if [ ! -f "$models" ] || [ experiments/imdps/benchmarks/index.json -nt "$models" ]; then
  echo "== $(date): compressing the interval MDPs of imdps to $models"
  python3 -I -c 'import json, pathlib, sys
root = pathlib.Path("experiments/imdps/benchmarks")
files = []
for name, b in json.load(open(root / "index.json")).items():
    found = sorted(root.glob(b["bundle"] + ".*"))
    if not found:
        sys.exit(f"no files for {name}, generate them first (see experiments/imdps/README.md)")
    files += found
print("\n".join(map(str, files)))' > "$models.list"
  XZ_OPT="-T0 -6" tar -cJf "$models.tmp" -T "$models.list"
  mv "$models.tmp" "$models"
  rm "$models.list"
fi

# The repository below storm2-experiments/, with links to the large files, which
# zip stores as the files themselves; compressed files are stored as they are
echo "== $(date): writing $out"
stage=$(mktemp -d "$(dirname "$out")/artifact.XXXXXX")
trap 'rm -rf "$stage"' EXIT
git archive --prefix=storm2-experiments/ HEAD | tar -x -C "$stage"
ln -s "$PWD/$models" "$stage/storm2-experiments/$models"
for zip in docker/modest/*.zip; do
  ln -s "$PWD/$zip" "$stage/storm2-experiments/$zip"
done
ln -s "$image" "$stage/storm2-experiments/storm2-experiments.tar.gz"
rm -f "$out.tmp"
(cd "$stage" && zip -r -q -n .gz:.xz:.zip "$out.tmp" storm2-experiments)
mv "$out.tmp" "$out"

echo "== $(date): checking $out"
unzip -tq "$out"
ls -l "$out"
