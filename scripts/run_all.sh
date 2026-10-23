#!/bin/sh
# Run all experiments one after the other, post-process their logs and build the
# figures in plots/latex/main.pdf. The options are passed on to common/run.py, which by
# default runs as many invocations at once as fit into the machine, e.g.
#   scripts/run_all.sh --jobs 4
# Every experiment writes its logs and results to its experiments/ directory.
set -eu
cd "$(dirname "$0")/.."
run_options="$*"

experiment() {  # experiment DIRECTORY [POSTPROCESS OPTIONS]
  directory=$1
  shift
  echo "== $(date): $directory"
  cd "experiments/$directory"
  python3 ../../scripts/common/generate_invocations.py --out inv.json --logdir experiments/logs
  # shellcheck disable=SC2086
  python3 ../../scripts/common/run.py inv.json $run_options
  python3 ../../scripts/common/postprocess.py "$@" experiments/logs experiments/results
  cd ../..
}

experiment comparison_tools_bisim
experiment imdps --agreement --absolute
experiment pomdp

echo "== $(date): figures"
scripts/build_figures.sh
