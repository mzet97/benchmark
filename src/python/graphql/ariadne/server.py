import os
import json

import uvicorn
from starlette.applications import Starlette
from starlette.routing import Route, Mount
from starlette.requests import Request
from starlette.responses import JSONResponse
from ariadne.asgi import GraphQLApp

from schema import schema
from db import ensure_schema


async def health(request: Request):
    return JSONResponse({"status": "ok"})


graphql_app = GraphQLApp(
    schema,
    introspection=False,
)

app = Starlette(
    routes=[
        Route("/health", health, methods=["GET"]),
        Mount("/graphql", app=graphql_app),
    ],
    on_startup=[lambda: ensure_schema()],
)

if __name__ == "__main__":
    ensure_schema()
    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run("server:app", host="0.0.0.0", port=port, log_level="info")
