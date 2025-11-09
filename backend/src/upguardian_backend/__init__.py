import uvicorn

def main():
    uvicorn.run('upguardian_backend.main:app', port=8000)
