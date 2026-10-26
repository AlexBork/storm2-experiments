#!/bin/sh
# Run a representative set of the experiments, like run_all.sh but on the benchmarks
# of the index-representative.json of every experiment, with a time limit of 90
# seconds and a memory limit of 16 GiB per run: about 3 hours with 2 runs at a time.
# The benchmarks are chosen such that about as many runs time out as in run_all.sh.
# Every experiment writes its logs and results to experiments/representative/ of its
# directory. The limits can be changed, e.g. TIMELIMIT=60 docker/run_representative.sh,
# and the options are passed on to common/run.py, e.g.
#   docker/run_representative.sh --jobs 2
set -eu
SET=representative TIMELIMIT=${TIMELIMIT:-90} MEMLIMIT=${MEMLIMIT:-16} exec "$(dirname "$0")/common/run_set.sh" "$@"
