import asyncio
import sqlite3
from typing import List, Optional

from .service import Service
from .request import Request


class UpGuardianSQLiteDB:
    """Encapsulates sqlite3 access and provides async helpers.

        The DB stores a `services` table with columns: id (INTEGER PK), profile, name,
        old_endpoint and new_endpoint. Services are unique per (profile, name).
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
                old_endpoint TEXT,
                new_endpoint TEXT,
                UNIQUE(profile, name)
            )
            """
        )
        # Requests table stores individual HTTP requests tied to a service
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                service INTEGER NOT NULL,
                endpoint TEXT NOT NULL,
                method TEXT NOT NULL,
                body TEXT,
                FOREIGN KEY(service) REFERENCES services(id) ON DELETE CASCADE
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
                cur = self._conn.execute("SELECT id, name, profile FROM services")
                return cur.fetchall()
            else:
                cur = self._conn.execute(
                    "SELECT id, name, profile FROM services WHERE profile = ?", (profile,)
                )
                return cur.fetchall()

        rows = await asyncio.to_thread(_fetch)
        return [Service(self._conn, id, name, prof) for id, name, prof in rows]

    async def createService(self, profile: Optional[str], name: str, old_endpoint: Optional[str] = None, new_endpoint: Optional[str] = None) -> Service:
        """Create or update a service row (by profile+name) and return a Service.

        Returns a Service instance with the integer primary key `id`.
        """

        def _upsert():
            # Try update first; set both endpoint columns (may be NULL)
            cur = self._conn.execute(
                "UPDATE services SET old_endpoint = ?, new_endpoint = ? WHERE profile IS ? AND name = ?",
                (old_endpoint, new_endpoint, profile, name),
            )
            rowid = None
            if cur.rowcount == 0:
                ins = self._conn.execute(
                    "INSERT INTO services(profile, name, old_endpoint, new_endpoint) VALUES(?, ?, ?, ?)",
                    (profile, name, old_endpoint, new_endpoint),
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

    # --- Request-related DB helpers ---------------------------------
    async def create_request(self, service_id: int, endpoint: str, method: str, body: Optional[str] = None) -> Request:
        """Insert a new request row and return a Request object."""

        def _insert():
            cur = self._conn.execute(
                "INSERT INTO requests(service, endpoint, method, body) VALUES(?, ?, ?, ?)",
                (service_id, endpoint, method, body),
            )
            self._conn.commit()
            return cur.lastrowid

        rowid = await asyncio.to_thread(_insert)
        return Request(self._conn, int(rowid))

    async def get_service_by_id(self, service_id: int) -> Optional[Service]:
        def _get():
            cur = self._conn.execute("SELECT id, name, profile FROM services WHERE id = ?", (service_id,))
            return cur.fetchone()

        row = await asyncio.to_thread(_get)
        if not row:
            return None
        return Service(self._conn, int(row[0]), row[1], row[2])

    async def get_request(self, request_id: int) -> Optional[Request]:
        def _get():
            cur = self._conn.execute(
                "SELECT id FROM requests WHERE id = ?", (request_id,)
            )
            return cur.fetchone()

        row = await asyncio.to_thread(_get)
        if not row:
            return None
        return Request(self._conn, int(row[0]))

    async def delete_request(self, request_id: int) -> bool:
        def _delete():
            cur = self._conn.execute("DELETE FROM requests WHERE id = ?", (request_id,))
            self._conn.commit()
            return cur.rowcount > 0

        return await asyncio.to_thread(_delete)
