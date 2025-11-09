import asyncio
import sqlite3
from typing import Optional


class Request:
    """Represents a stored HTTP request row backed by sqlite3.

    Provides async getters/setters for its fields. The object holds the DB
    connection and the integer primary key id.
    """

    def __init__(self, db_conn: sqlite3.Connection, id: int):
        self._conn = db_conn
        self.id = id

    async def get_service(self) -> Optional[int]:
        def _get():
            cur = self._conn.execute("SELECT service FROM requests WHERE id = ?", (self.id,))
            row = cur.fetchone()
            return int(row[0]) if row else None

        return await asyncio.to_thread(_get)

    async def set_service(self, service_id: int) -> None:
        def _set():
            self._conn.execute("UPDATE requests SET service = ? WHERE id = ?", (service_id, self.id))
            self._conn.commit()

        await asyncio.to_thread(_set)

    async def get_endpoint(self) -> Optional[str]:
        def _get():
            cur = self._conn.execute("SELECT endpoint FROM requests WHERE id = ?", (self.id,))
            row = cur.fetchone()
            return row[0] if row else None

        return await asyncio.to_thread(_get)

    async def set_endpoint(self, endpoint: str) -> None:
        def _set():
            self._conn.execute("UPDATE requests SET endpoint = ? WHERE id = ?", (endpoint, self.id))
            self._conn.commit()

        await asyncio.to_thread(_set)

    async def get_method(self) -> Optional[str]:
        def _get():
            cur = self._conn.execute("SELECT method FROM requests WHERE id = ?", (self.id,))
            row = cur.fetchone()
            return row[0] if row else None

        return await asyncio.to_thread(_get)

    async def set_method(self, method: str) -> None:
        def _set():
            self._conn.execute("UPDATE requests SET method = ? WHERE id = ?", (method, self.id))
            self._conn.commit()

        await asyncio.to_thread(_set)

    async def get_body(self) -> Optional[str]:
        def _get():
            cur = self._conn.execute("SELECT body FROM requests WHERE id = ?", (self.id,))
            row = cur.fetchone()
            return row[0] if row else None

        return await asyncio.to_thread(_get)

    async def set_body(self, body: Optional[str]) -> None:
        def _set():
            self._conn.execute("UPDATE requests SET body = ? WHERE id = ?", (body, self.id))
            self._conn.commit()

        await asyncio.to_thread(_set)

    async def to_dict(self) -> dict:
        def _get():
            cur = self._conn.execute("SELECT id, service, endpoint, method, body FROM requests WHERE id = ?", (self.id,))
            row = cur.fetchone()
            if not row:
                return {}
            return {"id": int(row[0]), "service": int(row[1]), "endpoint": row[2], "method": row[3], "body": row[4]}

        return await asyncio.to_thread(_get)
