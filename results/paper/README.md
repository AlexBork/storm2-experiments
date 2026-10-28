# Results in the paper

The logs and results of the runs that Figures 6 to 9 of the paper show. These runs used a beta version of Storm 2.0, commit [`276d4fe0a5`](https://github.com/stormchecker/storm/commit/276d4fe0a56ee61952e4d5e04ce5f69c19f216eb) of the Storm repository, which the logs show as `Storm 1.14.0 (dev)`:

| Path | Contents |
| --- | --- |
| `data/` | The data of the figures, in the layout of `experiments/docker/plots/latex/data/`: that of `mdp` directly in it, of `imdp` in `imdp/`, and `plot-series.csv` and `plot-curves.csv` of `pomdp` in `pomdp/` |
| `mdp/` | `logs/` and `results/` of the tool comparison, 957 runs of 10 configurations |
| `imdp/` | `logs/` and `results/` of the interval MDPs, 156 runs |
| `pomdp/` | `logs/` and `results/` of the POMDPs, 665 runs, of which the figure shows the 646 of the 34 configurations other than `mdp` |

Create the figures of the paper from the logs here (see
[Step 4](../../README.md#step-4-create-the-figures-from-logs) of the README) with

```bash
$ARTIFACT_DIR/scripts/4_figures.sh $ARTIFACT_DIR/results/paper
```

which writes them to `paper-figures.pdf` in the current directory.

The csv files in `data/` are those that `experiments/docker/common/postprocess.py`
writes for the logs here, e.g. from `experiments/mdp`:

```bash
python3 ../docker/common/postprocess.py ../../results/paper/mdp/logs /tmp/bisim
```

from `experiments/imdp` with `--agreement --absolute`, and from `experiments/pomdp`,
which writes `plot-series.csv` and `plot-curves.csv` to `plots/` of its results and
ignores the logs of the removed configuration `mdp`. The `results/` directories are
those of the post-processing at the time of the paper; that of `pomdp` has other
files than the current one.
