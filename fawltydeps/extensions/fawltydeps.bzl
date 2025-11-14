""" Implementation of rules_fawltydeps 'fawltydeps' extension """

DOC = """\
Defines a module extension to instantiate @fawltydeps external repository with the right config.

This technique has been deemed easier to use than configuration flags because the configuration exists in the MODULE file instead of .bazelrc. There are no fully qulified flags to maintain.
This may change in the future
"""

def _fawltydeps_repo_impl(ctx):
    # Create files from templates
    for target, src in [
        ("defs.bzl", ctx.attr._defs_template),
        ("BUILD.bazel", ctx.attr._build_template),
        ("convert_manifest.py", ctx.attr._converter_template),
        ("fawltydeps_wrapper.py", ctx.attr._wrapper_template),
    ]:
        ctx.template(
            target,
            src,
            substitutions = {
                "{pip_repo}": "@@" + ctx.attr.pip_repo.repo_name,
                "{pip_repo_name}": ctx.attr.pip_repo.name,  # A hack, because @pip turns into rules_python++pip+pip//:pip so the target name is the user-facing repo name
                "{+}": "+" if int((native.bazel_version or "9.x").split(".")[0]) >= 8 else "~",
            },
        )

# The repository rule that will be instantiated by the extension
_fawltydeps_repo = repository_rule(
    implementation = _fawltydeps_repo_impl,
    attrs = {
        "pip_repo": attr.label(mandatory = True),
        "_defs_template": attr.label(allow_single_file = True, default = ":defs.tpl.bzl"),
        "_build_template": attr.label(allow_single_file = True, default = ":BUILD.tpl.bazel"),
        "_converter_template": attr.label(allow_single_file = True, default = ":convert_manifest.tpl.py"),
        "_wrapper_template": attr.label(allow_single_file = True, default = ":fawltydeps_wrapper.tpl.py"),
    },
)

def _fawltydeps_impl(module_ctx):
    for mod in module_ctx.modules:
        for repo in mod.tags.configure:
            _fawltydeps_repo(
                name = repo.name,
                pip_repo = repo.pip_repo,
            )

_configure = tag_class(
    doc = """Tag class used to configure which pip repo to use with fawltydeps""",
    attrs = {
        "pip_repo": attr.label(
            mandatory = True,
            doc = """\
The label of the pip repository that you want fawltydeps to use to generate
mappings between import names and module names. Will also be used to suggest
names for missing modules.

If you are using the same names as rules_python documentation this would be "@pypi"
""",
        ),
        "name": attr.string(
            mandatory = False,
            default = "fawltydeps",
            doc = """The repository name to create. Default to "fawltydeps". """,
        ),
    },
)

fawltydeps = module_extension(
    doc = """Bzlmod extension that is used to configure fawltydeps.""",
    implementation = _fawltydeps_impl,
    tag_classes = {
        "configure": _configure,
    },
    environ = ["RULES_PYTHON_BZLMOD_DEBUG"],
)
