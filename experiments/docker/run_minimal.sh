#!/bin/sh
# Run the representative set of the experiments (see run_representative.sh) on a
# minimal machine: the benchmarks of the index-representative.json of every
# experiment with a time limit of 90 seconds, but with 2 physical cores, a memory
# limit of 8 GiB and 4 GiB for the decision diagram libraries per run instead of 4
# cores, 16 GiB and 8 GiB. Every experiment writes its logs and results to
# experiments/minimal/ of its directory. The limits can be changed, e.g.
# TIMELIMIT=60 docker/run_minimal.sh, and the options are passed on to
# common/run.py, e.g.
#   docker/run_minimal.sh --parallel
set -eu
SET=minimal INDEX=representative TIMELIMIT=${TIMELIMIT:-90} MEMLIMIT=${MEMLIMIT:-8} CORES=${CORES:-2} \
  DDMEM=${DDMEM:-4} exec "$(dirname "$0")/common/run_set.sh" "$@"
