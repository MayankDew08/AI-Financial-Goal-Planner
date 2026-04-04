from __future__ import annotations

import json
import logging
import os
from typing import Any, Dict

from openai import OpenAI
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

logger = logging.getLogger("services_utils")


def get_db():
    db = {"connection": "db_connection"}
    try:
        yield db
    finally:
        db.clear()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


# ─── LLM HELPERS ───────────────────────────────────────────────────────────


def _get_hf_client() -> OpenAI:
    hf_token = os.getenv("HF_TOKEN")
    if not hf_token:
        raise ValueError("HF_TOKEN not found in environment variables")

    return OpenAI(
        base_url="https://router.huggingface.co/v1",
        api_key=hf_token.strip('"').strip("'"),
    )


def call_llm(prompt: str, model: str = "MiniMaxAI/MiniMax-M2.5:novita") -> str:
    """
    Call Hugging Face MiniMax via the router API and return text response.
    """
    try:
        client = _get_hf_client()
        completion = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=4096,
            temperature=0.7,
        )
        return (completion.choices[0].message.content or "").strip()
    except Exception as exc:
        logger.error("HuggingFace LLM error: %s", exc)
        return f"Error calling LLM: {exc}"


def call_llm_json(prompt: str, model: str = "MiniMaxAI/MiniMax-M2.5:fastest") -> Dict[str, Any]:
    """
    Call Hugging Face MiniMax via the router API and parse JSON output.
    """
    try:
        client = _get_hf_client()
        json_prompt = f"{prompt}\n\nRespond with ONLY valid JSON, no other text."
        completion = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": json_prompt}],
            max_tokens=2048,
            temperature=0.1,
        )

        response_text = (completion.choices[0].message.content or "").strip()
        if response_text.startswith("```json"):
            response_text = response_text[len("```json"):].strip()
        if response_text.startswith("```"):
            response_text = response_text[len("```"):].strip()
        if response_text.endswith("```"):
            response_text = response_text[:-3].strip()

        try:
            return json.loads(response_text)
        except json.JSONDecodeError:
            logger.warning("Failed to parse JSON directly: %s", response_text)
            if "```json" in response_text:
                json_str = response_text.split("```json", 1)[1].split("```", 1)[0].strip()
                return json.loads(json_str)
            if "```" in response_text:
                json_str = response_text.split("```", 1)[1].split("```", 1)[0].strip()
                return json.loads(json_str)
            if "{" in response_text and "}" in response_text:
                start = response_text.find("{")
                end = response_text.rfind("}") + 1
                return json.loads(response_text[start:end])
            raise json.JSONDecodeError("No JSON found in response", response_text, 0)
    except Exception as exc:
        logger.error("HuggingFace LLM JSON error: %s", exc)
        return {"error": str(exc), "intent": "unclear"}
