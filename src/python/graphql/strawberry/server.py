import os

import strawberry
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

from schema import schema
from db import ensure_schema

# Disable introspection in production
graphql_app = GraphQLRouter(
    schema,
    graphql_ide=None,  # disable GraphiQL/Playground
    allow_queries_via_get=False,  # POST only
)

app = FastAPI()
app.include_router(graphql_app, prefix="/graphql")


@app.on_event("startup")
def startup():
    ensure_schema()


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run("server:app", host="0.0.0.0", port=port, log_level="info")
