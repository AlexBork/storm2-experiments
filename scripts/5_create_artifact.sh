#!/bin/sh
# Create the artifact zip, by default storm2-experiments-artifact.zip in the current
# directory: the committed files of the repository, including those of the
# submodules storm/ and stormpy/, plus the saved image experiments/storm2-experiments.tar.gz
# (see experiments/build_docker.sh), the Modest Toolset zips and the compressed
# interval MDPs.
#   scripts/5_create_artifact.sh [FILE]
set -eu
out=$(realpath "${1:-storm2-experiments-artifact.zip}")
cd "$(dirname "$0")/.."
image=experiments/storm2-experiments.tar.gz
large="$image experiments/experiments/imdps/benchmarks.tar.xz experiments/docker/modest/*.zip"

echo "== $(date): checking the repository, the submodules, the image and the large files"
if [ -n "$(git status --porcelain)" ]; then
  echo "uncommitted changes, commit them first" >&2
  exit 1
fi
# A submodule that is not checked out, or not at its committed commit, would be
# missing from the zip or have other files in it
if git submodule status | grep -q '^[-+U]'; then
  git submodule status >&2
  echo "submodules not checked out at their commits, run git submodule update --init" >&2
  exit 1
fi
# shellcheck disable=SC2086
for file in $large; do
  [ -f "$file" ] || { echo "missing $file" >&2; exit 1; }
done
# The image contains the whole of experiments/, so it must be saved after the last commit
if [ "$(stat -c %Y $image)" -lt "$(git log -1 --format=%ct)" ]; then
  echo "$image is older than the last commit, rebuild it with experiments/build_docker.sh" >&2
  exit 1
fi

# Run from the parent so that everything is below storm2-experiments/ in the zip;
# the already compressed files are stored as they are
repo=$(basename "$PWD")
# shellcheck disable=SC2086
echo "== $(date): writing $(git ls-files --recurse-submodules | wc -l) committed files and $(du -ch $large | tail -1 | cut -f1) of large files to $out"
rm -f "$out"
# shellcheck disable=SC2086
{ git ls-files --recurse-submodules; ls $large; } \
  | sed "s|^|$repo/|" | (cd .. && zip -q -n .gz:.xz:.zip "$out" -@)
echo "== $(date): testing $out"
unzip -tq "$out"
echo "== $(date): done, $(du -h "$out" | cut -f1) in $out"
