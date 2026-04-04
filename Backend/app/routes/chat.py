"""
Chat endpoint for conversational chatbot.
Wires FastAPI requests to LangGraph state machine.
"""

from fastapi import APIRouter, Depends, HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.routes.auth import get_current_user
from app.models.db import User
from app.services.chatbot_graph import chatbot_app
from app.utils.log_format import JSONFormatter
import logging
from datetime import datetime

handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger = logging.getLogger("chat_router")
if not logger.handlers:
    logger.addHandler(handler)
logger.setLevel(logging.INFO)

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message")
async def chat_message(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Send a message to the chatbot.
    
    The chatbot maintains session state per session_id.
    Uses LangGraph to orchestrate intent detection, slot collection, 
    tool invocation, and explanation generation.
    """
    if not current_user:
        raise HTTPException(status_code=401, detail="Authentication required")

    user_id = current_user.id
    session_id = request.session_id

    logger.info({
        "event": "chat_message_received",
        "user_id": user_id,
        "session_id": session_id,
        "message": request.message,
        "timestamp": datetime.utcnow().isoformat(),
    })

    try:
        # Configure for this session/thread
        config = {"configurable": {"thread_id": session_id}}

        # Input state for this turn. Do not overwrite checkpointed progress.
        input_state = {
            "messages": [{"role": "user", "content": request.message}],
            "user_id": user_id,
            "session_id": session_id,
        }

        # Invoke graph
        result = await chatbot_app.ainvoke(input_state, config=config)

        # Extract response
        response = ChatResponse(
            reply=result.get("reply", ""),
            pending_fields=result.get("pending", []),
            action_state=result.get("action_state", "done"),
            can_confirm=result.get("can_confirm", False),
            session_id=session_id,
        )

        logger.info({
            "event": "chat_message_sent",
            "user_id": user_id,
            "session_id": session_id,
            "intent": result.get("intent"),
            "action_state": result.get("action_state"),
            "timestamp": datetime.utcnow().isoformat(),
        })

        return response

    except Exception as e:
        logger.error({
            "event": "chat_error",
            "user_id": user_id,
            "session_id": session_id,
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat(),
        })

        raise HTTPException(
            status_code=500,
            detail=f"Chat error: {str(e)}"
        )


@router.get("/session/{session_id}")
async def get_session_state(
    session_id: str,
    current_user: User = Depends(get_current_user),
):
    """
    Fetch current state of a chat session.
    Useful for resuming interrupted conversations.
    """
    if not current_user:
        raise HTTPException(status_code=401, detail="Authentication required")

    try:
        config = {"configurable": {"thread_id": session_id}}
        state = chatbot_app.get_state(config)
        
        return {
            "session_id": session_id,
            "state": state.values,
        }
    except Exception as e:
        logger.error(f"Error fetching session: {e}")
        raise HTTPException(status_code=500, detail=str(e))