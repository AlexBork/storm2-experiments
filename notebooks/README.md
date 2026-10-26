# Notebooks for FM tutorial

This folder contains material for the Storm tutorial at [FM 2026](https://conf.researchr.org/home/fm-2026).
We provide the Jupyter notebooks as well as model files.

## Versions
The notebooks in this folder use [stormpy](https://github.com/stormchecker/stormpy) 2.0 and [stormvogel](https://github.com/stormchecker/stormvogel) 0.13.
The decision tree synthesis with [PAYNT](https://github.com/randriu/synthesis) in `3-policies.ipynb` is currently disabled, as PAYNT does not yet support stormpy 2.0.

The version matching the tutorial paper (using stormpy 1.12) is available under the git tag [fm2026](https://github.com/stormchecker/stormpyter/tree/fm2026/tutorial_orchard) or as an [artifact on Zenodo](https://doi.org/10.5281/zenodo.18955665).

## Download
The easiest way is to download and run the prepared Docker image.

```
docker run -it -p 8888:8888 mvolk/storm-tutorial
```

Alternatively, one can also manually build and run from the provided Dockerfile.

```
docker build -t storm-tutorial .
docker run -it -p 8888:8888 storm-tutorial
```

## Running
After running the Dockerfile, in both cases visit the *localhost* link indicated in the commandline output with your web-browser.
This opens the Jupyter lab environment.
The notebooks from the tutorial are available in the `notebooks` directory and follow the same structure as the sections in the corresponding tutorial paper.
The example files, such as the Prism model files, are given in `notebooks/examples`.

## Trying online
One can also run most of the example in our online playground at [try.stormchecker.org](https://try.stormchecker.org/).
Select the examples from *Examples -> tutorial -> Orchard ...*
