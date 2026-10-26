#!/bin/sh
# Check that everything works: run every configuration on the one small benchmark
# of the index-smoke.json of every experiment, with a time limit of 60 seconds and a
# memory limit of 16 GiB per run, like run_all.sh. Fails if a run has an incorrect
# result or none at all, e.g. because the output of a tool changed. Takes about 8
# minutes with one run at a time. Every experiment writes its logs and results to experiments/smoke/ of
# its directory. The options are passed on to common/run.py, e.g.
#   docker/run_smoke.sh --parallel
set -eu
SET=smoke TIMELIMIT=${TIMELIMIT:-60} MEMLIMIT=${MEMLIMIT:-16} exec "$(dirname "$0")/common/run_set.sh" "$@"
