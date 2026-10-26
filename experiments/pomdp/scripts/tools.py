from collections import OrderedDict

import storm

TOOLS = [storm]
TOOL_NAMES = OrderedDict([[t.NAME, t] for t in TOOLS])

def config_from_id(tool, identifier):
    if isinstance(tool, str):
        assert tool in TOOL_NAMES, f"Unknown tool '{tool}'"
        return TOOL_NAMES[tool].config_from_id(identifier)
    else:
        return tool.config_from_id(identifier)
