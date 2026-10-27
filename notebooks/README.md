# Notebooks for FM tutorial

This folder contains material for the Storm tutorial at [FM 2026](https://conf.researchr.org/home/fm-2026): the Jupyter notebooks, the model files they use, and the slides.
It is a copy of `tutorial_orchard/` of the [stormpyter repository](https://github.com/volkm/stormpyter/tree/stormpy2) (branch `stormpy2`, commit `c47a454`), with a `Dockerfile` that builds on the stormpy 2.0 image.

## Versions
The notebooks in this folder use [stormpy](https://github.com/stormchecker/stormpy) 2.0 and [stormvogel](https://github.com/stormchecker/stormvogel) 0.13.
The decision tree synthesis with [PAYNT](https://github.com/randriu/synthesis) in `3-policies.ipynb` is currently disabled, as PAYNT does not yet support stormpy 2.0.

The version matching the tutorial paper (using stormpy 1.12) is available under the git tag [fm2026](https://github.com/stormchecker/stormpyter/tree/fm2026/tutorial_orchard) or as an [artifact on Zenodo](https://doi.org/10.5281/zenodo.18955665).

## Contents
| Path | Contents |
| --- | --- |
| `1-modeling.ipynb` | Step one: modelling the Orchard game |
| `2-model-checking.ipynb` | Step two: model checking |
| `3-policies.ipynb` | Step three: working with policies |
| `4-uncertainty.ipynb` | Step four: MDPs with more uncertainty |
| `5-extensions.ipynb` | Next steps |
| `examples/` | The model files of the notebooks, e.g. the Prism programs and the stormvogel model of the Orchard game |
| `slides/` | The slides of the tutorial, as notebooks for [RISE](https://github.com/jupyterlab-contrib/rise) and as `slides.pdf` |
| `Dockerfile`, `requirements.txt` | The Jupyter environment, on top of the official stormpy 2.0 image `movesrwth/stormpy:2.0.0` |

## Running
The artifact ships the Jupyter environment as the prebuilt Docker image `storm2-tools`, which `scripts/1_load.sh` of the artifact loads; no network access is needed. Start it with

```
docker run -it --rm -p 8888:8888 storm2-tools
```

and visit the `http://127.0.0.1:8888/lab?token=...` link indicated in the command-line output with your web browser.
This opens the Jupyter Lab environment in a copy of this folder, `/opt/notebooks` in the container.
The notebooks follow the same structure as the sections in the corresponding tutorial paper.
Changes to the notebooks are lost when the container stops; `File > Download` saves a notebook to the host.

To work on the notebooks of this folder on the host instead, mount it into the container by runnin this in the notebooks folder:

```
docker run -it --rm -p 8888:8888 -v "$PWD:/opt/notebooks" storm2-tools
```

Files that the notebooks write are then owned by root on Linux.
The image can also be built from the `Dockerfile` in this folder, which needs network access:

```
docker build -t storm2-tools .
```

## Trying online
One can also run most of the examples in our online playground at [try.stormchecker.org](https://try.stormchecker.org/).
Select the examples from *Examples -> tutorial -> Orchard ...*
