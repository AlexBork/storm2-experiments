#!/bin/sh
# Copy the post-processed results of every experiment (see README.md) to latex/data/,
# those of imdps to latex/data/imdp/, and build the figures of all of them in
# latex/main.pdf, as in the paper.
set -eu
cd "$(dirname "$0")"

copy() {  # copy EXPERIMENT DIRECTORY
  if [ -f "$1/experiments/results/scatter.csv" ]; then
    mkdir -p "$2"
    cp "$1"/experiments/results/*.csv "$2/"
  else
    echo "no results in $1/experiments/results, leaving out its figures"
  fi
}
copy comparison_tools_bisim latex/data
copy imdps latex/data/imdp

cd latex && latexmk -pdf -interaction=nonstopmode -quiet main.tex
echo "wrote latex/main.pdf"
