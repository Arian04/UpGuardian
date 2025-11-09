import fastapi
import sqlite3
from pathlib import Path
import os

from dotenv import load_dotenv
import asyncio
from typing import Optional

from fastapi import FastAPI
from jwt import PyJWKClient

from .db import UpGuardianSQLiteDB
from .service import Service

load_dotenv()

# Auth0 / JWT settings (configure via environment variables)
AUTH0_DOMAIN = os.getenv("AUTH0_DOMAIN", "")
app: FastAPI = fastapi.FastAPI()

# Database file placed at the repository root (two parents up from this file)
DB_PATH = Path(__file__).resolve().parents[2] / "upguardian.db"

@app.on_event("startup")
def startup():
    """Open DB connection and (optionally) fetch JWKS from Auth0.

    The JWKS fetch is only attempted if AUTH0_DOMAIN is configured. The
    fetched JWKS is stored in `app.state.jwks` for use by the JWT verifier.
    """
    # Ensure parent directory exists (usually it will)
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    # allow usage from different threads (FastAPI workers). For simple apps
    # this is sufficient; for high concurrency consider a connection pool.
    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row

    # initialize a small table for storage
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS kv (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE NOT NULL,
            value TEXT
        )
        """
    )
    conn.commit()

    app.state.db = conn

    # Attach a DB manager that wraps sqlite access and ensure tables exist.
    db_manager = UpGuardianSQLiteDB(conn)
    db_manager.ensure_tables()
    app.state.db_manager = db_manager

    # If Auth0 domain is set, prepare a PyJWKClient to fetch JWKs on demand.
    if AUTH0_DOMAIN:
        try:
            jwks_url = f"https://{AUTH0_DOMAIN}/.well-known/jwks.json"
            app.state.jwks_client = PyJWKClient(jwks_url)
        except Exception:
            # Do not crash the app if JWKS client cannot be prepared at startup;
            # verification will attempt to prepare/fetch on demand and raise a
            # proper 401/500.
            app.state.jwks_client = None

@app.on_event("shutdown")
def shutdown():
    db = getattr(app.state, "db", None)
    if db:
        db.close()


def get_db() -> sqlite3.Connection:
    """Return the application's database connection.

    Use this in endpoints as a dependency if needed:

        def endpoint(db: sqlite3.Connection = Depends(get_db)):
            ...
    """
    return app.state.db


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/services")
async def list_services(profile: Optional[str] = None):
    """List services for the given profile (passed as query parameter `profile`).

    The profile value is placed into a local variable named `profile` so the
    lookup can be changed later (for example to derive from an auth token).
    """
    # canonical place for the profile value — could be computed differently later
    profile = profile

    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    services = await db_manager.getServices(profile)

    async def _get(svc: Service):
        endpoint = await svc.get_endpoint()
        return {"id": svc.id, "endpoint": endpoint}

    results = await asyncio.gather(*[_get(s) for s in services])
    return {"services": results}


@app.put("/services/{service_id}")
async def put_service(service_id: str, body: dict):
    """Create or update a service's endpoint.

    The request body is expected to include `endpoint` and may include
    `profile`. The `profile` value is copied into a local variable named
    `profile` so it can be replaced later with a different resolution.
    """
    profile = body.get("profile")
    endpoint = body.get("endpoint")
    if endpoint is None:
        return fastapi.responses.JSONResponse(
            {"error": "endpoint is required"}, status_code=400
        )

    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    service = await db_manager.createService(profile, service_id, endpoint)

    # read back endpoint to confirm
    current_endpoint = await service.get_endpoint()
    return {"id": service.id}