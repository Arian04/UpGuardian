import sys

import uvicorn

SERVER_VERSION_ARG: int = int(sys.argv[1])

def main() -> None:
    uvicorn.run("demo_backend.main:app", port=5000, log_level="info")
