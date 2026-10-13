import os, copy, itertools, json, re
from collections import OrderedDict

NAME = "storm"
DESCRIPTION = ["storm-pomdp"]

# Configuration data, from scripts/configurations.json as for the other experiments.
# Every configuration there has a family (discretisation, cutoff or MDP), and the
# cut-offs their size threshold.
CONFIGS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "configurations.json")

base_cfg = OrderedDict()
base_cfg["tool"] = NAME
base_cfg["notes"] = ["Storm-pomdp"]
base_cfg["supported-obj-types"] = ["prb", "rew"]
base_cfg["supported-model-types"] = ["pomdp"]
base_cfg["supported-model-formalisms"] = ["prism"]

CONFIGS = []
with open(CONFIGS_FILE) as configs_file:
    for identifier, entry in json.load(configs_file).items():
        cfg = copy.deepcopy(base_cfg)
        cfg["id"] = identifier
        cfg["family"] = entry["family"]
        if "size-threshold" in entry:
            cfg["size-threshold"] = entry["size-threshold"]
        cfg["notes"] += [entry["description"].rstrip(".")]
        CONFIGS.append(cfg)

CONFIGS = sorted(CONFIGS, key=lambda x: (x["id"][:3], x.get("size-threshold", 0), x["id"]))
META_CONFIG_TIMELIMITS = [1800]
BASE_CONFIGS = ["discr", "cut"]
META_CONFIGS = []
for timelimit in META_CONFIG_TIMELIMITS:
    for cfgbase in BASE_CONFIGS:
        metacfg = OrderedDict()
        metacfg["id"] = f"{cfgbase}-best-in-{timelimit}s"
        metacfg["cfgbase"] = cfgbase
        metacfg["maxtime"] = timelimit
        META_CONFIGS.append(metacfg)

def config_from_id(identifier):
    for c in CONFIGS + META_CONFIGS:
        if c["id"] == identifier: return c
    assert False, f"Configuration identifier {identifier} is not known for {NAME}."
    
# LOGFILE Parsing
def contains_any_of(log, msg): 
    for m in msg:
        if m in log: return True
    return False

def try_parse(log, start, before, after, out_dict, out_key, out_type):
    pos1 = log.find(before, start)
    if pos1 >= 0:
        pos1 += len(before)
        pos2 = log.find(after, pos1)
        if pos2 >= 0:
            out_dict[out_key] = out_type(log[pos1:pos2])
            return pos2 + len(after)
    return start

def try_parse_duration(log, start, before, out_dict, out_key):
    pos1 = log.find(before, start)
    if pos1 < 0:
        return start
    pos1 += len(before)
    match = re.match(r"([0-9]+(?:\.[0-9]+)?)(ms|s)\.", log[pos1:])
    if match is None:
        return start
    value = float(match.group(1))
    if match.group(2) == "ms":
        value /= 1000.0
    out_dict[out_key] = value
    return pos1 + match.end()

def try_parse_constructed_belief_mdp(log, start, out_dict):
    prefix = "Constructed belief MDP: "
    pos1 = log.find(prefix, start)
    if pos1 < 0:
        return start
    pos1 += len(prefix)
    match = re.match(r"([0-9]+) states, ([0-9]+) choices, ([0-9]+) transitions\.", log[pos1:])
    if match is None:
        return start
    out_dict["states"] = int(match.group(1))
    out_dict["choices"] = int(match.group(2))
    out_dict["transitions"] = int(match.group(3))
    return pos1 + match.end()

