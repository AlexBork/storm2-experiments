#!/bin/sh
# Create the artifact zip, by default storm2-experiments-artifact.zip in the current
# directory: the committed files of the repository plus the saved image (see
# 5_build.sh), the Modest Toolset zips and the compressed interval MDPs.
#   ./6_create_artifact.sh [FILE]
set -eu
out=$(realpath "${1:-storm2-experiments-artifact.zip}")
cd "$(dirname "$0")"

echo "== $(date): checking the repository, the image and the large files"
if [ -n "$(git status --porcelain)" ]; then
  echo "uncommitted changes, commit them first" >&2
  exit 1
fi
for file in storm2-experiments.tar.gz experiments/imdps/benchmarks.tar.xz docker/modest/*.zip; do
  [ -f "$file" ] || { echo "missing $file" >&2; exit 1; }
done
# The image contains the whole repository, so it must be saved after the last commit
if [ "$(stat -c %Y storm2-experiments.tar.gz)" -lt "$(git log -1 --format=%ct)" ]; then
  echo "storm2-experiments.tar.gz is older than the last commit, rebuild it with 5_build.sh" >&2
  exit 1
fi

# Run from the parent so that everything is below storm2-experiments/ in the zip;
# the already compressed files are stored as they are
repo=$(basename "$PWD")
echo "== $(date): writing $(git ls-files | wc -l) committed files and $(du -ch storm2-experiments.tar.gz experiments/imdps/benchmarks.tar.xz docker/modest/*.zip | tail -1 | cut -f1) of large files to $out"
rm -f "$out"
{ git ls-files; ls storm2-experiments.tar.gz experiments/imdps/benchmarks.tar.xz docker/modest/*.zip; } \
  | sed "s|^|$repo/|" | (cd .. && zip -q -n .gz:.xz:.zip "$out" -@)
echo "== $(date): testing $out"
unzip -tq "$out"
echo "== $(date): done, $(du -h "$out" | cut -f1) in $out"
