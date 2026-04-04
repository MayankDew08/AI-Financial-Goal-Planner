#!/usr/bin/env python3
"""
Manual chatbot testing script.
Run this to test the chat endpoint interactively.

Usage:
    python tests/manual_chat_test.py
    
This will:
    1. Register a test user
    2. Create a session
    3. Let you type utterances and see bot responses
    4. Show all response fields for debugging
"""

import asyncio
import httpx
import json
import sys
from datetime import datetime
from typing import Optional

# ──────────────────────────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────────────────────────

BASE_URL = "http://127.0.0.1:8000"
TEST_USER_EMAIL = "chatbot_test@example.com"
TEST_USER_PASSWORD = "TestPassword123!"

# ──────────────────────────────────────────────────────────────────
# TEST SCENARIOS
# ──────────────────────────────────────────────────────────────────

SCENARIOS = {
    "1": {
        "name": "Retirement Create (Full Flow)",
        "session_id": "scenario_retirement_01",
        "utterances": [
            "I want to plan my retirement",
            "60",
            "45000",
            "75",
            "85",
            "yes"
        ]
    },
    "2": {
        "name": "One-Time Goal Create",
        "session_id": "scenario_onetime_01",
        "utterances": [
            "I want to save for a house",
            "House Purchase",
            "80 lakhs",
            "7",
            "yes"
        ]
    },
    "3": {
        "name": "Scenario Simulate",
        "session_id": "scenario_simulate_01",
        "utterances": [
            # Must have filled retirement first
            "what if I retire at 55",
        ]
    },
    "4": {
        "name": "Portfolio Overview",
        "session_id": "scenario_portfolio_01",
        "utterances": [
            "show me my complete financial picture"
        ]
    },
    "5": {
        "name": "Error Recovery (Invalid Input)",
        "session_id": "scenario_error_01",
        "utterances": [
            "I want to retire",
            "abc",  # Invalid → should error and ask again
            "60",   # Valid → should proceed
        ]
    }
}

# ──────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────

async def register_user(client: httpx.AsyncClient) -> str:
    """Register/login test user and return JWT token."""
    print("\n📝 Registering test user...")
    
    # Try register (might already exist)
    try:
        resp = await client.post(
            f"{BASE_URL}/api/v1/auth/register",
            json={
                "email": TEST_USER_EMAIL,
                "password": TEST_USER_PASSWORD,
                "role": "user"
            },
            timeout=10
        )
        print(f"   Register response: {resp.status_code}")
    except Exception as e:
        print(f"   Register failed (may already exist): {e}")
    
    # Login
    print("🔑 Logging in...")
    resp = await client.post(
        f"{BASE_URL}/api/v1/auth/login",
        json={
            "email": TEST_USER_EMAIL,
            "password": TEST_USER_PASSWORD
        },
        timeout=10
    )
    
    if resp.status_code != 200:
        print(f"❌ Login failed: {resp.status_code}")
        print(f"   Response: {resp.text}")
        sys.exit(1)
    
    token = resp.json()["access_token"]
    print(f"✅ Logged in successfully")
    return token


async def chat(
    client: httpx.AsyncClient,
    token: str,
    message: str,
    session_id: str
) -> dict:
    """Send a chat message and return response."""
    headers = {"Authorization": f"Bearer {token}"}
    
    resp = await client.post(
        f"{BASE_URL}/api/v1/chat",
        headers=headers,
        json={"message": message, "session_id": session_id},
        timeout=30
    )
    
    if resp.status_code != 200:
        return {
            "error": f"HTTP {resp.status_code}",
            "detail": resp.text
        }
    
    return resp.json()


def print_response(response: dict, message: str):
    """Pretty-print bot response."""
    print()
    print("─" * 80)
    print(f"👤 You:  {message}")
    print("─" * 80)
    
    if "error" in response:
        print(f"❌ Error: {response['error']}")
        if "detail" in response:
            print(f"   Detail: {response['detail']}")
        return
    
    # Main response
    print(f"🤖 Bot:  {response.get('reply', 'No reply')}")
    print()
    
    # Metadata
    print("📊 Metadata:")
    print(f"   Action State:    {response.get('action_state', 'N/A')}")
    print(f"   Can Confirm:     {response.get('can_confirm', False)}")
    print(f"   Pending Fields:  {response.get('pending_fields', [])}")
    
    if response.get("pending_fields"):
        print(f"   ➜ {response['pending_fields'][0]} is next")

    print()


async def run_scenario(client: httpx.AsyncClient, token: str, scenario_key: str):
    """Run a predefined scenario."""
    scenario = SCENARIOS[scenario_key]
    
    print(f"\n{'='*80}")
    print(f"🎬 SCENARIO: {scenario['name']}")
    print(f"   Session: {scenario['session_id']}")
    print(f"{'='*80}")
    
    for i, utterance in enumerate(scenario["utterances"], 1):
        print(f"\n[Turn {i}]")
        response = await chat(
            client,
            token,
            utterance,
            scenario["session_id"]
        )
        print_response(response, utterance)
        
        # Small delay between turns for readability
        await asyncio.sleep(0.5)


async def interactive_mode(client: httpx.AsyncClient, token: str):
    """Interactive console mode for manual testing."""
    print(f"\n{'='*80}")
    print("💬 INTERACTIVE MODE")
    print("   Type your messages. Type 'session <id>' to change session.")
    print("   Type 'exit' to quit.")
    print(f"{'='*80}")
    
    session_id = f"manual_session_{int(datetime.now().timestamp())}"
    print(f"\n📍 Current Session: {session_id}")
    
    while True:
        print()
        try:
            user_input = input("You: ").strip()
        except EOFError:
            break
        
        if not user_input:
            continue
        
        if user_input.lower() == "exit":
            print("👋 Exiting...")
            break
        
        if user_input.lower().startswith("session "):
            new_session = user_input[8:].strip()
            session_id = new_session
            print(f"✅ Switched to session: {session_id}")
            continue
        
        response = await chat(client, token, user_input, session_id)
        print_response(response, user_input)


async def main():
    """Main entry point."""
    print(f"\n{'='*80}")
    print("🚀 CHATBOT MANUAL TESTING")
    print(f"{'='*80}")
    print(f"Backend: {BASE_URL}")
    
    async with httpx.AsyncClient() as client:
        # Auth
        token = await register_user(client)
        
        # Menu
        print(f"\n{'='*80}")
        print("MENU")
        print(f"{'='*80}")
        print("1. Retirement Create (Full Flow)")
        print("2. One-Time Goal Create")
        print("3. Scenario Simulate")
        print("4. Portfolio Overview")
        print("5. Error Recovery")
        print("6. Interactive Mode (Free-form chat)")
        print("0. Exit")
        print()
        
        choice = input("Choose option: ").strip()
        
        if choice == "0":
            print("Goodbye!")
            return
        
        if choice in SCENARIOS:
            await run_scenario(client, token, choice)
        elif choice == "6":
            await interactive_mode(client, token)
        else:
            print("Invalid choice.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\nCancelled by user.")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
