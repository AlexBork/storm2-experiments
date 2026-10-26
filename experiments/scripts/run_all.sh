#!/bin/sh
# Run all experiments on all benchmarks of their index.json, with a time limit of
# 900 seconds and a memory limit of 32 GiB per run, post-process and check their
# logs, and build the figures in plots/latex/main.pdf, see common/run_set.sh.
# Every experiment writes its logs and results to experiments/logs and
# experiments/results of its directory. The options are passed on to common/run.py,
# which by default runs as many invocations at once as fit into the machine, e.g.
#   scripts/run_all.sh --jobs 4
set -eu
SET= TIMELIMIT=${TIMELIMIT:-900} MEMLIMIT=${MEMLIMIT:-32} exec "$(dirname "$0")/common/run_set.sh" "$@"
