import json
from app.database import get_redis

CACHE_TTL = 300  # 5 minutes

PARKING_STATS_KEY = "parking:stats"
SPOT_STATUS_KEY = "parking:spot:{}"

_memory_cache: dict = {}


def _cache_get(key: str) -> str | None:
    r = get_redis()
    if r:
        return r.get(key)
    entry = _memory_cache.get(key)
    if entry:
        import time
        value, expires = entry
        if time.time() < expires:
            return value
        del _memory_cache[key]
    return None


def _cache_set(key: str, value: str, ttl: int = CACHE_TTL) -> None:
    r = get_redis()
    if r:
        r.set(key, value, ex=ttl)
        return
    import time
    _memory_cache[key] = (value, time.time() + ttl)


def _cache_delete(key: str) -> None:
    r = get_redis()
    if r:
        r.delete(key)
        return
    _memory_cache.pop(key, None)


def get_spot_cache(spot_id: int) -> str | None:
    return _cache_get(SPOT_STATUS_KEY.format(spot_id))


def set_spot_cache(spot_id: int, status: str) -> None:
    _cache_set(SPOT_STATUS_KEY.format(spot_id), status)


def delete_spot_cache(spot_id: int) -> None:
    _cache_delete(SPOT_STATUS_KEY.format(spot_id))


def get_parking_stats() -> dict | None:
    data = _cache_get(PARKING_STATS_KEY)
    return json.loads(data) if data else None


def set_parking_stats(stats: dict) -> None:
    _cache_set(PARKING_STATS_KEY, json.dumps(stats), ttl=60)


def delete_parking_stats() -> None:
    _cache_delete(PARKING_STATS_KEY)


def publish_parking_update(message: dict) -> None:
    r = get_redis()
    if r:
        r.publish("parking_updates", json.dumps(message))


def subscribe_parking_updates():
    r = get_redis()
    if r:
        pubsub = r.pubsub()
        pubsub.subscribe("parking_updates")
        return pubsub
    return None
