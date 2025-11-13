"""FawltyDeps Bazel aspect for checking Python dependencies."""

load("@rules_python//python:defs.bzl", "PyInfo")
load("@rules_python//python/private:reexports.bzl", "BuiltinPyInfo")

FawltyDepsInfo = provider(
    doc = "Information about FawltyDeps analysis",
    fields = {
        "files": "Files directly exposed by this rule",
    },
)

REPO_NAME_UNDERSCORES = len("{pip_repo_name}".split("_")) - 1
IGNORE_MISSING_IMPORTS = []  # XXX: make configurable
IGNORE_UNUSED_DEPS = []
EXTRA_MAPPINGS = {}
_EXTRA_MAPPING_LABELS = {Label(k): k for k in EXTRA_MAPPINGS.keys()}

_ESCAPES = {
    "_": "_u",  # must be first
    "/": "_s",
    ":": "_c",
    "@": "_a",
    "\\": "_b",
    "-": "_d",
}

def escape(s):
    for k, v in _ESCAPES.items():
        s = s.replace(k, v)
    return "package" + s

def _fawltydeps_aspect_impl(target, ctx):
    """Aspect implementation to collect Python dependency information."""

    if "pypi" in str(target.label):
        return [FawltyDepsInfo(files = [])]

    if not hasattr(ctx.rule.attr, "srcs"):
        return [FawltyDepsInfo(files = [])]

    srcs = ctx.rule.attr.srcs
    data = getattr(ctx.rule.attr, "data", [])
    deps = getattr(ctx.rule.attr, "deps", [])

    # Collect Python source files
    python_files = []
    for src in srcs:
        python_files += [
            f
            for f in src.files.to_list()
            if f.extension == "py" and not f.path.startswith("external/")
        ]
    for src in data:
        if PyInfo in src:
            fail("py_library should go in deps, not data")

        # XXX: Do we, in general, want to deal with python sources in data ?
        python_files += [
            f
            for f in src.files.to_list()
            if f.extension == "py" and not f.path.startswith("external/")
        ]

    if not python_files:
        return [FawltyDepsInfo(files = [])]
    elif "no-fawltydeps" in ctx.rule.attr.tags:
        return [FawltyDepsInfo(files = python_files)]

    direct_imports = []
    imported_files = []
    for dep in deps:
        if dep.label in _EXTRA_MAPPING_LABELS:
            direct_imports.append(escape(_EXTRA_MAPPING_LABELS[dep.label]))
        elif PyInfo in dep or (BuiltinPyInfo != None and BuiltinPyInfo in dep):
            if dep.label.repo_name.startswith("rules_python{+}{+}pip{+}{pip_repo_name}_"):
                # rules_python++pip+{pip_repo_name}_310_requests -> requests
                #   1  |                  ???      | 2 |  [3:]
                repo_name_parts = 3 + REPO_NAME_UNDERSCORES
                pip_package_name = dep.label.repo_name.split("_", repo_name_parts)[-1]
                direct_imports.append(escape("@{pip_repo_name}//" + pip_package_name))
            elif FawltyDepsInfo in dep:
                imported_files += dep[FawltyDepsInfo].files

    package = target.label.package
    global_mapping = ctx.file._fawltydeps_manifest

    requirements = ctx.actions.declare_file(target.label.name + "_requirements.txt")
    ctx.actions.write(requirements, "\n".join(direct_imports) + "\n")

    mapping_file = ctx.actions.declare_file(target.label.name + "_mapping_file.toml")
    mapping_file_content = "\n".join(['"{}" = {}'.format(escape(k), v) for k, v in EXTRA_MAPPINGS.items()])
    ctx.actions.write(mapping_file, mapping_file_content)

    report_file = ctx.actions.declare_file(target.label.name + ".fawltydeps_report.txt")

    # wrapper args
    args = ctx.actions.args()
    args.add(report_file.path)
    args.add(target.label)
    args.add(package)

    # fawltydeps args

    # Some libraries are just glorified filegroups factoring some common files and dependencies for a few binaries in the same package.
    # They would not work if called from another package because they behave like binaries without being so.
    # The solution I found was to annotate them with "py_binary" tags, so their special behavior can be handled correctly.
    envs = ["."]  # The workspace root
    if ctx.rule.kind in ["py_binary", "py_test"] or "py_binary" in ctx.rule.attr.tags:
        envs = [package, "."]  # The package first, then the workspace root.

    args.add("--json")
    args.add("--check")
    args.add_all("--pyenv", envs)
    args.add("--base-dir", ".")
    args.add_all("--ignore-undeclared", IGNORE_MISSING_IMPORTS)
    args.add_all("--ignore-unused", [escape(p) for p in IGNORE_UNUSED_DEPS])
    args.add_all("--code", python_files)
    args.add("--deps", requirements.path)
    args.add("--custom-mapping-file", mapping_file.path)
    args.add("--custom-mapping-file", global_mapping.path)

    ctx.actions.run(
        executable = ctx.executable._fawltydeps,
        arguments = [args],
        inputs = [requirements, mapping_file, global_mapping] + python_files + imported_files,
        outputs = [report_file],
        mnemonic = "FawltyDeps",
        progress_message = "FawltyDeps %{label}",
    )

    return [
        OutputGroupInfo(fawltydeps_report = [report_file]),
        FawltyDepsInfo(files = python_files),
    ]

_MaybeBuiltinPyInfo = [[BuiltinPyInfo]] if BuiltinPyInfo != None and BuiltinPyInfo != PyInfo else []

fawltydeps_aspect = aspect(
    implementation = _fawltydeps_aspect_impl,
    attr_aspects = ["deps"],
    required_providers = [[PyInfo]] + _MaybeBuiltinPyInfo,
    provides = [FawltyDepsInfo],
    attrs = {
        "_fawltydeps": attr.label(
            cfg = "exec",
            executable = True,
            allow_files = True,
            default = "//:fawltydeps_wrapper",
        ),
        "_fawltydeps_manifest": attr.label(
            allow_single_file = [".toml"],
            default = "//:manifest",
        ),
    },
)
