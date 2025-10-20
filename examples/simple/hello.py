"""Example Python module with some imports."""

import json
import sys


def greet(name):
    """Greet someone by name."""
    data = {"greeting": f"Hello, {name}!"}
    return json.dumps(data)


def main():
    """Main function."""
    if len(sys.argv) > 1:
        name = sys.argv[1]
    else:
        name = "World"
    
    print(greet(name))


if __name__ == "__main__":
    main()
