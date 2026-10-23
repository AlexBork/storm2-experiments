#!/bin/sh
# Build the Docker image of the experiments for amd64 and arm64 and save it to a
# file, by default storm2-experiments.tar.gz in the current directory. PLATFORMS
# selects the architectures; other options are passed on to docker buildx build, e.g.
#   PLATFORMS=linux/amd64 docker/build.sh -o /tmp/image.tar.gz --build-arg generate_workers=4
# Building for another architecture than that of the machine needs QEMU, e.g.
#   docker run --privileged --rm tonistiigi/binfmt --install arm64
set -eu
out=$PWD/storm2-experiments.tar.gz
if [ "${1:-}" = "-o" ]; then
  out=$(realpath "$2")
  shift 2
fi
cd "$(dirname "$0")/.."

echo "== $(date): unpacking the Modest Toolset"
(cd docker/modest && sha256sum -c SHA256SUMS)
for arch in amd64:x64 arm64:arm64; do
  dir=docker/modest/${arch%%:*}
  rm -rf "$dir" && mkdir "$dir"
  unzip -q docker/modest/Modest-Toolset-*-linux-${arch##*:}.zip -d "$dir"
done

echo "== $(date): building the image"
docker buildx build --platform "${PLATFORMS:-linux/amd64,linux/arm64}" -t storm2-experiments --load "$@" .

echo "== $(date): saving the image to $out"
docker save storm2-experiments | gzip > "$out"
ls -l "$out"
