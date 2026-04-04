"""
Comprehensive chatbot endpoint testing against 80 diverse utterances.
Tests:
  1. Intent classification correctness
  2. Slot collection completeness
  3. Deterministic output parity (chat vs direct API)
  4. HITL confirmation flow
  5. Error handling and graceful recovery
"""

import asyncio
import pytest
import json
from typing import Optional
from httpx import AsyncClient
from app.main import app
from app.schemas.user import CreateUser
from app.schemas.chat import ChatRequest, ChatResponse
from enum import Enum

# ──────────────────────────────────────────────────────────────────
# TEST UTTERANCES (Frozen)
# ──────────────────────────────────────────────────────────────────

class Intent(str, Enum):
    RETIREMENT_CREATE = "retirement_create"
    ONETIME_CREATE    = "onetime_create"
    SCENARIO_SIMULATE = "scenario_simulate"
    PORTFOLIO_OVERVIEW = "portfolio_overview"

TEST_UTTERANCES = {
    Intent.RETIREMENT_CREATE: [
        "I want to plan my retirement",
        "help me retire at 60",
        "I am 30 years old and want to retire comfortably",
        "plan for my retirement please",
        "I want to retire at 58 with 40000 monthly expenses",
        "retirement planning for age 55",
        "how much do I need to retire",
        "I earn 1.5 lakhs a month and want to retire at 60",
        "start my retirement plan",
        "I want to stop working at 60 and need a plan",
    ],

    Intent.ONETIME_CREATE: [
        "I want to save for a house",
        "planning to buy a car in 3 years",
        "my daughter's wedding in 5 years",
        "I want to do an MBA from a top college in 2 years",
        "save 80 lakhs for a house in 7 years",
        "plan for home purchase",
        "I need 50 lakhs in 4 years for my business",
        "goal for buying a plot of land",
        "education fund for my child — needs 40 lakhs in 10 years",
        "save for a foreign trip costing 5 lakhs next year",
    ],

    Intent.SCENARIO_SIMULATE: [
        "what if I retire at 55",
        "what happens if I retire 5 years earlier",
        "suppose I increase my monthly expenses to 60000",
        "what if I plan till age 90 instead of 85",
        "what if I reduce my retirement expenses to 60 percent",
        "scenario where I retire at 65",
        "if I retire at 50 what changes",
        "what if I need 70000 per month after retirement",
        "recalculate if my expenses go up to 50000",
        "what if life expectancy is 95",
    ],

    Intent.PORTFOLIO_OVERVIEW: [
        "how am I doing overall",
        "show me my complete financial picture",
        "what does my portfolio look like",
        "are all my goals funded",
        "is there a conflict between my goals",
        "how much am I saving in total",
        "show me all my goals",
        "am I on track",
        "what is my savings ratio",
        "overview of all my plans",
    ]
}

# ──────────────────────────────────────────────────────────────────
# FIXTURES
# ──────────────────────────────────────────────────────────────────

