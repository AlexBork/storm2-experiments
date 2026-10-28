#!/bin/sh
# Run docker/run_SET.sh in a container storm2-SET of the image storm2-experiments
# (see scripts/1_load.sh of the artifact), copy what it produces to the current
# directory and remove the container. Used by scripts/2_smoke.sh and 3_run.sh of
# the artifact; the set full is
# that of docker/run_all.sh, and the set smoke-TARGET that of docker/run_smoke.sh
# TARGET, the smoke test with the cores and memory of the set TARGET.
#   experiments/docker/run_in_container.sh SET [-p] [RUN.PY OPTIONS]
# The runs take place one at a time; with -p, as many at the same time as fit into
# the cores and the memory of the machine (run.py --parallel).
# Writes to the current directory:
#   SET.pdf                    the figures, also in SET/
#   SET/output.log             the output of the container
#   SET/EXPERIMENT/logs/       the logs of every run of every experiment
#   SET/EXPERIMENT/results/    its post-processed results
#   SET/EXPERIMENT/steps.log   the output of generating its runs and post-processing
#   SET/EXPERIMENT/check.log   the output of check_results.py
#   SET/data/                  the csv files the figures are made from
#   SET/figures.log            the output of building the figures
# If SET or SET.pdf exists already, asks whether to replace it.
# The container runs in the background, so that the runs go on when this script or
# the terminal is closed; then run the same command again once it has stopped
# (docker wait storm2-SET), which only copies the results.
set -eu
set=$1
shift
if [ "${1:-}" = -p ]; then
  shift
  set -- --parallel "$@"
fi
name=storm2-$set
image=/opt/storm2-experiments
# The logs and results of every experiment are in experiments/SET/ of its directory,
# those of run_all.sh directly in experiments/
case $set in
  full) script=run_all.sh results=experiments ;;
  smoke-*) script=run_smoke.sh results=experiments/smoke
           set -- "${set#smoke-}" "$@" ;;
  *) script=run_$set.sh results=experiments/$set ;;
esac

if [ -e "$set" ] || [ -e "$set.pdf" ]; then
  echo "$PWD/$set or $set.pdf exists already, from an earlier run" >&2
  # Only asks in a terminal; otherwise nothing is removed
  [ -t 0 ] || { echo "move it away first" >&2; exit 1; }
  printf 'replace it? [y/N] ' >&2
  read -r answer
  case $answer in
    y|Y|yes) rm -rf "$set" "$set.pdf" ;;
    *) echo "move it away first" >&2; exit 1 ;;
  esac
fi

if docker container inspect "$name" >/dev/null 2>&1; then
  echo "== continuing with the container $name of an earlier run"
else
  docker run -d --privileged --cap-drop=all --name "$name" storm2-experiments \
    "docker/$script" "$@" >/dev/null
fi
docker logs -f "$name" || true
status=$(docker wait "$name")

mkdir "$set"
docker logs "$name" > "$set/output.log" 2>&1
for experiment in mdp imdp pomdp; do
  docker cp -q "$name:$image/$experiment/$results" "$set/$experiment" \
    || echo "no logs and results of $experiment" >&2
done
docker cp -q "$name:$image/docker/plots/latex/data" "$set/data" || echo "no figure data" >&2
docker cp -q "$name:$image/docker/plots/latex/build.log" "$set/figures.log" 2>/dev/null || true
docker cp -q "$name:$image/docker/plots/latex/main.pdf" "$set.pdf" && cp "$set.pdf" "$set/" \
  || echo "no figures" >&2
docker rm "$name" >/dev/null
echo "== results in $PWD/$set/, figures in $PWD/$set.pdf"
exit "$status"
