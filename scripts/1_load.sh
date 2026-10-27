#!/bin/sh
# Load the saved images of the artifact, by default experiments/storm2-experiments.tar.gz
# (see scripts/4_build_docker.sh), into Docker: storm2-experiments for the experiments
# and storm2-tools for Storm, stormpy and the notebooks (see TOOLS.md). The images are
# for amd64 and arm64, which needs Docker's containerd image store ("Use containerd
# for pulling and storing images" in the Docker settings).
#   scripts/1_load.sh [FILE]
set -eu
image=$(realpath "${1:-$(dirname "$0")/../experiments/storm2-experiments.tar.gz}")

command -v docker >/dev/null || { echo "docker not found, install Docker first" >&2; exit 1; }
[ -f "$image" ] || { echo "missing $image" >&2; exit 1; }
case $(docker info --format '{{.DriverStatus}}') in
  *io.containerd.snapshotter*) ;;
  *) echo "Docker does not use the containerd image store, which the multi-platform" \
          "image needs: enable \"Use containerd for pulling and storing images\" in the" \
          "Docker settings, or \"features\": {\"containerd-snapshotter\": true} in" \
          "/etc/docker/daemon.json for Docker Engine, and restart Docker" >&2
     exit 1 ;;
esac

echo "== $(date): loading $image"
docker load -i "$image"
for name in storm2-experiments storm2-tools; do
  docker image inspect $name --format "loaded $name for {{.Os}}/{{.Architecture}}"
done
