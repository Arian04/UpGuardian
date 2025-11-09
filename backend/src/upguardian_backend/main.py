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


@app.get("/profiles/{profile}/services")
async def list_services(profile: str):
    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    services = await db_manager.getServices(profile)

    async def _get(svc: Service):
        endpoint = await svc.get_endpoint()
        name = await svc.get_name()
        return {"id": svc.id, "name": name, "endpoint": endpoint}

    results = await asyncio.gather(*[_get(s) for s in services])
    return list(results)


@app.post("/profiles/{profile}/services")
async def create_service_for_profile(profile: str, body: dict):
    """Create a new service for the given profile.

    Expected JSON body: {"name": <str>, "endpoint": <str>}
    """
    name = body.get("name")
    endpoint = body.get("endpoint")
    if not name or not endpoint:
        return fastapi.responses.JSONResponse({"error": "name and endpoint are required"}, status_code=400)

    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    svc = await db_manager.createService(profile, name, endpoint)
    current_name = await svc.get_name()
    current_endpoint = await svc.get_endpoint()
    return {"id": svc.id, "name": current_name, "endpoint": current_endpoint, "profile": svc.profile}


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

    # read back endpoint and name to confirm
    current_endpoint = await service.get_endpoint()
    current_name = await service.get_name()
    return {"id": service.id, "name": current_name, "endpoint": current_endpoint, "profile": service.profile}


@app.post("/services/{service_id}/requests")
async def create_request(service_id: int, body: dict):
    """Create a new Request record.

    Expected JSON body: {"service": <int>, "endpoint": <str>, "method": <str>, "body": <optional str>}
    """
    endpoint = body.get("endpoint")
    method = body.get("method")
    rb = body.get("body")
    if endpoint is None or method is None:
        return fastapi.responses.JSONResponse({"error": "endpoint and method are required"}, status_code=400)

    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    req = await db_manager.create_request(int(service_id), endpoint, method, rb)
    data = await req.to_dict()
    return data


@app.get("/requests/{request_id}")
async def get_request(request_id: int):
    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    req = await db_manager.get_request(request_id)
    if not req:
        return fastapi.responses.JSONResponse({"error": "not found"}, status_code=404)
    return await req.to_dict()


@app.put("/requests/{request_id}")
async def update_request(request_id: int, body: dict):
    db_manager: UpGuardianSQLiteDB = app.state.db_manager

    # Retrieve Request object and use its setters to update fields.
    req = await db_manager.get_request(request_id)
    if not req:
        return fastapi.responses.JSONResponse({"error": "not found"}, status_code=404)

    # Use the Request instance setters (they offload to threads).
    if "service" in body and body.get("service") is not None:
        await req.set_service(int(body.get("service")))
    if "endpoint" in body and body.get("endpoint") is not None:
        await req.set_endpoint(body.get("endpoint"))
    if "method" in body and body.get("method") is not None:
        await req.set_method(body.get("method"))
    if "body" in body:
        # allow setting body to null/None
        await req.set_body(body.get("body"))

    return await req.to_dict()


@app.delete("/requests/{request_id}")
async def delete_request(request_id: int):
    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    ok = await db_manager.delete_request(request_id)
    if not ok:
        return fastapi.responses.JSONResponse({"error": "not found"}, status_code=404)
    return {"deleted": request_id}


@app.get("/services/{service}/requests")
async def list_service_requests(service: int):
    """List stored requests for the given integer service id by acquiring a
    Service object and using its list_requests() method.
    """
    db_manager: UpGuardianSQLiteDB = app.state.db_manager
    svc = await db_manager.get_service_by_id(service)
    if not svc:
        return fastapi.responses.JSONResponse({"error": "service not found"}, status_code=404)

    reqs = await svc.list_requests()
    results = await asyncio.gather(*[r.to_dict() for r in reqs])
    return list(results)