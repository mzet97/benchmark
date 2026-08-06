import os
import json

from flask import Flask, jsonify, request, Response

from schema import schema
from db import ensure_schema

app = Flask(__name__)


@app.route("/graphql", methods=["POST"])
def graphql():
    # Accept either a JSON body ({query, variables, operationName}) or an
    # application/graphql body (raw query text). POST only, no GraphiQL.
    content_type = (request.headers.get("Content-Type") or "").split(";")[0].strip()
    if content_type == "application/json":
        try:
            payload = request.get_json(force=True, silent=False)
        except Exception:
            payload = None
        if not isinstance(payload, dict):
            return _json_error("Request body must be a JSON object", 400)
        query = payload.get("query")
        variables = payload.get("variables")
        operation_name = payload.get("operationName")
    else:
        query = request.get_data(as_text=True)
        variables = None
        operation_name = None

    if not query:
        return _json_error("Must provide a query string.", 400)

    if isinstance(variables, str):
        try:
            variables = json.loads(variables) if variables else None
        except json.JSONDecodeError:
            return _json_error("Variables are invalid JSON.", 400)

    result = schema.execute(
        query,
        variables=variables,
        operation_name=operation_name,
    )

    response: dict = {}
    if result.errors:
        response["errors"] = [{"message": str(err)} for err in result.errors]
    response["data"] = result.data
    return Response(
        json.dumps(response),
        status=200,
        mimetype="application/json",
    )


def _json_error(message: str, status: int) -> Response:
    return Response(
        json.dumps({"errors": [{"message": message}]}),
        status=status,
        mimetype="application/json",
    )


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    ensure_schema()
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
