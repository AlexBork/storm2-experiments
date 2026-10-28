#!/bin/sh
# Run the experiment set SET (minimal, representative or full) in a container and copy
# its figures to SET.pdf and its logs and results to SET/ in the current directory,
# see experiments/docker/run_in_container.sh: experiments/docker/run_minimal.sh, the
# representative experiments with 2 physical cores and 8 GiB per run,
# run_representative.sh or run_all.sh. Takes hours, the full set days on a small
# machine; the runs go on when the terminal is closed. The runs take place one at a
# time; with -p, as many at the same time as fit into the machine. Other options are
# passed on to run.py, e.g.
#   scripts/3_run.sh representative -p
# Fails if a run has an incorrect result or none at all.
case ${1:-} in
  minimal|representative|full) ;;
  *) echo "usage: scripts/3_run.sh minimal|representative|full [-p]" >&2
     exit 2 ;;
esac
set=$1
shift
exec "$(dirname "$0")/../experiments/docker/run_in_container.sh" "$set" "$@"
