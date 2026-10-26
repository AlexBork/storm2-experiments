import json, os
from collections import OrderedDict

# The benchmark instances are listed in benchmarks/index.json, as for the other
# experiments; its paths are relative to the benchmarks directory.
MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "benchmarks")
INDEX_FILE = os.path.join(MODELS_DIR, "index.json")

PROPERTY_TYPES = OrderedDict()
PROPERTY_TYPES["prb"] = "Reachability probability"
PROPERTY_TYPES["rew"] = "Expected reward"

def create_property_info(identifier : str,  file_name : str):
    """
    Creates a dictionary with the information of a property.
    @param identifier: The identifier of the property. The first three letters yield the type of the property.
                        The next three letters encode the optimization direction (min or max)
                        If the seventh character is numeric, it encodes the number of different reward assignments involved in reward bounds
    @param file_name: The name of the file containing the property
    """
    assert len(identifier) >= 3, f"Invalid identifier for property: {identifier}"
    info = OrderedDict()
    info["id"] = identifier
    info["file"] = file_name
    info["type"] = identifier[:3]
    info["dir"] = identifier[3:6]
    assert info["dir"] in ["min", "max"], f"Unknown optimization direction for property {info['dir']}"
    if len(identifier) >= 7 and identifier[6].isnumeric():
        assert info["type"] in ["rbr"], f"Unknown extra information for property type {info['type']}"
        info["num-bnd-rew-assignments"] = int(identifier[6])
    else:
        assert info["type"] not in ["rbr"], f"Missing extra information for property of type {info['type']}"
    return info

def parse_constants(constants):
    """The values of a constant definition like 'N=4,sl=0.1'."""
    values = OrderedDict()
    for definition in constants.split(","):
        name, value = definition.split("=")
        values[name] = int(value) if value.lstrip("-").isdigit() else float(value)
    return values

def create_instance(inst_id, entry):
    inst = OrderedDict()
    inst["id"] = inst_id
    inst["benchmark-set"] = entry["benchmark-set"]
    inst["name"] = entry["name"]
    inst["model"] = OrderedDict()
    if "constants" in entry:
        inst["model"]["file-parameters"] = OrderedDict()
        inst["model"]["open-parameters"] = parse_constants(entry["constants"])
    inst["model"]["file"] = entry["prism"]
    inst["model"]["formalism"] = "prism"
    inst["model"]["type"] = "pomdp"
    inst["property"] = create_property_info(entry["property"], entry["prism-property"])
    return inst

with open(INDEX_FILE) as index_file:
    INSTANCES = [create_instance(inst_id, entry) for inst_id, entry in json.load(index_file).items()]
NAMES = list(dict.fromkeys([i["name"] for i in INSTANCES]).keys())
BENCHMARK_SETS = OrderedDict()
for bset in dict.fromkeys([i["benchmark-set"] for i in INSTANCES]):
    BENCHMARK_SETS[bset] = [f"{bset} benchmark set", "{} instances".format(len([i for i in INSTANCES if i["benchmark-set"] == bset]))]

def get_full_model_filename(inst):
    return os.path.join(MODELS_DIR, inst["model"]["file"])

def get_full_property_filename(inst):
    return os.path.join(MODELS_DIR, inst["property"]["file"])

def from_id(identifier):
    for b in INSTANCES:
        if b["id"] == identifier: return b
    assert False, f"Instance with id {identifier} not found."

def check_instances():
    for inst in INSTANCES:
        modelfilename = get_full_model_filename(inst)
        assert os.path.isfile(modelfilename), f"Model file {modelfilename} does not exist."
        propfilename = get_full_property_filename(inst)
        assert os.path.isfile(propfilename), f"Property file {propfilename} does not exist."
        propname = inst["property"]["id"]
        with open(propfilename, 'r') as propfile:
            content = propfile.read()
        assert f'"{propname}":' in content, (f"Property file '{propfilename}' contents\n-----\n{content}\n-----\n...do not refer to property name {propname}. "
                                         f"Make sure to assign the property name like this:\n\t"
                                         f'"{propname}": Pmax=? ...')

if __name__ == "__main__":
    check_instances()
    print(f"Registered {len(NAMES)} benchmark models with {len(INSTANCES)} instances.")
    for name in NAMES:
        name_instances = [b for b in INSTANCES if b['name'] == name]
        print(f"Model '{name}' ({len(name_instances)} instances):\n\t" + "\n\t".join([b['id'] for b in name_instances]))
    print(f"Registered {len(BENCHMARK_SETS)} benchmark sets: {', '.join(BENCHMARK_SETS)}")
