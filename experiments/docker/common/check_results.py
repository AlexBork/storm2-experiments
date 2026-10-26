#!/usr/bin/env python3
"""Check the post-processed results of an experiment for runs that went wrong.

run.py only reports whether a tool exited normally; this checks what the
post-processing made of it. Run from an experiment directory with the results
directory written by postprocess.py, e.g.
  python3 ../docker/common/check_results.py experiments/results
It reports and fails on
  - runs that are incorrect, or have no result although they did not run out of
    time or memory (e.g. because the output format of a tool changed),
  - for pomdp, runs without a result, results that are not a bound of the
    expected kind, and lower bounds above upper bounds of the same benchmark.
Runs that ran out of time or memory are counted, but not considered errors.
"""

import argparse
import importlib.util
import json
import math
import sys
from pathlib import Path

# The experiment directory, e.g. mdp; the scripts are run from there.
ROOT = Path.cwd()

# Relative and absolute slack when comparing the bounds of pomdp, which are rounded
# to ten digits in the output.
BOUND_TOLERANCE = 1e-6


def last_result_line(log):
    """The last line of a log that mentions a result, to show what the tool printed."""
    try:
        lines = Path(log).read_text(errors="replace").splitlines()
    except OSError:
        return "(log not readable)"
    found = [line for line in lines if "result" in line.lower()]
    return found[-1].strip() if found else "(no result line in the log)"


def check_common(results):
    """Problems in the results.json of common/postprocess.py, and the status counts."""
    problems, counts = [], {}
    for configuration, benchmarks in sorted(results.items()):
        for benchmark, repetitions in sorted(benchmarks.items()):
            for repetition, data in sorted(repetitions.items()):
                status = data["status"]
                counts[status] = counts.get(status, 0) + 1
                if status in ("incorrect", "no-result"):
                    problems.append(f"{status}: {configuration} {benchmark} rep{repetition}: "
                                    f"{last_result_line(data['log'])}")
    return problems, counts


def check_pomdp(executions):
    """Problems in the execution-data.json of pomdp/scripts/postprocess.py, and the
    status counts."""
    spec = importlib.util.spec_from_file_location("pomdp_postprocess",
                                                  ROOT / "scripts" / "postprocess.py")
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(ROOT / "scripts"))
    spec.loader.exec_module(module)

    problems, counts = [], {}
    bounds = {}      # benchmark -> (lower bounds, upper bounds) as (value, run id)
    for tool, configurations in executions.items():
        for configuration, runs in configurations.items():
            for benchmark, run in runs.items():
                # Meta configurations only repeat the runs of other configurations.
                if run.get("tool") != tool or run.get("configuration-id") != configuration:
                    continue
                if run.get("timeout") or run.get("memout"):
                    status = "memout" if run.get("memout") else "timeout"
                    counts[status] = counts.get(status, 0) + 1
                    continue
                if run.get("not-supported") or run.get("expected-error"):
                    counts["unsupported"] = counts.get("unsupported", 0) + 1
                    continue
                if run.get("execution-error") or "result" not in run:
                    counts["error"] = counts.get("error", 0) + 1
                    problems.append(f"no result: {run['id']}: {last_result_line(run['log'])}")
                    continue
                try:
                    relation, value = module.parse_result_value(run["result"])
                except ValueError as e:
                    counts["error"] = counts.get("error", 0) + 1
                    problems.append(f"unreadable result: {run['id']}: {e}")
                    continue
                counts["ok"] = counts.get("ok", 0) + 1
                base = configuration.rstrip("0123456789s")
                expected = module.expected_bound_relation(base, run["benchmark"])
                # An exact value, e.g. of a fully explored belief MDP, is both bounds.
                if expected is not None and relation not in (expected, "="):
                    problems.append(f"wrong kind of bound: {run['id']}: {relation} {value}, "
                                    f"expected {expected}")
                lower, upper = bounds.setdefault(benchmark, ([], []))
                if relation in ("≥", "="):
                    lower.append((value, run["id"]))
                if relation in ("≤", "="):
                    upper.append((value, run["id"]))
    for benchmark, (lower, upper) in sorted(bounds.items()):
        if not lower or not upper:
            continue
        low, low_id = max(lower)
        high, high_id = min(upper)
        if low > high and not math.isclose(low, high, rel_tol=BOUND_TOLERANCE,
                                            abs_tol=BOUND_TOLERANCE):
            problems.append(f"bounds contradict: {benchmark}: lower bound {low} ({low_id}) "
                            f"> upper bound {high} ({high_id})")
    return problems, counts


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("results", help="directory written by postprocess.py")
    args = parser.parse_args()

    results = Path(args.results)
    if (results / "results.json").is_file():
        with open(results / "results.json") as f:
            problems, counts = check_common(json.load(f))
    elif (results / "execution-data.json").is_file():
        with open(results / "execution-data.json", encoding="utf-8-sig") as f:
            problems, counts = check_pomdp(json.load(f))
    else:
        sys.exit(f"{results}: neither results.json nor execution-data.json found")

    print(f"checked {sum(counts.values())} runs: "
          + ", ".join(f"{n} {s}" for s, n in sorted(counts.items())))
    for problem in problems:
        print(f"  {problem}")
    if problems:
        sys.exit(f"{len(problems)} problem(s) in {results}")


if __name__ == "__main__":
    main()
