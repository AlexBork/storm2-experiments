# Storm and Stormpy

This artifact contains the source code of [Storm](https://www.stormchecker.org/) 2.0 in `storm/` and of [Stormpy](https://stormchecker.github.io/stormpy/) 2.0 in `stormpy/`. This file describes both tools briefly and shows how to play with them on the robot vacuum example of the paper (Sec. 7, Fig. 4 and 5) in `examples/vacuum/` and on the MDP and POMDP benchmarks of the experiments in `examples/mdp_benchmarks/` and `examples/pomdp_benchmarks/`.

## Storm

Storm is a versatile, modular, and efficient open-source probabilistic model checker. It has a C++ core, which builds a model from a high-level description such as a Prism program or a JANI model, preprocesses it, and solves the equations that characterise a query, a set of command-line interfaces, and a Python API, Stormpy. Storm supports DTMCs, MDPs, POMDPs, CTMCs and Markov automata, as well as interval and parametric models. Queries include reachability probabilities, expected rewards, LTL, multi-objective queries, conditional probabilities and expected visiting times, and Storm can extract policies (schedulers) for them. Results come with the bounds that the chosen algorithm proves: Storm offers fast floating-point methods, sound methods with guaranteed precision, and exact methods with rational numbers.

The Storm website [www.stormchecker.org](https://www.stormchecker.org/) provides documentation, a [getting started guide](https://www.stormchecker.org/getting-started.html) and [tutorials](https://www.stormchecker.org/tutorials.html). Storm can also be tried without any installation in the online playground at [try.stormchecker.org](https://try.stormchecker.org/). More example models are in the [Quantitative Verification Benchmark Set](http://qcomp.org/benchmarks).

### Playing with Storm

Use the Docker image `storm2-tools` of the artifact, which `scripts/1_load.sh` loads together with the image of the experiments (see the [README](README.md#step-1-load-the-docker-images)), so no network access is needed. It is built from `notebooks/Dockerfile` on the official image of Stormpy 2.0, `movesrwth/stormpy:2.0.0`, and contains the command-line tools of Storm 2.0, Stormpy 2.0 and the Jupyter environment of the notebooks. Run Storm in it on the files in `examples/`, which the following command makes available as `/examples` in the container, from `$ARTIFACT_DIR`:

```bash
cd $ARTIFACT_DIR
docker run --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools \
    storm --prism vacuum.prism --prop 'Tmin=? [F "docked"]' --exact
```

This computes the minimal expected time for the robot vacuum to reach its charging dock exactly, using rational numbers:

```
Result (for initial states): 60134629039/1529841069 (approx. 39.30776226). Exact solution.
```

Replace the options after `storm` to try other queries and settings, for example:

| Options | Result |
| --- | --- |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]'` | 39.30873742 with the default floating-point value iteration, which only proves the bounds [0, 246.26] |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]' --sound` | 39.30777562 with sound value iteration, which proves the bounds [39.30773631, 39.30781493] |
| `--prism vacuum.prism --prop 'Pmax=? [F<=10 "docked"]' --sound` | 0.7519414556, the maximal probability to dock within 10 steps, which Storm computes exactly |
| `--prism vacuum.prism --prop 'R{"steps"}min=? [F "docked"]' --sound` | 38.30777562, the minimal expected number of moves to dock (the first step only starts the robot), with the bounds [38.30773731, 38.30781393] |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]' --sound --buildstateval --buildchoicelab --exportscheduler sched.json` | also writes the optimal policy to `examples/vacuum/sched.json`: for every state, given by its variables, the action to choose, e.g. `east` |

The comments at the top of `vacuum.prism` describe its variants: a POMDP in which the robot only observes bumps, a parametric MDP with an undefined slip probability, and an interval MDP. The MDP benchmarks of the experiments can be checked in the same way, e.g. the coin-flip property `c2` of the consensus protocol with 4 processes, before and after bisimulation minimisation:

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/mdp_benchmarks/consensus storm2-tools \
    storm --prism consensus.4.prism --prop consensus.props c2 --constants K=4 --bisimulation --sound
```

which reduces the model from 43136 to 2189 states and gives `0.4062752785` with the bounds `[0.4062748722, 0.4062756848]`; the exact value is 852021/2097152 ≈ 0.4062752724. `storm --help` lists all options, and `storm --help all` also the advanced ones.

POMDPs are analysed by `storm-pomdp`, whose belief exploration computes sound bounds on the optimal value. For the refuel benchmark of the POMDP experiments, unfolding the beliefs up to a size limit of 100000 gives a lower bound, and discretising the beliefs with resolution 4 an upper bound on the maximal probability to reach the goal:

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/pomdp_benchmarks/refuel storm2-tools \
    storm-pomdp --prism refuel.prism --prop refuel.props prbmax -const N=6 --belief-exploration unfold --size-threshold 100000 --sound
docker run --rm -v "$PWD/examples:/examples" -w /examples/pomdp_benchmarks/refuel storm2-tools \
    storm-pomdp --prism refuel.prism --prop refuel.props prbmax -const N=6 --belief-exploration discretize --resolution 4 --triangulationmode static --sound
```

which print `Result: ≥ 0.67219` and `Result: ≤ 0.7129687089`; with `--sound`, as in the experiments, the bounds hold despite rounding errors. Figure 9 of the paper shows how these bounds develop with the size limit.

## Stormpy

Stormpy provides the Python bindings for Storm, created using [pybind11](https://pybind11.readthedocs.io/). It brings Storm into the Python ecosystem for numerical computations, machine learning, and visualisation, so that algorithms on top of Storm, such as loops around model checking calls, can be prototyped quickly while the computations run in the C++ core. Stormpy 2.0 has two layers: a Pythonic public API for common tasks, e.g. `build_model` picks the right builder for a model, and a developer layer with one-to-one bindings to the functions and classes of Storm. Specialisations such as the number representation are selected by indexing, e.g. `build_model[Rational](program)` builds a model with rational numbers. The [documentation of Stormpy](https://stormchecker.github.io/stormpy/) has a getting started guide and the API reference.

### Playing with Stormpy

`examples/vacuum/vacuum.py` is the code of Fig. 4 of the paper. It builds the robot vacuum MDP with rational numbers, computes the minimal expected time to dock together with an optimal policy, applies the policy to obtain the induced DTMC, computes how often the robot visits the rug, and finally turns every probability into an interval of width 1/100 and computes the minimal expected time under robust semantics.

Run it in the same image `storm2-tools`:

```bash
cd $ARTIFACT_DIR
docker run --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools python3 vacuum.py
```

This prints, apart from warnings that Storm switches to robust value iteration for the interval MDP:

```
Minimal expected time to dock: 60134629039/1529841069 [...] approx: 39.307762 [39.307762, 39.307762]
Expected number of visits to the rug: 12.084022 [-, -]
Interval result: ... approx: 50.768185 [...]
```

To explore further, start an interactive Python shell with `docker run -it --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools python3` and enter the lines of `vacuum.py` one by one, e.g. to look at `mdp`, `result.get_scheduler()` or `visits`.

### Notebooks

`notebooks/` contains the Jupyter notebooks of the Storm tutorial on the Orchard game, which introduce modelling, model checking, policies, uncertainty and further extensions with Stormpy 2.0 and [stormvogel](https://github.com/stormchecker/stormvogel). The image `storm2-tools` contains them in `/opt/notebooks` together with their Jupyter environment. Start it with

```bash
docker run -it --rm -p 8888:8888 storm2-tools
```

and open the `http://127.0.0.1:8888/lab?token=...` link that it prints in a web browser; see [notebooks/README.md](notebooks/README.md) for the notebooks. Changes to the notebooks are lost when the container stops; `File > Download` saves a notebook to the host.
