#!/bin/sh
# Run all experiments one after the other, post-process their logs and build the
# figures in latex/main.pdf. The options are passed on to common/run.py, which by
# default runs as many invocations at once as fit into the machine, e.g.
#   ./run_all.sh --jobs 4
# Every experiment writes its logs and results to its experiments/ directory.
set -eu
cd "$(dirname "$0")"
run_options="$*"

experiment() {  # experiment DIRECTORY [POSTPROCESS OPTIONS]
  directory=$1
  shift
  echo "== $(date): $directory"
  cd "$directory"
  python3 ../common/generate_invocations.py --out inv.json --logdir experiments/logs
  # shellcheck disable=SC2086
  python3 ../common/run.py inv.json $run_options
  python3 ../common/postprocess.py "$@" experiments/logs experiments/results
  cd ..
}

experiment comparison_tools_bisim
experiment imdps --agreement --absolute
experiment pomdp

echo "== $(date): figures"
./build_figures.sh
