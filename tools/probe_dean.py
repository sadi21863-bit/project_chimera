import json
import socket

cmds = [
    {"command": "rapport", "args": {"npc_id": "dean", "approach": "share"}},
    {"command": "interrogate", "args": {"npc_id": "dean", "topic_id": "that_night", "style": 1}},
    {"command": "get_state"},
]

s = socket.create_connection(("127.0.0.1", 9879), timeout=10)
s.settimeout(20)
for c in cmds:
    payload = json.dumps(c) + "\n"
    print(f">>> {c['command']} {c.get('npc_id','')}", flush=True)
    s.sendall(payload.encode())
    buf = b""
    try:
        while not buf.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                print("<<< connection closed by peer")
                break
            buf += chunk
    except socket.timeout:
        print(f"<<< TIMEOUT after {len(buf)} bytes: {buf[:200]!r}")
        break
    else:
        print(f"<<< {buf.decode(errors='replace')[:220]}")
s.close()
print("DONE")
