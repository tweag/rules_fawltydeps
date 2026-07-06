"""A tiny library that only uses the Python standard library.

Kept dependency-free on purpose: the BCR presubmit test module needs to
resolve rules_fawltydeps from the registry and run the fawltydeps aspect
across every supported platform without a pinned pip lockfile.
"""

import json


def greeting(name):
    """Return a JSON greeting for ``name``."""
    return json.dumps({"hello": name})
