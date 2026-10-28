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
#   POMDP_CONFIGS  the configurations of pomdp, comma separated (default: all)
# A new run replaces the logs and results of the set. The options are passed on to
# run.py. Fails if a run has an incorrect result or none at all.
set -eu
: "${TIMELIMIT:?}" "${MEMLIMIT:?}"
SET=${SET:-}
INDEX=${INDEX:-$SET}
CORES=${CORES:-4}
DDMEM=${DDMEM:-8}
POMDP_CONFIGS=${POMDP_CONFIGS:-}
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

experiment() {  # experiment DIRECTORY CONFIGS [POSTPROCESS OPTIONS]
  directory=$1
  configs=$2
  shift 2
  number=$((number + 1))
  experiment_start=$(date +%s)
  echo "== $(date): running experiment $number/$experiments: $directory"
  cd "$directory"
  rm -rf "$out/logs" "$out/results" "$out/steps.log"
  mkdir -p "$out"
  # The output of generating the invocations and of the post-processing only goes
  # to steps.log, next to the logs and results
  python3 ../docker/common/generate_invocations.py --out "$invocations" \
    --index "$index" --logdir "$out/logs" --timelimit "$TIMELIMIT" \
    ${configs:+--configs "$configs"} >> "$out/steps.log" 2>&1 \
    || { cat "$out/steps.log" >&2; exit 1; }
  # shellcheck disable=SC2086
  python3 ../docker/common/run.py "$invocations" --memlimit "$MEMLIMIT" \
    --cores-per-run "$CORES" --ddmem "$DDMEM" $run_options
  python3 ../docker/common/postprocess.py "$@" "$out/logs" "$out/results" >> "$out/steps.log" 2>&1 \
    || { cat "$out/steps.log" >&2; exit 1; }
  # Lists the runs with problems, if any
  if python3 ../docker/common/check_results.py "$out/results" > "$out/check.log" 2>&1; then
    summary="$summary
  $directory: $(head -1 "$out/check.log")"
  else
    failed="$failed $directory"
    summary="$summary
  $directory: $(head -1 "$out/check.log"), PROBLEMS (listed in the output of $directory)"
  fi
  cat "$out/check.log"
  cd ..
  echo "== $(date): finished experiment $number/$experiments: $directory in" \
    "$(duration "$experiment_start"), $(duration "$start") in total"
}

summary=""
experiment mdp ""
experiment imdp "" --agreement --absolute
experiment pomdp "$POMDP_CONFIGS"

echo "== $(date): building the figures"
# The output of LaTeX only goes to docker/plots/latex/build.log
docker/build_figures.sh -r "$out/results" > docker/plots/latex/build.log 2>&1 \
  || { cat docker/plots/latex/build.log >&2; echo "== building the figures failed" >&2; exit 1; }
echo "== $(date): finished in $(duration "$start") in total"
echo "== summary:$summary"

if [ -n "$failed" ]; then
  echo "== results with problems in:$failed" >&2
  exit 1
fi
echo "== all results checked"
