#!/bin/sh
# Build the figures of the paper in docker/plots/latex/main.pdf. Without an argument,
# from the post-processed results of the experiments (see README.md), in
# experiments/results of every experiment directory or in RESULTS with -r RESULTS:
# those of comparison_tools_bisim go to docker/plots/latex/data/, those of imdps to
# docker/plots/latex/data/imdp/ and the plot data of pomdp to
# docker/plots/latex/data/pomdp/. With a directory in that layout, from its data
# instead, e.g. for the figures of the paper:
#   docker/build_figures.sh ../results/paper/data
set -eu
results=experiments/results
if [ "${1:-}" = "-r" ]; then
  results=$2
  shift 2
fi
data=${1:+$(realpath "$1")}
cd "$(dirname "$0")/.."
latex=docker/plots/latex
rm -rf $latex/data

if [ -n "$data" ]; then
  cp -r "$data" $latex/data
else
  copy() {  # copy EXPERIMENT DIRECTORY
    if [ -f "$1/$results/scatter.csv" ]; then
      mkdir -p "$2"
      cp "$1/$results"/*.csv "$2/"
    else
      echo "no results in $1/$results, leaving out its figures"
    fi
  }
  copy comparison_tools_bisim $latex/data
  copy imdps $latex/data/imdp

  # The data of the POMDP figure, wherever below the results of pomdp it was written
  series=$(find "pomdp/$results" -name plot-series.csv 2>/dev/null | head -1)
  if [ -n "$series" ] && [ -f "$(dirname "$series")/plot-curves.csv" ]; then
    mkdir -p $latex/data/pomdp
    cp "$series" "$(dirname "$series")/plot-curves.csv" $latex/data/pomdp/
  else
    echo "no plot-series.csv and plot-curves.csv in pomdp/$results, leaving out its figure"
  fi
fi

# -g: latexmk does not see which data files the figures read
cd $latex && latexmk -g -pdf -interaction=nonstopmode -quiet main.tex
echo "wrote $latex/main.pdf"
