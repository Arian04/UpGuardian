import asyncio
import sys

import uvicorn

from .main import init_db, run_tests_helper

async def cli_main(service_id: int) -> None:
    thingy = await run_tests_helper(
        service_id,
        db_manager=init_db()
    )
    print(thingy)

def main():
    if sys.argv[1] == 'cli':
        service_id = int(sys.argv[2])
        asyncio.run(cli_main(service_id))
    else:
        uvicorn.run('upguardian_backend.main:app', port=8000)
