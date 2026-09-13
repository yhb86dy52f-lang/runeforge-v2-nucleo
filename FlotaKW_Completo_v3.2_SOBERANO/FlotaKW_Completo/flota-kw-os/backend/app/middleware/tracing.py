import uuid
import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
logger = structlog.get_logger()

class TracingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        trace_id = request.headers.get("X-Trace-Id") or str(uuid.uuid4())[:8].upper()
        request.state.trace_id = trace_id
        structlog.contextvars.bind_contextvars(trace_id=trace_id, path=request.url.path)
        response = await call_next(request)
        response.headers["X-Trace-Id"] = trace_id
        structlog.contextvars.clear_contextvars()
        return response
