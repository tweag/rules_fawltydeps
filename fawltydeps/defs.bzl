"""FawltyDeps Bazel aspect and rules for checking Python dependencies."""

FawltyDepsInfo = provider(
    doc = "Information about FawltyDeps analysis",
    fields = {
        "sources": "depset of source files",
        "imports": "depset of import names found in sources",
        "declared_deps": "depset of declared dependency names",
    },
)

def _fawltydeps_aspect_impl(target, ctx):
    """Aspect implementation to collect Python dependency information."""
    
    # Only process Python targets
    if not hasattr(target, "files"):
        return []
    
    sources = depset()
    imports = depset()
    declared_deps = depset()
    
    # Collect Python source files
    if PyInfo in target:
        py_info = target[PyInfo]
        sources = depset(
            direct = [f for f in target.files.to_list() if f.extension == "py"],
            transitive = [],
        )
        
        # Collect declared dependencies
        if hasattr(ctx.rule.attr, "deps"):
            dep_labels = [str(dep.label) for dep in ctx.rule.attr.deps]
            declared_deps = depset(direct = dep_labels)
    
    # Create analysis output file
    output = ctx.actions.declare_file(target.label.name + ".fawltydeps_report")
    
    # Write basic report
    ctx.actions.write(
        output = output,
        content = "FawltyDeps Analysis for: {}\nSources: {}\nDeclared deps: {}\n".format(
            target.label,
            len(sources.to_list()),
            len(declared_deps.to_list()),
        ),
    )
    
    return [
        FawltyDepsInfo(
            sources = sources,
            imports = imports,
            declared_deps = declared_deps,
        ),
        OutputGroupInfo(
            fawltydeps_report = depset([output]),
        ),
    ]

fawltydeps_aspect = aspect(
    implementation = _fawltydeps_aspect_impl,
    attr_aspects = ["deps"],
    provides = [FawltyDepsInfo],
)

def _fawltydeps_check_impl(ctx):
    """Rule implementation to check Python dependencies with FawltyDeps."""
    
    target = ctx.attr.target
    
    # Get the aspect information
    if FawltyDepsInfo not in target:
        fail("Target does not have FawltyDepsInfo")
    
    info = target[FawltyDepsInfo]
    
    # Create output file
    output = ctx.actions.declare_file(ctx.label.name + "_check.txt")
    
    # For now, just create a simple report
    ctx.actions.write(
        output = output,
        content = "FawltyDeps check completed for: {}\n".format(ctx.attr.target.label),
    )
    
    return [DefaultInfo(files = depset([output]))]

fawltydeps_check = rule(
    implementation = _fawltydeps_check_impl,
    attrs = {
        "target": attr.label(
            aspects = [fawltydeps_aspect],
            doc = "The Python target to check",
        ),
    },
    doc = "Check Python dependencies using FawltyDeps",
)
