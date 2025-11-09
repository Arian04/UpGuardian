import uvicorn

def main() -> None:
    uvicorn.run("demo_backend.main:app", port=5000, log_level="info")