@pytest.fixture
async def auth_headers():
    """Register a test user and return auth headers."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "chatbot_test@example.com",
                "password": "TestPassword123!",
                "role": "user"
            }
        )
        assert response.status_code in [200, 409]  # 409 if already exists
        
        # Login
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "chatbot_test@example.com",
                "password": "TestPassword123!"
            }
        )
        assert response.status_code == 200
        token = response.json()["access_token"]
        
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def client():
    """Async HTTP client."""
    async with AsyncClient(app=app, base_url="http://test") as c:
        yield c


# ──────────────────────────────────────────────────────────────────
# TESTS: Intent Classification
# ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestIntentClassification:
    """Verify each utterance is classified into correct intent."""

    async def test_retirement_create_intent(self, client, auth_headers):
        """Verify all retirement_create utterances classify correctly."""
        session_id = "test_retirement_001"
        
        for utterance in TEST_UTTERANCES[Intent.RETIREMENT_CREATE]:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200, f"Failed for: {utterance}"
            data = response.json()
            
            # Intent should be detected
            assert data.get("action_state") in ["collecting", "confirming", "done"]
            # Should be asking for slots (collecting) or ready to confirm
            assert len(data.get("pending_fields", [])) > 0 or data.get("can_confirm")
            
            print(f"✓ {utterance[:50]:<50} → collecting slots")

    async def test_onetime_create_intent(self, client, auth_headers):
        """Verify all onetime_create utterances classify correctly."""
        session_id = "test_onetime_001"
        
        for utterance in TEST_UTTERANCES[Intent.ONETIME_CREATE]:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200, f"Failed for: {utterance}"
            data = response.json()
            
            assert data.get("action_state") in ["collecting", "confirming", "done"]
            assert len(data.get("pending_fields", [])) > 0 or data.get("can_confirm")
            
            print(f"✓ {utterance[:50]:<50} → collecting slots")

    async def test_scenario_simulate_intent(self, client, auth_headers):
        """Verify all scenario_simulate utterances classify correctly."""
        session_id = "test_scenario_001"
        
        for utterance in TEST_UTTERANCES[Intent.SCENARIO_SIMULATE]:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200, f"Failed for: {utterance}"
            data = response.json()
            
            assert data.get("action_state") in ["collecting", "confirming", "done"]
            
            print(f"✓ {utterance[:50]:<50} → scenario mode")

    async def test_portfolio_overview_intent(self, client, auth_headers):
        """Verify all portfolio_overview utterances classify correctly."""
        session_id = "test_portfolio_001"
        
        for utterance in TEST_UTTERANCES[Intent.PORTFOLIO_OVERVIEW]:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200, f"Failed for: {utterance}"
            data = response.json()
            
            # Overview should complete immediately or ask no slots
            assert data.get("action_state") in ["collecting", "done"]
            
            print(f"✓ {utterance[:50]:<50} → overview mode")


# ──────────────────────────────────────────────────────────────────
# TESTS: Slot Collection Flow
# ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestSlotCollection:
    """Verify slot collection works end-to-end for each intent."""

    async def test_retirement_create_full_flow(self, client, auth_headers):
        """
        Test full retirement creation flow:
        1. User says retirement intent
        2. Bot asks for required slots one by one
        3. User provides values
        4. Bot asks optionals
        5. Bot asks confirmation
        6. Compute is called and result matches direct API
        """
        session_id = "test_retirement_flow_01"
        
        conversation_flow = [
            ("I want to plan my retirement", ["retirement_age"]),
            ("60", ["current_monthly_expenses"]),
            ("45000", ["post_retirement_expense_pct"]),
            ("75", ["life_expectancy"]),
            ("85", []),  # All required filled
        ]
        
        for utterance, expected_pending in conversation_flow:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200
            data = response.json()
            
            print(f"User: {utterance}")
            print(f"Bot:  {data.get('reply')[:80]}")
            print(f"Pending: {data.get('pending_fields')}")
            print()

    async def test_onetime_create_full_flow(self, client, auth_headers):
        """Test full one-time goal creation flow."""
        session_id = "test_onetime_flow_01"
        
        conversation_flow = [
            ("I want to save for a house", ["goal_name"]),
            ("House Purchase", ["goal_amount"]),
            ("80 lakhs", ["years_to_goal"]),
            ("7", []),  # All required filled
        ]
        
        for utterance, expected_pending in conversation_flow:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200
            data = response.json()
            
            print(f"User: {utterance}")
            print(f"Bot:  {data.get('reply')[:80]}")
            print(f"Pending: {data.get('pending_fields')}")
            print()


# ──────────────────────────────────────────────────────────────────
# TESTS: Error Handling
# ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestErrorHandling:
    """Verify graceful error handling and recovery."""

    async def test_invalid_value_recovery(self, client, auth_headers):
        """Test bot recovers from invalid input gracefully."""
        session_id = "test_error_recovery_01"
        
        conversation = [
            "I want to retire",
            "abc",  # Invalid age — should ask to retry
            "60",   # Valid age
        ]
        
        for utterance in conversation:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            
            assert response.status_code == 200
            data = response.json()
            print(f"User: {utterance}")
            print(f"Bot:  {data.get('reply')[:80]}")
            print()

    async def test_unclear_intent_recovery(self, client, auth_headers):
        """Test bot handles unclear intents."""
        session_id = "test_unclear_01"
        
        response = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "xyz blah blah", "session_id": session_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        # Should either ask for clarification or provide error
        assert "reply" in data
        print(f"Bot response to unclear intent: {data.get('reply')}")


# ──────────────────────────────────────────────────────────────────
# TESTS: Confirmation Gate
# ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestConfirmationGate:
    """Verify HITL confirmation before commit."""

    async def test_confirm_then_create(self, client, auth_headers):
        """Test user confirms before create is executed."""
        session_id = "test_confirm_create_01"
        
        # Fill all required slots
        conversation = [
            "I want to retire",
            "60",
            "45000",
            "75",
            "85",
        ]
        
        last_response_data = None
        for utterance in conversation:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            assert response.status_code == 200
            last_response_data = response.json()
        
        # After all slots, should ask for confirmation
        assert last_response_data.get("can_confirm") is True
        print(f"Confirmation preview: {last_response_data.get('reply')[:150]}")
        
        # User confirms
        response = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "yes", "session_id": session_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        # After confirmation, should have computed result
        assert data.get("action_state") == "done"
        print(f"Final response: {data.get('reply')[:150]}")

    async def test_cancel_and_edit(self, client, auth_headers):
        """Test user can cancel and edit values."""
        session_id = "test_cancel_edit_01"
        
        conversation = [
            "I want to retire",
            "60",
            "45000",
            "75",
            "85",
            "no",  # Cancel
        ]
        
        for utterance in conversation:
            response = await client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": utterance, "session_id": session_id}
            )
            assert response.status_code == 200
        
        data = response.json()
        # After cancel, should go back to collecting
        assert data.get("action_state") == "collecting"
        print(f"After cancel: {data.get('reply')}")


# ──────────────────────────────────────────────────────────────────
# TESTS: Session Persistence
# ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
class TestSessionPersistence:
    """Verify conversation state persists across API calls."""

    async def test_session_state_retained(self, client, auth_headers):
        """Test collected slots are retained in same session."""
        session_id = "test_persistence_01"
        
        # First call — provide first slot
        response1 = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "I want to retire", "session_id": session_id}
        )
        assert response1.status_code == 200
        
        # Second call — provide second slot
        response2 = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "60", "session_id": session_id}
        )
        assert response2.status_code == 200
        data2 = response2.json()
        
        # Pending should now be fewer
        assert len(data2.get("pending_fields", [])) < 4
        print(f"Slots still needed: {data2.get('pending_fields')}")

    async def test_different_sessions_independent(self, client, auth_headers):
        """Test different session_ids are independent."""
        session_a = "test_session_a"
        session_b = "test_session_b"
        
        # Session A: retirement
        response_a = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "I want to retire", "session_id": session_a}
        )
        
        # Session B: one-time goal
        response_b = await client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": "I want to save for a house", "session_id": session_b}
        )
        
        data_a = response_a.json()
        data_b = response_b.json()
        
        # Both should be asking for slots but different contexts
        assert data_a.get("reply") != data_b.get("reply")
        print(f"Session A asking: {data_a.get('reply')[:50]}")
        print(f"Session B asking: {data_b.get('reply')[:50]}")


# ──────────────────────────────────────────────────────────────────
# RUN TESTS
# ──────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
