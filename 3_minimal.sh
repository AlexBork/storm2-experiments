#!/bin/sh
# Run scripts/run_minimal.sh, the representative experiments with 2 physical cores and
# 8 GiB per run, in a container and copy its figures to minimal.pdf and its logs and
# results to minimal/ in the current directory, see docker/run_in_container.sh. Takes
# hours; the runs go on when the terminal is closed. The options are passed on to
# run.py, e.g.
#   ./3_minimal.sh --jobs 1
# Fails like run_minimal.sh if a run has an incorrect result or none at all.
exec "$(dirname "$0")/docker/run_in_container.sh" minimal "$@"
