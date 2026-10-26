#!/bin/sh
# Run scripts/run_representative.sh in a container and copy its figures to
# representative.pdf and its logs and results to representative/ in the current
# directory, see docker/run_in_container.sh. Takes hours; the runs go on when the
# terminal is closed. The options are passed on to run.py, e.g.
#   ./3_representative.sh --jobs 1
# Fails like run_representative.sh if a run has an incorrect result or none at all.
exec "$(dirname "$0")/docker/run_in_container.sh" representative "$@"
