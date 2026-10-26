#!/bin/sh
# Run experiments/docker/run_smoke.sh in a container and copy its figures to
# smoke.pdf and its logs and results to smoke/ in the current directory, see
# experiments/docker/run_in_container.sh. The options are passed on to run.py, e.g.
#   scripts/2_smoke.sh --jobs 1
# Fails like run_smoke.sh if a run has an incorrect result or none at all.
exec "$(dirname "$0")/../experiments/docker/run_in_container.sh" smoke "$@"
