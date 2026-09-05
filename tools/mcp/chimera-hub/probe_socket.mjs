import { Socket } from "net";

function sendCommand(command, args = {}, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const socket = new Socket();
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error("timeout"));
    }, timeoutMs);
    let buffer = "";
    socket.connect(9879, "127.0.0.1", () => {
      socket.write(JSON.stringify({ command, args }) + "\n");
    });
    socket.on("data", (data) => {
      buffer += data.toString();
      if (buffer.includes("\n")) {
        clearTimeout(timer);
        socket.destroy();
        try {
          const lines = buffer.split("\n").filter((l) => l.trim());
          resolve(JSON.parse(lines[lines.length - 1]));
        } catch (e) {
          reject(new Error("bad json"));
        }
      }
    });
    socket.on("error", (err) => {
      clearTimeout(timer);
      reject(new Error(err.message));
    });
  });
}

const t0 = Date.now();
for (let i = 0; i < 5; i++) {
  const s = Date.now();
  try {
    const r = await sendCommand(i === 2 ? "interrogate" : "get_state", i === 2 ? { npc_id: "dean", topic_id: "that_night", style: 1 } : {});
    console.log(`call ${i}: ${Date.now() - s}ms ok keys=${Object.keys(r).join(",")}`);
  } catch (e) {
    console.log(`call ${i}: ${Date.now() - s}ms ERR ${e.message}`);
  }
}
console.log(`total ${Date.now() - t0}ms`);
