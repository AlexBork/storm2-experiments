import stormpy
from stormpy.numbers import Rational
from stormpy import UncertaintyResolutionMode as Mode
from stormpy.analysis import compute_expected_number_of_visits
from stormpy.transformations import add_uncertainty

stormpy.compute_expected_number_of_visits = compute_expected_number_of_visits
stormpy.add_uncertainty = add_uncertainty


program = stormpy.parse_prism_program("vacuum.prism")
mdp = stormpy.build_model[Rational](program)
formula = 'Tmin=? [F "docked"]'
prop = stormpy.parse_property(formula, program)
result = stormpy.model_checking(
    mdp, prop, extract_scheduler=True
)  # 39.308 [39.308, 39.308]
dtmc = mdp.apply_scheduler(result.get_scheduler())
visits = stormpy.compute_expected_number_of_visits(dtmc)
rug = [s.id for s in dtmc.states if "rug" in s.labels]
rug_visits = sum(visits[i] for i in rug)  # 12.084
imdp = stormpy.add_uncertainty(mdp, Rational("1/100"))
interval_result = stormpy.model_checking(
    imdp, prop, uncertainty_resolution_mode=Mode.ROBUST
)  # 50.768

print(
    "Minimal expected time to dock: "
    f"{result[mdp.initial_states[0]]}"
    " approx: "
    f"{result[mdp.initial_states[0]]:.6f}"
)
print(
    "Expected number of visits to the rug: "
    f"{rug_visits:.6f}"
)
print(
    "Interval result: "
    f"{interval_result[imdp.initial_states[0]]}"
    " approx: "
    f"{interval_result[imdp.initial_states[0]]:.6f}"
)
