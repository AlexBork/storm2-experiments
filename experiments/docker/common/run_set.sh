#!/bin/sh
# Run a set of benchmarks of all experiments one after the other, post-process and
# check their logs with check_results.py, and build the figures in
# docker/plots/latex/main.pdf. Used by docker/run_all.sh, run_representative.sh,
# run_minimal.sh and run_smoke.sh, which set:
#   SET        the benchmarks of index-SET.json of every experiment, with the logs
#              and results in experiments/SET/ of its directory; if empty, those of
#              index.json, with the logs and results in experiments/
#   INDEX      the benchmarks of index-INDEX.json instead, e.g. those of another set
#   TIMELIMIT  the time limit of every run, in seconds
#   MEMLIMIT   the memory limit of every run, in GiB
#   CORES      the physical cores of every run (default: 4)
#   DDMEM      the memory of the decision diagram libraries of every run, in GiB
#              (default: 8)
# A new run replaces the logs and results of the set. The options are passed on to
# run.py. Fails if a run has an incorrect result or none at all.
set -eu
: "${TIMELIMIT:?}" "${MEMLIMIT:?}"
SET=${SET:-}
INDEX=${INDEX:-$SET}
CORES=${CORES:-4}
DDMEM=${DDMEM:-8}
index=index${INDEX:+-$INDEX}.json
out=experiments${SET:+/$SET}
invocations=inv${SET:+-$SET}.json
cd "$(dirname "$0")/../.."
run_options="$*"
failed=""
experiments=3
number=0
start=$(date +%s)

duration() {  # duration SINCE: the time since SINCE (seconds since the epoch), e.g. 1h 02m 03s
  seconds=$(($(date +%s) - $1))
  printf '%dh %02dm %02ds' $((seconds / 3600)) $((seconds % 3600 / 60)) $((seconds % 60))
}

experiment() {  # experiment DIRECTORY [POSTPROCESS OPTIONS]
  directory=$1
  shift
  number=$((number + 1))
  experiment_start=$(date +%s)
  echo "== $(date): running experiment $number/$experiments: $directory"
  cd "$directory"
  rm -rf "$out/logs" "$out/results"
  python3 ../docker/common/generate_invocations.py --out "$invocations" \
    --index "$index" --logdir "$out/logs" --timelimit "$TIMELIMIT"
  # shellcheck disable=SC2086
  python3 ../docker/common/run.py "$invocations" --memlimit "$MEMLIMIT" \
    --cores-per-run "$CORES" --ddmem "$DDMEM" $run_options
  python3 ../docker/common/postprocess.py "$@" "$out/logs" "$out/results"
  python3 ../docker/common/check_results.py "$out/results" || failed="$failed $directory"
  cd ..
  echo "== $(date): finished experiment $number/$experiments: $directory in" \
    "$(duration "$experiment_start"), $(duration "$start") in total"
}

experiment mdp
experiment imdp --agreement --absolute
experiment pomdp

echo "== $(date): building the figures"
docker/build_figures.sh -r "$out/results"
echo "== $(date): finished in $(duration "$start") in total"

if [ -n "$failed" ]; then
  echo "== results with problems in:$failed" >&2
  exit 1
fi
echo "== all results checked"
