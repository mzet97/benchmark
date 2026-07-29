import os
import json

from flask import Flask, jsonify, request
from flask_graphql import GraphQLView

from schema import schema
from db import ensure_schema

app = Flask(__name__)

# POST /graphql only, disable GraphiQL
app.add_url_rule(
    "/graphql",
    view_func=GraphQLView.as_view(
        "graphql",
        schema=schema,
        graphiql=False,
    ),
)


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    ensure_schema()
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
