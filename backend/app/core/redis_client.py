import json
from typing import Any, Optional

import redis.asyncio as redis

from app.config import get_settings

settings = get_settings()
_redis: Optional[redis.Redis] = None


async def get_redis() -> redis.Redis:
    global _redis
    if _redis is None:
        _redis = redis.from_url(settings.redis_url, decode_responses=True)
    return _redis


async def cache_get(key: str) -> Optional[Any]:
    client = await get_redis()
    value = await client.get(key)
    if value:
        return json.loads(value)
    return None


async def cache_set(key: str, value: Any, ttl: int = 3600) -> None:
    client = await get_redis()
    await client.setex(key, ttl, json.dumps(value, default=str))


async def rate_limit_check(key: str, limit: int, window: int = 60) -> bool:
    """Returns True if request is allowed."""
    client = await get_redis()
    current = await client.incr(key)
    if current == 1:
        await client.expire(key, window)
    return current <= limit
