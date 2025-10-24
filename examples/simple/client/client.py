import bs4  # Not declared, not known from requirements
import click
import sqlalchemy  # Not declared
#import requests  # Not needed
from libs.utils import greet

@click.command()
@click.option("--name", default="World", help="Name to greet")
def main(name):
    print(greet(name))
    try:
        response = requests.get("http://localhost:5000/")
        print("Server says:", response.text)
    except Exception as e:
        print("Error connecting to server:", e)

if __name__ == "__main__":
    main()
