import json
import socket
import time

s = socket.create_connection(("127.0.0.1", 9879), timeout=10)
s.settimeout(30)
start = time.time()
n = 0
while time.time() - start < 720:
    n += 1
    msg = json.dumps({"command": "get_state"}) + "\n"
    try:
        s.sendall(msg.encode())
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                print(f"[{time.time()-start:6.1f}s] conn closed", flush=True)
                raise SystemExit
            buf += chunk
        if n % 20 == 0:
            print(f"[{time.time()-start:6.1f}s] ok x{n}", flush=True)
    except socket.timeout:
        print(f"[{time.time()-start:6.1f}s] TIMEOUT at call {n} (partial={buf[:80]!r})", flush=True)
        break
    except (ConnectionResetError, BrokenPipeError) as e:
        print(f"[{time.time()-start:6.1f}s] {type(e).__name__} at call {n}", flush=True)
        break
print(f"survived {n} calls over {time.time()-start:.0f}s", flush=True)
