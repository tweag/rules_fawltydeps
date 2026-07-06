"""Entry point exercising the greeting library."""

import sys

from greeting import greeting


def main():
    print(greeting(sys.argv[1] if len(sys.argv) > 1 else "world"))


if __name__ == "__main__":
    main()
