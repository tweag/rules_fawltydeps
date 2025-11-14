"""Configuration definitions for container image rules."""

ModuleVersionInfo = provider(
    doc = "Metadata on the version of a module",
    fields = {
        "version": "The version (as defined in module function of MODULE.bazel)",
    },
)

def _version_impl(ctx):
    return [ModuleVersionInfo(version = ctx.attr.version)]

version = rule(
    implementation = _version_impl,
    attrs = {"version": attr.string()},
)

def _version_repo_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        content = """load("@rules_fawltydeps//fawltydeps/private/config:defs.bzl", "version")

version(
    name = "rules_fawltydeps_version",
    version = "{}",
    visibility = ["//visibility:public"],
)
""".format(rctx.attr.version),
    )

version_repo = repository_rule(
    implementation = _version_repo_impl,
    attrs = {"version": attr.string()},
)

def _module_version_impl(ctx):
    if len(ctx.modules) != 1:
        fail("this extension should only be used by @rules_fawltydeps")
    module = ctx.modules[0]
    version_repo(
        name = "rules_fawltydeps_version",
        version = module.version,
    )
    return ctx.extension_metadata(
        root_module_direct_deps = [],
        root_module_direct_dev_deps = ["rules_fawltydeps_version"],
        reproducible = True,
    )

module_version = module_extension(
    implementation = _module_version_impl,
)
