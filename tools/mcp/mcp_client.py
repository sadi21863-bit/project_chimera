"""
MCP Client for Project Chimera Hub.

Communicates with the MCP server via stdio transport (JSON-RPC 2.0).
This allows play scripts to use the full MCP tool layer instead of raw TCP.
"""

import subprocess
import json
import sys
import os
import threading
import time
from typing import Any, Optional

CHIMERA_ROOT = os.environ.get("CHIMERA_ROOT", r"C:\Users\aditya\Desktop\project-chimera\godot")
MCP_SERVER_PATH = os.path.join(os.path.dirname(__file__), "chimera-hub", "index.js")


class MCPClient:
    """MCP client that communicates with chimera-hub via stdio."""

    def __init__(self, server_path: str = MCP_SERVER_PATH, timeout: float = 30.0):
        self.server_path = server_path
        self.timeout = timeout
        self.process: Optional[subprocess.Popen] = None
        self._request_id = 0
        self._lock = threading.Lock()
        self._stdout_thread: Optional[threading.Thread] = None
        self._pending: dict[int, threading.Event] = {}
        self._responses: dict[int, dict] = {}
        self._notifications: list[dict] = []
        self._tools: list[dict] = []

    def connect(self) -> bool:
        """Start the MCP server process and perform handshake."""
        env = os.environ.copy()
        env["CHIMERA_ROOT"] = CHIMERA_ROOT

        self.process = subprocess.Popen(
            ["node", self.server_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )

        # Start stdout reader thread
        self._stdout_thread = threading.Thread(target=self._read_stdout, daemon=True)
        self._stdout_thread.start()

        # Drain stderr in a background thread: if node writes enough diagnostics
        # to fill the OS pipe buffer while nobody reads, node blocks on write,
        # stops consuming stdin, and our stdin.flush() deadlocks forever.
        self._stderr_lines: list[str] = []
        self._stderr_thread = threading.Thread(target=self._read_stderr, daemon=True)
        self._stderr_thread.start()

        # Send initialize
        resp = self._send_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "chimera-playtest", "version": "1.0.0"},
        })
        if not resp or "error" in resp:
            print(f"Initialize failed: {resp}", file=sys.stderr)
            return False

        # Send initialized notification
        self._send_notification("notifications/initialized", {})

        # List tools
        tools_resp = self._send_request("tools/list", {})
        if tools_resp and "result" in tools_resp:
            self._tools = tools_resp["result"].get("tools", [])

        return True

    def disconnect(self):
        """Stop the MCP server process."""
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()

    def get_tools(self) -> list[dict]:
        """Return list of available tools."""
        return self._tools

    def call_tool(self, name: str, arguments: dict = None) -> dict:
        """Call an MCP tool by name with arguments."""
        resp = self._send_request("tools/call", {
            "name": name,
            "arguments": arguments or {},
        })
        if not resp:
            return {"error": "No response from server"}
        if "error" in resp:
            return {"error": resp["error"].get("message", str(resp["error"]))}
        return resp.get("result", {})

    def _next_id(self) -> int:
        with self._lock:
            self._request_id += 1
            return self._request_id

    def _send_request(self, method: str, params: dict) -> Optional[dict]:
        """Send a JSON-RPC request and wait for response."""
        req_id = self._next_id()
        msg = {
            "jsonrpc": "2.0",
            "id": req_id,
            "method": method,
            "params": params,
        }

        event = threading.Event()
        self._pending[req_id] = event

        try:
            self.process.stdin.write(json.dumps(msg) + "\n")
            self.process.stdin.flush()
        except (BrokenPipeError, OSError) as e:
            return {"error": {"message": f"Write failed: {e}"}}

        # Wait for response
        if event.wait(timeout=self.timeout):
            return self._responses.pop(req_id, None)
        else:
            self._pending.pop(req_id, None)
            return {"error": {"message": f"Timeout waiting for {method}"}}

    def _send_notification(self, method: str, params: dict):
        """Send a JSON-RPC notification (no response expected)."""
        msg = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        }
        try:
            self.process.stdin.write(json.dumps(msg) + "\n")
            self.process.stdin.flush()
        except (BrokenPipeError, OSError):
            pass

    def _read_stdout(self):
        """Background thread reading JSON-RPC responses from server stdout."""
        while self.process and self.process.poll() is None:
            try:
                line = self.process.stdout.readline()
                if not line:
                    break
                line = line.strip()
                if not line:
                    continue
                msg = json.loads(line)
                if "id" in msg:
                    req_id = msg["id"]
                    if req_id in self._pending:
                        self._responses[req_id] = msg
                        self._pending[req_id].set()
                else:
                    self._notifications.append(msg)
            except json.JSONDecodeError:
                continue
            except UnicodeDecodeError:
                continue
            except Exception as e:
                # Never die silently: a dead reader thread makes every future
                # request time out with no visible cause.
                print(f"[mcp_client] stdout reader stopped: {e}", file=sys.stderr)
                break

    def _read_stderr(self):
        """Background thread draining server stderr to prevent pipe-full deadlock."""
        try:
            for line in self.process.stderr:
                self._stderr_lines.append(line.rstrip())
        except Exception:
            pass


def get_tool_text(result: dict) -> str:
    """Extract text content from an MCP tool call result."""
    contents = result.get("content", [])
    texts = []
    for c in contents:
        if c.get("type") == "text":
            texts.append(c.get("text", ""))
    return "\n".join(texts)


def get_tool_images(result: dict) -> list[dict]:
    """Extract image content from an MCP tool call result."""
    contents = result.get("content", [])
    return [c for c in contents if c.get("type") == "image"]


def is_tool_error(result: dict) -> bool:
    """Check if a tool result indicates an error."""
    return result.get("isError", False)


if __name__ == "__main__":
    client = MCPClient()
    print("Connecting to MCP server...")
    if client.connect():
        tools = client.get_tools()
        print(f"Connected! {len(tools)} tools available:")
        for t in tools:
            print(f"  - {t['name']}: {t.get('description', '')[:60]}")

        # Test a static tool
        print("\n--- Testing chimera_project_info ---")
        result = client.call_tool("chimera_project_info")
        print(get_tool_text(result))

        client.disconnect()
    else:
        print("Failed to connect to MCP server")
