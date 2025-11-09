from __future__ import annotations

from datetime import datetime, timezone
from typing import Dict

from fastapi import FastAPI

from demo_backend import SERVER_VERSION_ARG
from demo_backend.routers.v1 import customers as v1_customers
from demo_backend.routers.v2 import customers as v2_customers
from demo_backend.routers.v3 import customers as v3_customers

app = FastAPI(title="Demo Backend for Diff Testing", version="0.1.0")

@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok", "time": datetime.now(tz=timezone.utc).isoformat()}


@app.get("/")
def root_index() -> Dict[str, str]:
    return {
        "message": "Demo backend is running",
    }

match SERVER_VERSION_ARG:
    case 1:
        app.include_router(
            v1_customers.router,
        )
    case 2:
        app.include_router(
            v2_customers.router,
        )
    case 3:
        app.include_router(
            v3_customers.router,
        )

    case _:
        raise ValueError(f"Unknown server version: v{SERVER_VERSION_ARG}")
