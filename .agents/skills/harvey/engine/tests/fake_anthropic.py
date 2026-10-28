"""A localhost stand-in for the Anthropic Messages API, for driving the real
Claude CLI in tests with no credentials and no network.

    python fake_anthropic.py <log.jsonl> <port-file>

Binds 127.0.0.1 on a free port, writes the port to <port-file>, and answers
every POST .../messages with a short streamed (or plain JSON) reply. Each
request is appended to <log.jsonl> as {"method", "path", "headers": [names],
"body"}: header NAMES only, never values, so nothing credential-shaped is
ever written down even if a client sends one.
"""

import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG, PORT_FILE = sys.argv[1], sys.argv[2]
_lock = threading.Lock()
REPLY = "FAKE-REPLY"


def _record(handler, body):
    entry = {
        "method": handler.command,
        "path": handler.path,
        "headers": sorted(k.lower() for k in handler.headers.keys()),
        "body": body,
    }
    with _lock, open(LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):  # keep stderr quiet
        pass

    def _send(self, code, payload, ctype="application/json"):
        data = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        _record(self, None)
        self._send(404, {"type": "error", "error": {"type": "not_found_error",
                                                    "message": "fake"}})

    do_HEAD = do_GET
    do_DELETE = do_GET

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b""
        try:
            body = json.loads(raw or b"null")
        except ValueError:
            body = raw.decode("utf-8", "replace")
        _record(self, body)
        path = self.path.split("?", 1)[0]
        if path.endswith("/count_tokens"):
            return self._send(200, {"input_tokens": 1})
        if not path.endswith("/messages"):
            return self._send(404, {"type": "error", "error": {
                "type": "not_found_error", "message": "fake"}})
        model = (body or {}).get("model", "fake-model") if isinstance(body, dict) else "fake"
        usage = {"input_tokens": 1, "output_tokens": 1,
                 "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0}
        message = {"id": "msg_fake", "type": "message", "role": "assistant", "model": model,
                   "content": [], "stop_reason": None, "stop_sequence": None,
                   "usage": usage}
        if not (isinstance(body, dict) and body.get("stream")):
            message["content"] = [{"type": "text", "text": REPLY}]
            message["stop_reason"] = "end_turn"
            return self._send(200, message)
        events = [
            ("message_start", {"type": "message_start", "message": message}),
            ("content_block_start", {"type": "content_block_start", "index": 0,
                                     "content_block": {"type": "text", "text": ""}}),
            ("content_block_delta", {"type": "content_block_delta", "index": 0,
                                     "delta": {"type": "text_delta", "text": REPLY}}),
            ("content_block_stop", {"type": "content_block_stop", "index": 0}),
            ("message_delta", {"type": "message_delta",
                               "delta": {"stop_reason": "end_turn", "stop_sequence": None},
                               "usage": {"output_tokens": 1}}),
            ("message_stop", {"type": "message_stop"}),
        ]
        data = "".join(f"event: {name}\ndata: {json.dumps(payload)}\n\n"
                       for name, payload in events).encode()
        self._send(200, data, ctype="text/event-stream")


def main():
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    with open(PORT_FILE, "w") as f:
        f.write(str(server.server_address[1]))
    server.serve_forever()


if __name__ == "__main__":
    main()
