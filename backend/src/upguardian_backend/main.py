import fastapi
import sqlite3
from pathlib import Path
import os
from typing import Dict, Any

from dotenv import load_dotenv
import asyncio
from typing import List, Optional, Any

import jwt
from jwt import PyJWKClient
from jwt.exceptions import InvalidTokenError
from fastapi import Security, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

load_dotenv()

# Auth0 / JWT settings (configure via environment variables)
AUTH0_DOMAIN = os.getenv("AUTH0_DOMAIN", "")
API_AUDIENCE = os.getenv("API_AUDIENCE", "")
ALGORITHMS = ["RS256"]

# Security scheme for FastAPI endpoints. Use like:
#   @app.get('/private')
#   def private(payload=Security(verify_jwt)):
#       return {"sub": payload["sub"]}
bearer_scheme = HTTPBearer()
app = fastapi.FastAPI()

# Database file placed at the repository root (two parents up from this file)
DB_PATH = Path(__file__).resolve().parents[2] / "upguardian.db"

# (Auth0/JWT code temporarily ignored per user request.)


class Service:
    """A lightweight Service model that holds a DB connection and an id that
    is unique within a given profile (not globally unique).

    Methods use asyncio.to_thread to offload sqlite3 operations to a thread
    pool since sqlite3 is not async-safe.
    """

    def __init__(self, db_conn: sqlite3.Connection, id: int, name: str, profile: Optional[str]):
        self._conn = db_conn
        # integer primary key
        self.id = id
        # human-friendly name (previously used as id)
        self.name = name
        # profile may be None for legacy/unknown profile entries
        self.profile = profile

    async def get_endpoint(self) -> Optional[str]:
        def _get():
            cur = self._conn.execute(
                "SELECT endpoint FROM services WHERE id = ?",
                (self.id,),
            )
            row = cur.fetchone()
            return row[0] if row else None

        return await asyncio.to_thread(_get)

    async def set_endpoint(self, endpoint: str) -> None:
        def _set():
            # Update by integer id
            cur = self._conn.execute(
                "UPDATE services SET endpoint = ? WHERE id = ?",
                (endpoint, self.id),
            )
            if cur.rowcount == 0:
                # If the row does not exist, insert a new row with the known
                # name and profile. This will create a new integer id; the
                # Service instance's id will not be updated in this case.
                self._conn.execute(
                    "INSERT INTO services(profile, name, endpoint) VALUES(?, ?, ?)",
                    (self.profile, self.name, endpoint),
                )
            self._conn.commit()

        await asyncio.to_thread(_set)


class UpGuardianSQLiteDB:
    """Encapsulates sqlite3 access and provides async helpers.

    The DB stores a `services` table with columns: profile, id (TEXT), endpoint (TEXT)
    and PRIMARY KEY(profile, id) because ids are unique only within a profile.
    """

    def __init__(self, conn: sqlite3.Connection):
        self._conn = conn

    def ensure_tables(self) -> None:
        # Create required tables if they don't exist. Use a composite primary
        # key (profile, id) since service ids are only unique within a profile.
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS services (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                profile TEXT,
                name TEXT,
                endpoint TEXT,
                UNIQUE(profile, name)
            )
            """
        )
        # Keep the kv table as previously defined for other storage.
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS kv (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                value TEXT
            )
            """
        )
        self._conn.commit()

    async def getServices(self, profile: Optional[str] = None) -> List[Service]:
        """Return a list of Service objects. If profile is provided, return
        only services belonging to that profile; otherwise return all.
        """

        def _fetch():
            if profile is None:
                cur = self._conn.execute("SELECT profile, id FROM services")
                rows = cur.fetchall()
                return [(row[0], row[1]) for row in rows]
            else:
                cur = self._conn.execute(
                    "SELECT id, name, profile FROM services WHERE profile = ?", (profile,)
                )
                return cur.fetchall()

        rows = await asyncio.to_thread(_fetch)
        return [Service(self._conn, id, name, prof) for id, name, prof in rows]

    async def createService(self, profile: Optional[str], name: str, endpoint: str) -> Service:
        """Create or update a service row (by profile+name) and return a Service.

        Returns a Service instance with the integer primary key `id`.
        """

        def _upsert():
            # Try update first
            cur = self._conn.execute(
                "UPDATE services SET endpoint = ? WHERE profile IS ? AND name = ?",
                (endpoint, profile, name),
            )
            rowid = None
            if cur.rowcount == 0:
                ins = self._conn.execute(
                    "INSERT INTO services(profile, name, endpoint) VALUES(?, ?, ?)",
                    (profile, name, endpoint),
                )
                rowid = ins.lastrowid
            else:
                row = self._conn.execute(
                    "SELECT id FROM services WHERE profile IS ? AND name = ?",
                    (profile, name),
                ).fetchone()
                rowid = int(row[0]) if row else None
            self._conn.commit()
            return rowid

        rowid = await asyncio.to_thread(_upsert)
        if rowid is None:
            raise RuntimeError("Failed to create or locate service row")
        return Service(self._conn, rowid, name, profile)


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

def _get_jwks_client_cached() -> PyJWKClient:
    client = getattr(app.state, "jwks_client", None)
    if client:
        return client
    if not AUTH0_DOMAIN:
        raise RuntimeError("AUTH0_DOMAIN not configured; cannot fetch JWKS")
    jwks_url = f"https://{AUTH0_DOMAIN}/.well-known/jwks.json"
    client = PyJWKClient(jwks_url)
    app.state.jwks_client = client
    return client

def verify_jwt(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
) -> Dict[str, Any]:
    """Verify an incoming JWT using Auth0's JWKS and return the token payload.

    Use as a dependency via FastAPI's Security(...) to protect endpoints.
    """
    token = credentials.credentials
    # Use PyJWKClient to obtain the signing key for this token. This avoids
    # assuming RSA or converting to PEM; PyJWT handles the JWK types.
    try:
        client = _get_jwks_client_cached()
        signing_key = client.get_signing_key_from_jwt(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Unable to obtain signing key: {str(e)}",
        )

    issuer = f"https://{AUTH0_DOMAIN}/" if AUTH0_DOMAIN else None

    try:
        # Pass the signing key object via the signing_key parameter to jwt.decode
        payload = jwt.decode(
            token,
            signing_key=signing_key.key,
            algorithms=ALGORITHMS,
            audience=API_AUDIENCE or None,
            issuer=issuer,
        )
        return payload
    except InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation error: {str(e)}",
        )

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