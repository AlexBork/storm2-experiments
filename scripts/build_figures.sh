#!/bin/sh
# Build the figures of the paper in plots/latex/main.pdf. Without an argument, from
# the post-processed results of the experiments (see README.md): those of
# comparison_tools_bisim go to plots/latex/data/, those of imdps to
# plots/latex/data/imdp/ and the plot data of pomdp to plots/latex/data/pomdp/.
# With a directory in that layout, from its data instead, e.g. for the figures of
# the paper:
#   scripts/build_figures.sh paper_results/data
set -eu
data=${1:+$(realpath "$1")}
cd "$(dirname "$0")/.."
rm -rf plots/latex/data

if [ -n "$data" ]; then
  cp -r "$data" plots/latex/data
else
  copy() {  # copy EXPERIMENT DIRECTORY
    if [ -f "experiments/$1/experiments/results/scatter.csv" ]; then
      mkdir -p "$2"
      cp "experiments/$1"/experiments/results/*.csv "$2/"
    else
      echo "no results in experiments/$1/experiments/results, leaving out its figures"
    fi
  }
  copy comparison_tools_bisim plots/latex/data
  copy imdps plots/latex/data/imdp

  # The data of the POMDP figure, wherever below the results of pomdp it was written
  series=$(find experiments/pomdp/experiments/results -name plot-series.csv 2>/dev/null | head -1)
  if [ -n "$series" ] && [ -f "$(dirname "$series")/plot-curves.csv" ]; then
    mkdir -p plots/latex/data/pomdp
    cp "$series" "$(dirname "$series")/plot-curves.csv" plots/latex/data/pomdp/
  else
    echo "no plot-series.csv and plot-curves.csv in experiments/pomdp/experiments/results, leaving out its figure"
  fi
fi

cd plots/latex && latexmk -pdf -interaction=nonstopmode -quiet main.tex
echo "wrote plots/latex/main.pdf"
