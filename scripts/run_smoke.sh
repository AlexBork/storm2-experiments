#!/bin/sh
# Check that everything works: run all configurations of every experiment on two
# small benchmarks with a time limit of 60 seconds, post-process the logs, check
# the results with common/check_results.py and build the figures in
# plots/latex/main.pdf, like run_all.sh does for all benchmarks. Fails if a run has an
# incorrect result or none at all, e.g. because the output of a tool changed.
# Takes about 5 to 10 minutes. The options are passed on to common/run.py, e.g.
#   scripts/run_smoke.sh --jobs 2
# The logs and results go to the same place as those of run_all.sh, which
# overwrites all of them.
set -eu
cd "$(dirname "$0")/.."
run_options="$*"
failed=""

experiment() {  # experiment DIRECTORY BENCHMARKS [POSTPROCESS OPTIONS]
  directory=$1
  benchmarks=$2
  shift 2
  echo "== $(date): $directory"
  cd "experiments/$directory"
  python3 ../../scripts/common/generate_invocations.py --out inv.json --logdir experiments/logs \
    --benchmarks "$benchmarks" --timelimit 60
  # shellcheck disable=SC2086
  python3 ../../scripts/common/run.py inv.json $run_options
  python3 ../../scripts/common/postprocess.py "$@" experiments/logs experiments/results
  python3 ../../scripts/common/check_results.py experiments/results || failed="$failed $directory"
  cd ../..
}

experiment comparison_tools_bisim consensus.4-4.c2,tireworld.17.goal
experiment imdps consensus.4-4.c2.absolute-005,zeroconf.20-2-false.correct_max.absolute-25 \
  --agreement --absolute
experiment pomdp grid_grid_rewmin_sl0.1,refuel_refuel_prbmax_N06

echo "== $(date): figures"
scripts/build_figures.sh

if [ -n "$failed" ]; then
  echo "== results with problems in:$failed" >&2
  exit 1
fi
echo "== all results checked"
