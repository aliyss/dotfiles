#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "gemini-webapi==2.1.1",
#   "fastapi>=0.115",
#   "uvicorn>=0.30",
# ]
# ///
"""An OpenAI-compatible endpoint in front of the consumer Gemini web app.

Why this exists
---------------
Gemini-API (github.com/HanaokaYuzu/Gemini-API) is an async *library* that drives
the same gemini.google.com session your browser uses, so it costs nothing beyond
your existing Google account. Unlike the DeepSeek bridge next door it does not
ship a server, and what the rest of this machine speaks is the OpenAI API (the
local llama.cpp router, ollmcp, Avante, the `ask` command). This file is the
adapter: ~200 lines of FastAPI that translate OpenAI chat completions into
`GeminiClient.generate_content_stream`.

Endpoints
---------
  GET  /healthz                liveness + whether a session is established
  GET  /v1/models              the account's models (falls back to ["gemini"])
  POST /v1/chat/completions    OpenAI shape; `"stream": true` streams SSE

Non-OpenAI extras, both optional booleans in the request body:
  "thinking": true             -> Gemini's extended thinking
  "search":   true             -> accepted and ignored (the web app decides)

Conversation handling
---------------------
Gemini's web RPC has no separate system role, so the message list is folded into
a single prompt. A lone user message is passed through untouched (best quality);
anything longer becomes a `Role: text` transcript ending with `Assistant:`.

Auth
----
Cookies come from $GEMINI_COOKIE_FILE (default ~/.config/gemini-webapi/cookies.json,
written by `gemini-auth`): a JSON object with `__Secure-1PSID` and, normally,
`__Secure-1PSIDTS`. gemini-webapi rotates 1PSIDTS itself and caches it under
$GEMINI_COOKIE_PATH, which is why that is pinned next to the cookie file rather
than left in /tmp. A missing or rejected cookie is a 503 with instructions — the
server always starts, it only needs the session when a request arrives.
"""

from __future__ import annotations

import asyncio
import json
import os
import time
import uuid
from pathlib import Path
from typing import Any, AsyncGenerator

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, StreamingResponse
from gemini_webapi import GeminiClient, set_log_level
from gemini_webapi.constants import AccountStatus

HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", "8013"))
DEFAULT_MODEL = os.environ.get("GEMINI_DEFAULT_MODEL", "").strip() or None
INIT_TIMEOUT = float(os.environ.get("GEMINI_INIT_TIMEOUT", "60"))

_config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
COOKIE_FILE = Path(os.environ.get("GEMINI_COOKIE_FILE") or _config_home / "gemini-webapi" / "cookies.json")
# Where the library caches the rotated __Secure-1PSIDTS between runs. Its own
# default is a temp dir, which would silently re-authenticate on every boot.
os.environ.setdefault("GEMINI_COOKIE_PATH", str(COOKIE_FILE.parent))

# uvicorn already reports what matters; the library defaults to INFO.
set_log_level(os.environ.get("GEMINI_LOG_LEVEL", "WARNING"))

# Model names a client may send that mean "whatever the account defaults to".
# Anything else is resolved against the account's model registry and rejected
# with a 400 if it does not exist, rather than silently falling back.
DEFAULT_MODEL_NAMES = {"", "default", "gemini", "gemini-web", "gemini-webapi"}

app = FastAPI(title="gemini-bridge", docs_url=None, redoc_url=None)

_client: GeminiClient | None = None
_client_lock = asyncio.Lock()


class BridgeError(RuntimeError):
    """A setup problem the user can fix, reported as 503 instead of a crash."""