def parse_logfile(log, inv):
    unsupported_messages = [] # add messages that indicate that the invocation is not supported
    inv["not-supported"] = contains_any_of(log, unsupported_messages)
    memout_messages = [] # add messages that indicate that the invocation is not supported
    memout_messages.append("An unexpected exception occurred and caused Storm to terminate. The message of this exception is: std::bad_alloc")
    memout_messages.append("Return code:\t-9")
    inv["memout"] = contains_any_of(log, memout_messages)
    known_error_messages = [] # add messages that indicate a "known" error, i.e., something that indicates that no warning should be printed
    inv["expected-error"] = contains_any_of(log, known_error_messages)
    if inv["not-supported"] or inv["expected-error"]: return
    if len(inv["return-codes"]) != 1 or inv["return-codes"][0] != 0:
        if not inv["timeout"] and not inv["memout"]: print("WARN: Unexpected return code(s): {} in {}".format(inv["return-codes"], inv["id"]))

    pos = try_parse_duration(log, 0, "Time for model construction: ", inv, "model-building-time")
    if pos == 0: 
        assert inv["timeout"] or inv["memout"] or inv.get("execution-error", False), "WARN: unable to get model construction time for {}".format(inv["id"])
        return
    inv["input-model"] = OrderedDict()
    pos = try_parse(log, pos, "States: \t", "\n", inv["input-model"], "states", int)
    pos = try_parse(log, pos, "Transitions: \t", "\n", inv["input-model"], "transitions", int)
    pos = try_parse(log, pos, "Choices: \t", "\n", inv["input-model"], "choices", int)
    pos = try_parse(log, pos, "Observations: \t", "\n", inv["input-model"], "observations", int)

    pos = log.find("Analyzing property ", pos)
    if pos < 0:
        assert inv["memout"] or inv["timeout"] or inv.get("execution-error", False), "Unable to find query output in {}".format(inv["id"])
        return

    if "Analyzing property 'Pmax=? [F true]'" in log: # todo this is to catch the trivial case
        inv["result"] = "≥1.0"
        inv["total-chk-time"] = "0.0"

    if "Exploration stopped before all beliefs were explored" in log or "Belief exploration stopped early:" in log:
        inv["belief-mdp-incomplete"] = True

    pos_bel = log.find("Constructing the belief MDP...", pos)
    if pos_bel < 0:
        pos_bel = log.find("Constructed belief MDP: ", pos)
    if pos_bel>=0:
        pos=pos_bel
        inv["belief-mdp"] = OrderedDict()
        pos = try_parse(log, pos, "States: \t", "\n", inv["belief-mdp"], "states", int)
        pos = try_parse(log, pos, "Transitions: \t", "\n", inv["belief-mdp"], "transitions", int)
        pos = try_parse(log, pos, "Choices: \t", "\n", inv["belief-mdp"], "choices", int)
        pos = try_parse_constructed_belief_mdp(log, pos, inv["belief-mdp"])
        pos = try_parse_duration(log, pos, "Time for exploring beliefs: ", inv["belief-mdp"], "expl-time")
        pos = try_parse_duration(log, pos, "Time for building the belief MDP: ", inv["belief-mdp"], "build-time")
        pos = try_parse_duration(log, pos, "Time for analyzing the belief MDP: ", inv["belief-mdp"], "chk-time")

    pos_result = try_parse(log, pos, "\nResult: ", "\n", inv, "result", str)
    if pos_result == pos:
        pos_result = try_parse(log, pos, "\nResult till abort: ", "\n", inv, "result", str)
    pos = pos_result
    pos = try_parse_duration(log, pos, "Time for POMDP analysis: ", inv, "total-chk-time")

    if "total-chk-time" not in inv and "belief-mdp" in inv:
        belief_times = ["expl-time", "build-time", "chk-time"]
        if all(t in inv["belief-mdp"] for t in belief_times):
            inv["total-chk-time"] = sum(inv["belief-mdp"][t] for t in belief_times)

    assert inv["memout"] or inv["timeout"] or inv.get("execution-error", False) or ("result" in inv and "total-chk-time" in inv), "Unable to find result or total-chk-time in {}".format(inv["id"]);

if __name__ == "__main__":
    print(f"{len(CONFIGS)} config(s) for {NAME}")
    print(json.dumps(CONFIGS,indent='\t'))
