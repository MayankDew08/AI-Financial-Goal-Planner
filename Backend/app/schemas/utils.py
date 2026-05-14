from pydantic import BaseModel




class CacheKeyMeta(BaseModel):
    namespace: str
    version: str = "v1"