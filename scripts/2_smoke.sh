#!/bin/sh
# Check that everything works and that the machine can run an experiment set: run
# experiments/docker/run_smoke.sh SET in a container, with the cores and memory per run
# of the set SET (minimal, representative or full), and copy its figures to
# smoke-SET.pdf and its logs and results to smoke-SET/ in the current directory, see
# experiments/docker/run_in_container.sh. The runs take place one at a time; with -p,
# as many at the same time as fit into the machine. Other options are passed on to
# run.py, e.g.
#   scripts/2_smoke.sh representative -p
# Fails like run_smoke.sh if a run has an incorrect result or none at all.
case ${1:-} in
  minimal|representative|full) ;;
  *) echo "usage: scripts/2_smoke.sh minimal|representative|full [-p]" >&2
     exit 2 ;;
esac
set=$1
shift
exec "$(dirname "$0")/../experiments/docker/run_in_container.sh" "smoke-$set" "$@"
