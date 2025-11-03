# Correct external imports:
#import click
#import requests

# Broken external imports for demo:
import bs4  # Not declared in BUILD file, not found in @py_deps
import click # correct
import sqlalchemy  # Not declared in BUILD file, found @py_deps
#import requests  # Declared in BUILD file, but never imported

# Test importing with full path from workspace root
from libs.utils import greet

# Test importing from binary location (as opposed to workspace root)
from sidequest import CONST

@click.command()
@click.option("--name", default="World", help="Name to greet")
def main(name):
    print(greet(name))
    print(f"CONST is {CONST}")
    try:
        response = requests.get("http://localhost:5000/")
        print("Server says:", response.text)
    except Exception as e:
        print("Error connecting to server:", e)

if __name__ == "__main__":
    main()
