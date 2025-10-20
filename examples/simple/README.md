# Simple FawltyDeps Example

This is a simple example demonstrating the use of `rules_fawltydeps` in a Bazel project.

## Structure

- `hello.py` - A simple Python binary that uses standard library imports
- `lib.py` - A library with commented-out external dependency (for testing)
- `BUILD.bazel` - Build file with `fawltydeps_check` rules

## Running the Example

### Build and run the binary

```bash
bazel run //examples/simple:hello
```

### Check dependencies

```bash
# Check the library dependencies
bazel build //examples/simple:lib_deps_check

# Check the binary dependencies  
bazel build //examples/simple:hello_deps_check
```

### Using the aspect directly

```bash
bazel build //examples/simple:hello --aspects=@rules_fawltydeps//fawltydeps:defs.bzl%fawltydeps_aspect --output_groups=fawltydeps_report
```

## Testing Dependency Detection

To test FawltyDeps dependency checking:

1. Uncomment the `import requests` line in `lib.py`
2. Run `bazel build //examples/simple:lib_deps_check`
3. FawltyDeps should report that `requests` is imported but not declared in deps
4. Add `@pypi//requests` to the deps in BUILD.bazel to fix the issue
