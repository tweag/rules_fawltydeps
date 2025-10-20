# Contributing to rules_fawltydeps

Thank you for your interest in contributing to rules_fawltydeps!

## Development Setup

1. Install Bazel (version 6.4.0 or compatible):
   ```bash
   # The .bazelversion file will guide bazelisk to download the correct version
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/tweag/rules_fawltydeps.git
   cd rules_fawltydeps
   ```

## Project Structure

```
rules_fawltydeps/
├── fawltydeps/          # Core aspect and rule definitions
│   ├── defs.bzl         # Main aspect and rules
│   └── BUILD.bazel      # Build file
├── examples/            # Example projects
│   └── simple/          # Simple example demonstrating usage
├── MODULE.bazel         # Bazel module definition
├── requirements_lock.txt # Python dependencies (FawltyDeps)
└── README.md            # Main documentation
```

## Testing Changes

### Running the Example

```bash
cd examples/simple
bazel build //...
bazel test //...
```

### Testing the Aspect

```bash
cd examples/simple
bazel build :hello --aspects=@rules_fawltydeps//fawltydeps:defs.bzl%fawltydeps_aspect \
  --output_groups=fawltydeps_report
```

## Code Style

- Follow existing code style in .bzl files
- Add documentation for new rules and aspects
- Update README.md when adding new features

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes thoroughly
5. Submit a pull request

## Questions?

Feel free to open an issue for any questions or concerns.
