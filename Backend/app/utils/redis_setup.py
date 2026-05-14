import os
from pathlib import Path
from dotenv import load_dotenv
from upstash_redis import Redis

# Load environment variables from .env file in Backend root directory
backend_dir = Path(__file__).parent.parent.parent
env_file = backend_dir / ".env"
load_dotenv(env_file)

url = os.getenv("UPSTASH_REDIS_REST_URL")
token = os.getenv("UPSTASH_REDIS_REST_TOKEN")

if not url or not token:
    raise ValueError(
        "Missing Redis credentials. Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN "
        "in your .env file or environment variables."
    )

redis = Redis(url=url, token=token)