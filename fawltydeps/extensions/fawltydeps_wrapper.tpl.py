import json
import sys
from pathlib import Path
from typing import Any

from fawltydeps.main import main

_ESCAPES = {
    "/": "_s",
    ":": "_c",
    "@": "_a",
    "\\": "_b",
    "-": "_d",
    "_": "_u",  # must be last
}


def demangle(s: str) -> str:
    s = s.removeprefix("package")
    for k, v in _ESCAPES.items():
        s = s.replace(v, k)
    return s.lower().replace("-", "_")  # last ressort fixes


def analyze_results(analysis: Any):
    undeclared = analysis["undeclared_deps"]
    unused = analysis["unused_deps"]
    failed = False
    if not unused and not undeclared:
        return True

    # Undeclared imports
    for u in undeclared:
        failed = True
        print(f"\nCould not find a package providing `{u['name']}`")
        for p in u["references"]:
            print(f"  - imported at {p['path']}:{p['lineno']}")
        # Other candidates are just the package name and as such are mostly useless
        candidates = [c for c in u["candidates"] if c.startswith("package")]
        if len(candidates) == 0:
            print("  Could not find any installed pip package providing that import.")
        elif len(candidates) == 1:
            print("  You can fix this by running the following command:")
        else:
            print("  You can fix this by running one of the following commands:")
        for c in candidates:
            print(f"    buildozer 'add {actual_attr} {demangle(c)}' {actual_label}")

    for u in unused:
        # Poor man approximation of import names from package.
        # Will work for "hydra" in "hydra_core" for example
        if folder in demangle(u["name"]):
            # There is a bug in isort that makes it accept the current folder as a valid import.
            # Silently ignore when such a combination happens
            continue

        failed = True
        print(f"\nPackage `{demangle(u['name'])}` is not used")
        print("  You can remove it using the following command:")
        for p in u["references"]:
            print(f"    buildozer 'remove {actual_attr} {demangle(u['name'])}' {actual_label}")
        #print(
        #    "  If you happen to know that that package is needed, look for a file"
        #    "\n  or directory with the same name in your python files. It probably"
        #    "\n  tricks fawltydeps into thinking that it provide the import above."
        #    "\n  Please rename that file to convey your intent to the tool."
        #)

    if failed:
        print(
            f"\nThere were errors while checking the dependencies of {label}."
            f"\nTo run this test locally you can run 'bazel build --config=fawltydeps {label}'"
            #'\nLast ressort, there is always the possibility to disable this check on a specific target using `tags = ["no-fawltydeps"]`.'
            "\n"  # Just to unclutter
        )

    return not failed


if __name__ == "__main__":
    output_file_path = sys.argv[1]
    label = sys.argv[2]
    package = sys.argv[3]
    args = sys.argv[4:]
    folder = package.split("/")[-1]

    # Ensure the package folder exists, as bazel may not create it if there are no sources within it.
    Path(package).mkdir(parents=True, exist_ok=True)

    # The label that should be patched. Sometimes different due to macros.
    actual_label = label
    actual_attr = "deps"
    # Fixup for swift test
    if label.endswith("_swift_test_pylib"):
        actual_label = label.removesuffix("_swift_test_pylib")
        actual_attr = "test_deps"

    with open(output_file_path, "w+") as output_file:
        ret = main(args, None, output_file)
        output_file.seek(0)
        analysis = json.load(output_file)

    ok = analyze_results(analysis)
    if (ret == 0) == ok:
        sys.exit(ret)
    else:
        sys.exit(0 if ok else 1)
