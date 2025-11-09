import asyncio
import sqlite3
from typing import List, Optional

from .service import Service


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
