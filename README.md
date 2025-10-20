# rules_fawltydeps

Bazel rules for [FawltyDeps](https://github.com/tweag/fawltydeps) to automatically check Python dependencies in your Bazel projects.

## Overview

`rules_fawltydeps` provides Bazel rules and aspects to integrate FawltyDeps into your build process. FawltyDeps finds undeclared and unused dependencies in Python projects, helping you maintain clean and accurate dependency declarations in your BUILD files.

## Features

- **Automatic dependency checking**: Validate that your Python code only uses declared dependencies
- **Aspect-based analysis**: Non-invasive checks that work with existing `py_library`, `py_binary`, and `py_test` rules
- **Build integration**: Runs as part of your normal Bazel build process

## Installation

Add the following to your `MODULE.bazel` file:

```python
bazel_dep(name = "rules_fawltydeps", version = "0.1.0")
```

## Usage

### Basic Usage with Aspects

To check dependencies for a specific target:

```bash
bazel build //your/package:target --aspects=@rules_fawltydeps//fawltydeps:defs.bzl%fawltydeps_aspect
```

### In BUILD Files

You can also create explicit check targets:

```python
load("@rules_fawltydeps//fawltydeps:defs.bzl", "fawltydeps_check")

py_library(
    name = "mylib",
    srcs = ["mylib.py"],
    deps = [
        "@pypi//requests",
    ],
)

fawltydeps_check(
    name = "mylib_deps_check",
    target = ":mylib",
)
```

Then run:

```bash
bazel test :mylib_deps_check
```

## Example

See the [examples](examples/) directory for a complete working example.

## How It Works

The `fawltydeps_aspect` traverses your build graph and:

1. Collects all Python source files
2. Analyzes imports in those files
3. Compares imports against declared dependencies
4. Reports any missing or unused dependencies

## Requirements

- Bazel 6.0 or later
- Python 3.8 or later

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the same terms as [FawltyDeps](https://github.com/tweag/fawltydeps).
