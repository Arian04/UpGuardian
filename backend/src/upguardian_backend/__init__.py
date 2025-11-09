import asyncio
import sys

import uvicorn

from .main import init_db, run_tests_helper

async def cli_main(service_id: int) -> int:
    thingy = await run_tests_helper(
        service_id,
        db_manager=init_db()
    )
    print(thingy)

    if False in thingy["response_statuses"]:
        return 1

    return 0

def main()-> int:
    if sys.argv[1] == 'cli':
        service_id = int(sys.argv[2])
        return asyncio.run(cli_main(service_id))
    else:
        uvicorn.run('upguardian_backend.main:app', port=8000)
        return 0
