from __future__ import annotations

from datetime import datetime, timezone
from typing import Dict

from fastapi import FastAPI


app = FastAPI(title="Demo Backend for Diff Testing", version="0.1.0")

@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok", "time": datetime.now(tz=timezone.utc).isoformat()}


@app.get("/")
def root_index() -> Dict[str, str]:
    return {
        "message": "Demo backend is running",
    }


# app.include_router(v1)
# app.include_router(v2)