# --------------------------------------------------------------------------- #
# session
# --------------------------------------------------------------------------- #
def _load_cookies() -> tuple[str, str]:
    try:
        raw = json.loads(COOKIE_FILE.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise BridgeError(f"no Gemini cookies at {COOKIE_FILE} — run: gemini-auth") from exc
    except (OSError, ValueError) as exc:
        raise BridgeError(f"cannot read {COOKIE_FILE}: {exc} — re-run: gemini-auth") from exc

    if isinstance(raw, list):  # a browser cookie-extension export
        raw = {c.get("name"): c.get("value") for c in raw if isinstance(c, dict)}

    psid = raw.get("__Secure-1PSID")
    if not psid:
        raise BridgeError(f"{COOKIE_FILE} has no __Secure-1PSID — re-run: gemini-auth")
    return psid, raw.get("__Secure-1PSIDTS") or ""


async def get_client() -> GeminiClient:
    """The single signed-in client, created on first use."""
    global _client
    if _client is not None:
        return _client
    async with _client_lock:
        if _client is None:
            psid, psidts = _load_cookies()
            client = GeminiClient(secure_1psid=psid, secure_1psidts=psidts)
            try:
                # auto_refresh keeps 1PSIDTS (and the access token) alive for as
                # long as this process runs; without it the service would need a
                # restart every few hours.
                await client.init(
                    timeout=INIT_TIMEOUT,
                    auto_refresh=True,
                    auto_close=False,
                    verbose=False,
                )
            except Exception as exc:
                raise BridgeError(f"Gemini rejected the saved session ({exc}) — re-run: gemini-auth") from exc
            # init() succeeds even with expired cookies (it just fetches less), so
            # the account status is the only reliable "are we really signed in".
            if client.account_status != AccountStatus.AVAILABLE:
                raise BridgeError(
                    f"Gemini says this session is {client.account_status.name} — re-run: gemini-auth"
                )
            _client = client
    return _client


# --------------------------------------------------------------------------- #
# OpenAI <-> Gemini translation
# --------------------------------------------------------------------------- #
_ROLE_LABELS = {"system": "System", "developer": "System", "assistant": "Assistant", "tool": "Tool result", "user": "User"}


def _text_of(content: Any) -> str:
    """OpenAI `content` may be a string or a list of content parts."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(part.get("text", "") for part in content if isinstance(part, dict))
    return ""


def fold_messages(messages: list[dict[str, Any]]) -> str:
    turns: list[tuple[str, str]] = []
    for message in messages:
        text = _text_of(message.get("content")).strip()
        if not text:
            continue
        turns.append((_ROLE_LABELS.get(str(message.get("role", "user")), "User"), text))

    if not turns:
        return ""
    if len(turns) == 1 and turns[0][0] == "User":
        return turns[0][1]  # the common case: don't wrap a plain prompt in labels
    return "\n\n".join(f"{label}: {text}" for label, text in turns) + "\n\nAssistant:"


def pick_model(name: Any) -> str | None:
    name = str(name or "").strip()
    return None if name.lower() in DEFAULT_MODEL_NAMES else (name or DEFAULT_MODEL)


def error(status: int, message: str, kind: str = "bridge_error") -> JSONResponse:
    return JSONResponse(status_code=status, content={"error": {"message": message, "type": kind, "code": status}})


def sse(payload: dict[str, Any]) -> str:
    return "data: " + json.dumps(payload, separators=(",", ":")) + "\n\n"


def chunk(completion_id: str, created: int, model: str, delta: dict[str, Any], finish: str | None = None) -> str:
    return sse(
        {
            "id": completion_id,
            "object": "chat.completion.chunk",
            "created": created,
            "model": model,
            "choices": [{"index": 0, "delta": delta, "finish_reason": finish}],
        }
    )


async def stream_reply(
    client: GeminiClient,
    prompt: str,
    model: str | None,
    thinking: bool,
    completion_id: str,
    created: int,
    model_name: str,
) -> AsyncGenerator[str, None]:
    yield chunk(completion_id, created, model_name, {"role": "assistant", "content": ""})
    try:
        async for output in client.generate_content_stream(prompt, model=model, extended_thinking=thinking):
            delta = output.text_delta
            if delta:
                yield chunk(completion_id, created, model_name, {"content": delta})
    except Exception as exc:
        # The status line is long gone by now, so report in-band and stop.
        yield sse({"error": {"message": f"Gemini stream failed: {exc}", "type": "upstream_error", "code": 502}})
    yield chunk(completion_id, created, model_name, {}, finish="stop")
    yield "data: [DONE]\n\n"


# --------------------------------------------------------------------------- #
# routes
# --------------------------------------------------------------------------- #
@app.get("/healthz")
async def healthz() -> dict[str, Any]:
    return {"ok": True, "session": _client is not None, "cookie_file": str(COOKIE_FILE)}


@app.get("/v1/models")
async def list_models() -> dict[str, Any]:
    """Never fails: clients enumerate this before they can send a request.

    The account's real model names only exist once a session has been
    established, so an unauthenticated bridge reports the alias that means
    "the account default" and nothing else.
    """
    ids: list[str] = ["gemini"]
    if _client is not None:
        for entry in _client.list_models() or []:
            for name in [entry.model_name, *entry.aliases]:
                if name and name not in ids:
                    ids.append(name)
    return {
        "object": "list",
        "data": [{"id": i, "object": "model", "created": 0, "owned_by": "google"} for i in ids],
    }


@app.post("/v1/chat/completions")
async def chat_completions(request: Request) -> Any:
    try:
        body = await request.json()
    except Exception:
        return error(400, "request body is not valid JSON")
    if not isinstance(body, dict):
        return error(400, "request body must be a JSON object")

    messages = body.get("messages")
    if not isinstance(messages, list) or not messages:
        return error(400, "messages must be a non-empty list")
    prompt = fold_messages(messages)
    if not prompt:
        return error(400, "messages contain no text content")

    model = pick_model(body.get("model"))
    thinking = bool(body.get("thinking") or body.get("reasoning"))
    stream = bool(body.get("stream"))
    model_name = str(body.get("model") or "gemini")

    try:
        client = await get_client()
    except BridgeError as exc:
        return error(503, str(exc))
    except Exception as exc:  # unexpected: still tell the caller how to fix it
        return error(503, f"Gemini session could not be initialised: {exc}")

    if model is not None:
        try:
            client.resolve_model(model)
        except Exception:
            return error(400, f"unknown model {model!r} — see GET /v1/models")

    completion_id = f"chatcmpl-{uuid.uuid4().hex[:24]}"
    created = int(time.time())

    if stream:
        return StreamingResponse(
            stream_reply(client, prompt, model, thinking, completion_id, created, model_name),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    try:
        output = await client.generate_content(prompt, model=model, extended_thinking=thinking)
    except Exception as exc:
        return error(502, f"Gemini request failed: {exc}", kind="upstream_error")

    text = output.text or ""
    return JSONResponse(
        {
            "id": completion_id,
            "object": "chat.completion",
            "created": created,
            "model": model_name,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": text},
                    "finish_reason": "stop",
                }
            ],
            # The web RPC returns no counts; this is the same ~4 chars/token
            # estimate the DeepSeek bridge uses, so clients that display usage
            # show something sane instead of failing.
            "usage": {
                "prompt_tokens": max(1, len(prompt) // 4),
                "completion_tokens": max(1, len(text) // 4),
                "total_tokens": max(2, (len(prompt) + len(text)) // 4),
            },
        }
    )


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT, log_level=os.environ.get("LOG_LEVEL", "warning"))
