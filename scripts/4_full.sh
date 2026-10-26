#!/bin/sh
# Run experiments/docker/run_all.sh in a container and copy its figures to full.pdf
# and its logs and results to full/ in the current directory, see
# experiments/docker/run_in_container.sh. Takes days on a small machine; the runs go
# on when the terminal is closed. The options are passed on to run.py, e.g.
#   scripts/4_full.sh --jobs 1
# Fails like run_all.sh if a run has an incorrect result or none at all.
exec "$(dirname "$0")/../experiments/docker/run_in_container.sh" full "$@"
