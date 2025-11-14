"""Release build utilities for rules_fawltydeps.

This module provides utilities for building release artifacts, including
platform-specific binaries, source bundles, and BCR (Bazel Central Registry)
packages.
"""

load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes")
load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")
load("//fawltydeps/private/config:defs.bzl", "ModuleVersionInfo")

DEFAULT_ATTRIBUTES = pkg_attributes(mode = "0644")

OfflineBuildDistdirInfo = provider(
    doc = """Provider representing the contents of a Bazel "--distdir".""",
    fields = {
        "basename_file_map": """Map of basename to File""",
        "files": "Depset of File whose basename shall be used as-is",
    },
)

BCRModuleVersionInfo = provider(
    doc = """Provider representing a version of a BCR module.""",
    fields = {
        "module_name": "Name of the module",
        "version": "The module version",
        "source_archive": "An archive File containing the module source",
        "source_archive_basename": "A basename for the source archive",
        "metadata_template": "A File containing a base template for metadata.json",
    },
)

def _release_files(ctx):
    output_group_info = {}
    version = ctx.attr.version[ModuleVersionInfo].version
    module_version = ctx.actions.declare_file("%s_module_version" % ctx.attr.name)
    git_tag = ctx.actions.declare_file("%s_git_tag" % ctx.attr.name)
    ctx.actions.write(module_version, content = version)
    ctx.actions.write(git_tag, content = "v" + version)
    output_group_info["version"] = depset([module_version, git_tag])
    lockfile_args = ctx.actions.args()
    lockfile_args.add("--version", version)
    dest_src_map = {}
    attributes = {}
    distdir_contents = {}
    lockfile = ctx.actions.declare_file("%s_lockfile.json" % ctx.attr.name)
    lockfile_args.add(lockfile)
    ctx.actions.run(
        outputs = [lockfile],
        inputs = [],
        executable = ctx.executable.lockfile_generator,
        arguments = [lockfile_args],
    )
    output_group_info["lockfile"] = depset([lockfile])

    return [
        DefaultInfo(files = depset(dest_src_map.values())),
        OutputGroupInfo(**output_group_info),
        PackageFilesInfo(attributes = attributes, dest_src_map = dest_src_map),
        OfflineBuildDistdirInfo(
            basename_file_map = distdir_contents,
            files = depset(),
        ),
    ]

release_files = rule(
    implementation = _release_files,
    attrs = {
        "basename": attr.string(),
        "lockfile_generator": attr.label(
            executable = True,
            default = Label("//fawltydeps/private/release/lockfile"),
            cfg = "exec",
        ),
        "lockfile_name": attr.string(
            mandatory = True,
        ),
        "version": attr.label(
            default = "@rules_fawltydeps_version",
            providers = [ModuleVersionInfo],
        ),
    },
)

def _offline_bundle_impl(ctx):
    contents = {}

    # Handle multiple distdir_contents inputs
    for distdir_content in ctx.attr.distdir_contents:
        if distdir_content:  # Check if not None
            mapped_contents = distdir_content[OfflineBuildDistdirInfo].basename_file_map
            extra_files = distdir_content[OfflineBuildDistdirInfo].files
            for f in extra_files.to_list():
                contents[f.basename] = f
            for basename, f in mapped_contents.items():
                contents[basename] = f

    distdir_args = ctx.actions.args()
    for basename, f in contents.items():
        distdir_args.add("--file", "%s=%s" % (basename, f.path))

    distdir_tree_artifact = ctx.actions.declare_directory(ctx.attr.name + ".distdir")
    distdir_args.add(distdir_tree_artifact.path)
    ctx.actions.run(
        outputs = [distdir_tree_artifact],
        inputs = contents.values(),
        executable = ctx.executable.distdir_generator,
        arguments = [distdir_args],
    )

    return [DefaultInfo(files = depset([distdir_tree_artifact]))]

offline_bundle = rule(
    implementation = _offline_bundle_impl,
    attrs = {
        "distdir_contents": attr.label_list(
            providers = [OfflineBuildDistdirInfo],
            mandatory = True,
        ),
        "distdir_generator": attr.label(
            executable = True,
            default = Label("//fawltydeps/private/release/distdir"),
            cfg = "exec",
        ),
    },
)

def _source_bundle_impl(ctx):
    attributes = {}
    dest_src_map = {}
    for file in ctx.files.srcs:
        if not file.is_source:
            fail("Bundling non-source file %s" % file.path)
        dest_src_map[file.path] = file
        attributes[file.path] = DEFAULT_ATTRIBUTES
    return [
        DefaultInfo(files = depset(dest_src_map.values())),
        PackageFilesInfo(attributes = attributes, dest_src_map = dest_src_map),
    ]

source_bundle = rule(
    implementation = _source_bundle_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)

