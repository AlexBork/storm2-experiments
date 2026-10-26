#!/bin/sh
# Build the Docker image of the experiments for amd64 and arm64 and save it to a
# file, by default storm2-experiments.tar.gz next to this script, where
# scripts/1_load.sh and scripts/5_create_artifact.sh expect it. PLATFORMS selects the
# architectures; other options are passed on to docker buildx build, e.g.
#   PLATFORMS=linux/amd64 experiments/build_docker.sh -o /tmp/image.tar.gz --build-arg generate_workers=4
# Building for another architecture than that of the machine needs QEMU, e.g.
#   docker run --privileged --rm tonistiigi/binfmt --install arm64
set -eu
out=$(cd "$(dirname "$0")" && pwd)/storm2-experiments.tar.gz
if [ "${1:-}" = "-o" ]; then
  out=$(realpath "$2")
  shift 2
fi
cd "$(dirname "$0")"

echo "== $(date): unpacking the Modest Toolset"
(cd docker/modest && sha256sum -c SHA256SUMS)
for arch in amd64:x64 arm64:arm64; do
  dir=docker/modest/${arch%%:*}
  rm -rf "$dir" && mkdir "$dir"
  unzip -q docker/modest/Modest-Toolset-*-linux-${arch##*:}.zip -d "$dir"
done

# The interval MDPs of imdp come with the artifact; the build only generates
# those still missing. The archive stores them below experiments/imdps/benchmarks/,
# the path of the experiment when the archive was made, so they are moved to
# imdp/benchmarks/ while unpacking (GNU tar).
if [ -f imdp/benchmarks.tar.xz ]; then
  echo "== $(date): unpacking the interval MDPs of imdp"
  XZ_OPT=-T0 tar -xJf imdp/benchmarks.tar.xz --skip-old-files \
    --transform 's|^experiments/imdps/|imdp/|'
fi

echo "== $(date): building the image"
# The MDP and POMDP benchmarks are in ../examples/, outside of the build context
docker buildx build --platform "${PLATFORMS:-linux/amd64,linux/arm64}" -t storm2-experiments --load \
  --build-context mdp_benchmarks=../examples/mdp_benchmarks \
  --build-context pomdp_benchmarks=../examples/pomdp_benchmarks "$@" .

echo "== $(date): saving the image to $out"
docker save storm2-experiments | gzip > "$out"
ls -l "$out"
