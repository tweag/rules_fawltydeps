from flask import Flask, render_template
from libs.db import init_db

app = Flask(__name__, template_folder="../libs/templates")
db = init_db()

@app.route("/")
def index():
    return render_template("index.html", message="Hello from Flask Server!")

if __name__ == "__main__":
    app.run(debug=True)
