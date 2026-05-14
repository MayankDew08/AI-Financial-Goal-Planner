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


@app.on_event("startup")
def startup_event():
    # Database setup with better error handling
    try:
        Base.metadata.create_all(bind=engine)
        logger.info({"event": "database_ready", "status": "ok"})
    except Exception as db_error:
        error_msg = str(db_error)
        if "ENOTFOUND" in error_msg or "not found" in error_msg:
            logger.error({
                "event": "database_connection_failed",
                "error": "Supabase credentials are invalid or expired",
                "action_required": "Update SQLALCHEMY_DATABASE_URL in .env with fresh credentials",
                "details": error_msg[:200]
            })
        else:
            logger.error({
                "event": "database_connection_failed",
                "error": str(db_error)
            })
        # Don't crash on startup - let it continue so you can debug
        logger.warning("⚠️ Database not available. API is running but DB operations will fail.")
    
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
    return {"status": "ok"}
