#!/bin/sh
# Run experiments/docker/run_minimal.sh, the representative experiments with 2
# physical cores and 8 GiB per run, in a container and copy its figures to minimal.pdf
# and its logs and results to minimal/ in the current directory, see
# experiments/docker/run_in_container.sh. Takes hours; the runs go on when the
# terminal is closed. The runs take place one at a time; with -p, as many at the same
# time as fit into the machine. Other options are passed on to run.py, e.g.
#   scripts/3_minimal.sh -p
# Fails like run_minimal.sh if a run has an incorrect result or none at all.
exec "$(dirname "$0")/../experiments/docker/run_in_container.sh" minimal "$@"
