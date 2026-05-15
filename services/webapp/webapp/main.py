from fastapi import FastAPI

app = FastAPI(title="event-driven-ecommerce webapp", version="0.1.0")


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}
