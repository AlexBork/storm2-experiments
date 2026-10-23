#!/bin/sh
# Run a set of benchmarks of all experiments one after the other, post-process and
# check their logs with check_results.py, and build the figures in
# plots/latex/main.pdf. Used by scripts/run_all.sh, run_quick.sh and run_smoke.sh,
# which set:
#   SET        the benchmarks of index-SET.json of every experiment, with the logs
#              and results in experiments/SET/ of its directory; if empty, those of
#              index.json, with the logs and results in experiments/
#   TIMELIMIT  the time limit of every run, in seconds
#   MEMLIMIT   the memory limit of every run, in GiB
# A new run replaces the logs and results of the set. The options are passed on to
# run.py. Fails if a run has an incorrect result or none at all.
set -eu
: "${TIMELIMIT:?}" "${MEMLIMIT:?}"
SET=${SET:-}
index=index${SET:+-$SET}.json
out=experiments${SET:+/$SET}
invocations=inv${SET:+-$SET}.json
cd "$(dirname "$0")/../.."
run_options="$*"
failed=""

experiment() {  # experiment DIRECTORY [POSTPROCESS OPTIONS]
  directory=$1
  shift
  echo "== $(date): $directory"
  cd "experiments/$directory"
  rm -rf "$out/logs" "$out/results"
  python3 ../../scripts/common/generate_invocations.py --out "$invocations" \
    --index "$index" --logdir "$out/logs" --timelimit "$TIMELIMIT"
  # shellcheck disable=SC2086
  python3 ../../scripts/common/run.py "$invocations" --memlimit "$MEMLIMIT" $run_options
  python3 ../../scripts/common/postprocess.py "$@" "$out/logs" "$out/results"
  python3 ../../scripts/common/check_results.py "$out/results" || failed="$failed $directory"
  cd ../..
}

experiment comparison_tools_bisim
experiment imdps --agreement --absolute
experiment pomdp

echo "== $(date): figures"
scripts/build_figures.sh -r "$out/results"

if [ -n "$failed" ]; then
  echo "== results with problems in:$failed" >&2
  exit 1
fi
echo "== all results checked"
