# Results in the paper

The logs and results of the runs that Figures 6 to 9 of the paper show:

| Path | Contents |
| --- | --- |
| `data/` | The data of the figures, in the layout of `plots/latex/data/`: that of `comparison_tools_bisim` directly in it, of `imdps` in `imdp/`, and `plot-series.csv` and `plot-curves.csv` of `pomdp` in `pomdp/` |
| `comparison_tools_bisim/` | `logs/` and `results/` of the tool comparison, 957 runs of 10 configurations |
| `imdps/` | `logs/` and `results/` of the interval MDPs, 156 runs |
| `pomdp/` | `logs/` and `results/` of the POMDPs, 665 runs |

Build the figures of the paper from `data/` with

```bash
scripts/build_figures.sh paper_results/data
```

which writes them to `plots/latex/main.pdf`.

The csv files of `comparison_tools_bisim` and `imdps` in `data/` are those that
`scripts/common/postprocess.py` writes for the logs here, e.g. from
`experiments/comparison_tools_bisim`:

```bash
python3 ../../scripts/common/postprocess.py ../../paper_results/comparison_tools_bisim/logs /tmp/bisim
```

and from `experiments/imdps` with `--agreement --absolute`. The runtimes in
`data/pomdp/plot-curves.csv` are those of `pomdp/results/runtime-runs.csv`.
