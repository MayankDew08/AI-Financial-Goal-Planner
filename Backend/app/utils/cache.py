import hashlib
import json
import logging
from typing import Any, Callable

from pydantic import BaseModel

from app.schemas.utils import CacheKeyMeta
from app.utils.redis_setup import redis as redis_client

logger = logging.getLogger("cache_utils")

DEFAULT_CACHE_TTL_SECONDS = 300


def _to_payload_dict(payload: BaseModel | dict[str, Any]) -> dict[str, Any]:
    if isinstance(payload, BaseModel):
        return payload.model_dump(mode="json")
    return payload


def make_cache_key(namespace: str, payload: BaseModel | dict[str, Any], version: str = "v1") -> str:
    meta = CacheKeyMeta(namespace=namespace, version=version)
    payload_dict = _to_payload_dict(payload)
    raw = json.dumps(payload_dict, sort_keys=True, separators=(",", ":"), default=str)
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    return f"{meta.namespace}:{meta.version}:{digest}"


def _get_json_from_cache(cache_key: str) -> Any | None:
    try:
        cached = redis_client.get(cache_key)
        if cached is None:
            return None
        if isinstance(cached, bytes):
            cached = cached.decode("utf-8")
        if isinstance(cached, str):
            return json.loads(cached)
        return cached
    except Exception as exc:
        logger.error({
            "event": "cache_get_failed",
            "cache_key": cache_key,
            "error_type": type(exc).__name__,
            "error": str(exc),
            "note": "Redis connection issue — cache miss, will recompute"
        })
        return None


def _set_json_in_cache(cache_key: str, value: Any, ttl_seconds: int) -> None:
    try:
        payload = json.dumps(value, default=str)
        redis_client.set(cache_key, payload, ex=ttl_seconds)
        logger.info({
            "event": "cache_set_success",
            "cache_key": cache_key,
            "ttl_seconds": ttl_seconds
        })
    except Exception as exc:
        logger.error({
            "event": "cache_set_failed",
            "cache_key": cache_key,
            "error_type": type(exc).__name__,
            "error": str(exc),
            "note": "Redis unavailable — result will not be cached"
        })


def get_or_set_cache(
    namespace: str,
    payload: BaseModel | dict[str, Any],
    compute_fn: Callable[[], Any],
    ttl_seconds: int = DEFAULT_CACHE_TTL_SECONDS,
) -> Any:
    cache_key = make_cache_key(namespace=namespace, payload=payload)
    cached = _get_json_from_cache(cache_key)
    
    if cached is not None:
        logger.info({
            "event": "cache_hit",
            "namespace": namespace,
            "cache_key": cache_key,
            "ttl_seconds": ttl_seconds
        })
        return cached

    logger.info({
        "event": "cache_miss",
        "namespace": namespace,
        "cache_key": cache_key,
        "will_compute": True
    })
    
    result = compute_fn()
    _set_json_in_cache(cache_key, result, ttl_seconds)
    return result