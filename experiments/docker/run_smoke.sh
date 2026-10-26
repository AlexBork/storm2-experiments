#!/bin/sh
# Check that everything works and that the machine can run an experiment set: run
# every configuration on the one small benchmark of the index-smoke.json of every
# experiment, with a time limit of 60 seconds, but with the physical cores, the memory
# limit and the memory of the decision diagram libraries per run of the given set:
#   minimal          2 cores,  8 GiB, 4 GiB
#   representative   4 cores, 16 GiB, 8 GiB
#   full             4 cores, 32 GiB, 8 GiB
# Fails if a run has an incorrect result or none at all, e.g. because the output of a
# tool changed, or if the machine is too small for a single run of the set. Takes about
# 8 minutes with one run at a time. Every experiment writes its logs and results to
# experiments/smoke/ of its directory. The other options are passed on to
# common/run.py, e.g.
#   docker/run_smoke.sh representative --parallel
set -eu
target=${1:-}
case $target in
  minimal) cores=2 memlimit=8 ddmem=4 ;;
  representative) cores=4 memlimit=16 ddmem=8 ;;
  full) cores=4 memlimit=32 ddmem=8 ;;
  *) echo "usage: docker/run_smoke.sh minimal|representative|full [RUN.PY OPTIONS]" >&2
     exit 2 ;;
esac
shift
echo "== smoke test for the $target experiments: $cores physical cores and $memlimit GiB of memory per run"
SET=smoke TIMELIMIT=${TIMELIMIT:-60} MEMLIMIT=$memlimit CORES=$cores DDMEM=$ddmem \
  exec "$(dirname "$0")/common/run_set.sh" "$@"
