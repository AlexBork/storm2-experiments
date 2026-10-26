# Results in the paper

The logs and results of the runs that Figures 6 to 9 of the paper show:

| Path | Contents |
| --- | --- |
| `data/` | The data of the figures, in the layout of `experiments/docker/plots/latex/data/`: that of `comparison_tools_bisim` directly in it, of `imdps` in `imdp/`, and `plot-series.csv` and `plot-curves.csv` of `pomdp` in `pomdp/` |
| `comparison_tools_bisim/` | `logs/` and `results/` of the tool comparison, 957 runs of 10 configurations |
| `imdps/` | `logs/` and `results/` of the interval MDPs, 156 runs |
| `pomdp/` | `logs/` and `results/` of the POMDPs, 665 runs, of which the figure shows the 646 of the 34 configurations other than `mdp` |

Build the figures of the paper from `data/` in the container of the experiments
(see the [README](../../README.md#loading-the-container)), from `$ARTIFACT_DIR`, with

```bash
docker run --rm -v "$PWD/results/paper:/paper:ro" -v "$PWD:/out" storm2-experiments \
    sh -c 'docker/build_figures.sh /paper/data && cp docker/plots/latex/main.pdf /out/paper.pdf'
```

which writes them to `paper.pdf` in `$ARTIFACT_DIR`.

The csv files in `data/` are those that `experiments/docker/common/postprocess.py`
writes for the logs here, e.g. from `experiments/comparison_tools_bisim`:

```bash
python3 ../docker/common/postprocess.py ../../results/paper/comparison_tools_bisim/logs /tmp/bisim
```

from `experiments/imdps` with `--agreement --absolute`, and from `experiments/pomdp`,
which writes `plot-series.csv` and `plot-curves.csv` to `plots/` of its results and
ignores the logs of the removed configuration `mdp`. The `results/` directories are
those of the post-processing at the time of the paper; that of `pomdp` has other
files than the current one.
