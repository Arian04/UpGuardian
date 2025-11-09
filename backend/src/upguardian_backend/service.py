import asyncio
import sqlite3
from typing import Optional


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
