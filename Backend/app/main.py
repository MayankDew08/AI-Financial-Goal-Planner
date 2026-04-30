from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.databse import Base, engine
from app.models import db as db_models
from app.routes.auth import router as auth_router
from app.routes.calaculation import router as calculation_router
from app.routes.user import router as user_router
from app.routes.goals import router as goals_router
from app.routes.chat import router as chat_router
import logging
import threading

logger = logging.getLogger("startup")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(calculation_router)
app.include_router(user_router)
app.include_router(goals_router)
app.include_router(auth_router)
app.include_router(chat_router)

_db_initialized = False

def _init_db():
    global _db_initialized
    try:
        logger.info("Background: Starting database initialization...")
        Base.metadata.create_all(bind=engine)
        _db_initialized = True
        logger.info({"event": "database_ready", "status": "ok"})
    except Exception as db_error:
        _db_initialized = False
        logger.error({
            "event": "database_init_failed",
            "error": str(db_error)[:300]
        })

@app.on_event("startup")
def startup_event():
    # Start DB init in background (don't block startup)
    db_thread = threading.Thread(target=_init_db, daemon=True)
    db_thread.start()
    
    # Health check Redis
    try:
        from app.utils.redis_setup import redis
        redis.ping()
        logger.info({"event": "redis_connected", "status": "ok"})
    except Exception as e:
        logger.error({
            "event": "redis_unavailable",
            "error": str(e),
            "note": "Cache will not work. Ensure UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are set."
        })

@app.get("/")
def read_root():
    return {"Message": "Welcome to Financial Planning API"}

@app.get("/health")
def health_check():
    return {"status": "ok", "database_initialized": _db_initialized}