def _versioned_filename_info_impl(ctx):
    file = ctx.file.src
    basename = file.basename
    destdir = ctx.attr.destdir
    slash = "/" if len(destdir) > 0 else ""
    extension = ctx.attr.extension if len(ctx.attr.extension) > 0 else file.extension
    dot = "." if len(extension) > 0 else ""
    path = file.path
    stem = basename.removesuffix(dot + extension)
    dest = ctx.attr.path_template.format(
        basename = basename,
        destdir = destdir,
        slash = slash,
        extension = extension,
        dot = dot,
        stem = stem,
        path = path,
        version = ctx.attr.version[ModuleVersionInfo].version,
    )
    dest_basename = ctx.attr.path_template.format(
        basename = basename,
        destdir = "",
        slash = "",
        extension = extension,
        dot = dot,
        stem = stem,
        path = path,
        version = ctx.attr.version[ModuleVersionInfo].version,
    )
    dest_src_map = {dest: file}

    # Generate release notes if requested (for source archives)
    output_group_info = {}
    if ctx.attr.generate_release_notes:
        release_notes = ctx.actions.declare_file("%s_release_notes.md" % ctx.attr.name)
        version = ctx.attr.version[ModuleVersionInfo].version
        version_with_v = "v" + version

        ctx.actions.run(
            outputs = [release_notes],
            inputs = [ctx.file.src],
            executable = ctx.executable._release_notes_generator,
            arguments = [ctx.file.src.path, version_with_v, release_notes.path],
            mnemonic = "GenerateReleaseNotes",
        )
        output_group_info["release_notes"] = depset([release_notes])

    return [
        DefaultInfo(files = depset(dest_src_map.values())),
        OutputGroupInfo(**output_group_info),
        PackageFilesInfo(attributes = {dest: ctx.attr.attributes}, dest_src_map = dest_src_map),
        BCRModuleVersionInfo(
            module_name = ctx.attr.module_name,
            version = ctx.attr.version[ModuleVersionInfo].version,
            source_archive = ctx.file.src,
            source_archive_basename = dest_basename,
            metadata_template = ctx.file._metadata_template,
        ),
    ]

versioned_filename_info = rule(
    implementation = _versioned_filename_info_impl,
    attrs = {
        "module_name": attr.string(),
        "src": attr.label(allow_single_file = True),
        "destdir": attr.string(),
        "extension": attr.string(),
        "path_template": attr.string(default = "{destdir}{slash}{stem}-v{version}{dot}{extension}"),
        "attributes": attr.string(),
        "generate_release_notes": attr.bool(default = False),
        "version": attr.label(
            default = "@rules_fawltydeps_version",
            providers = [ModuleVersionInfo],
        ),
        "_metadata_template": attr.label(
            allow_single_file = True,
            default = "//:.bcr/metadata.tpl.json",
        ),
        "_release_notes_generator": attr.label(
            executable = True,
            default = Label("//fawltydeps/private/release/release_notes"),
            cfg = "exec",
        ),
    },
)

def _offline_bcr_impl(ctx):
    bcr_args = ctx.actions.args()
    inputs = []
    output_group_info = {}
    for src_tar in ctx.attr.src_tars:
        bcr_info = src_tar[BCRModuleVersionInfo]
        request = {
            "module_name": bcr_info.module_name,
            "version": bcr_info.version,
            "source_path": bcr_info.source_archive.path,
            "override_source_basename": bcr_info.source_archive_basename,
            "metadata_template_path": bcr_info.metadata_template.path,
        }
        request_file = ctx.actions.declare_file(ctx.attr.name + "_local_module_" + bcr_info.module_name + ".json")
        inputs.append(request_file)
        inputs.append(bcr_info.source_archive)
        inputs.append(bcr_info.metadata_template)
        ctx.actions.write(request_file, content = json.encode(request))
        bcr_args.add("--add-local-module", request_file.path)
        bazel_dep = ctx.actions.declare_file(ctx.attr.name + "_local_module_" + bcr_info.module_name + ".bazel_dep")
        ctx.actions.write(bazel_dep, content = """bazel_dep(
    name = "{name}",
    version = "{version}",
)
""".format(name = bcr_info.module_name, version = bcr_info.version))
        output_group_info[bcr_info.module_name] = depset([bazel_dep])
    bcr_tree_artifact = ctx.actions.declare_directory(ctx.attr.name + ".local")
    bcr_args.add(bcr_tree_artifact.path)
    ctx.actions.run(
        outputs = [bcr_tree_artifact],
        inputs = inputs,
        executable = ctx.executable.bcr_generator,
        arguments = [bcr_args],
    )
    bcr = depset([bcr_tree_artifact])
    output_group_info["bcr"] = bcr
    return [
        DefaultInfo(files = bcr),
        OutputGroupInfo(**output_group_info),
    ]

offline_bcr = rule(
    implementation = _offline_bcr_impl,
    attrs = {
        "src_tars": attr.label_list(
            providers = [BCRModuleVersionInfo],
            mandatory = True,
        ),
        "bcr_generator": attr.label(
            executable = True,
            default = Label("//fawltydeps/private/release/bcr"),
            cfg = "exec",
        ),
    },
)
