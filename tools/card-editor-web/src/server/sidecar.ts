import { ChildProcessWithoutNullStreams, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

type PendingRequest = {
  resolve: (value: any) => void;
  reject: (reason?: unknown) => void;
};

type SidecarRpcResponse = {
  id: number | string | null;
  result?: unknown;
  error?: { message?: string };
};

// Godot child output is mirrored into the dev server log for local debugging.

export class GodotSidecarClient {
  private child: ChildProcessWithoutNullStreams | null = null;
  private nextRequestId = 1;
  private readonly pending = new Map<number, PendingRequest>();
  private readonly exitListeners = new Set<() => void>();

  constructor(private readonly projectRoot: string) {}

  onExit(listener: () => void) {
    this.exitListeners.add(listener);
    return () => this.exitListeners.delete(listener);
  }

  async request<T>(method: string, params: Record<string, unknown> = {}): Promise<T> {
    await this.ensureStarted();
    if (!this.child) {
      throw new Error("Godot sidecar is not running.");
    }

    const id = this.nextRequestId++;
    const payload = JSON.stringify({ id, method, params });

    return await new Promise<T>((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.child!.stdin.write(`${payload}\n`, (error) => {
        if (error) {
          this.pending.delete(id);
          reject(error);
        }
      });
    });
  }

  async restart() {
    this.disposeChild();
    await this.ensureStarted();
  }

  private async ensureStarted() {
    if (this.child && !this.child.killed) {
      return;
    }

    const godotBin = this.resolveGodotBinary();

    const child = spawn(
      godotBin,
      [
        "--headless",
        "--path",
        this.projectRoot,
        "--",
        "--card-editor-sidecar",
      ],
      {
        cwd: this.projectRoot,
        stdio: "pipe",
      },
    );

    this.child = child;
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    child.stdout.on("data", (chunk: string) => {
      for (const line of chunk.split(/\r?\n/)) {
        const trimmed = line.trim();
        if (!trimmed) {
          continue;
        }
        if (!trimmed.startsWith("{")) {
          console.log(`[godot] ${trimmed}`);
          continue;
        }
        try {
          const parsed = JSON.parse(trimmed) as SidecarRpcResponse;
          if (typeof parsed.id !== "number") {
            console.log(`[godot] ${trimmed}`);
            continue;
          }
          const pending = this.pending.get(parsed.id);
          if (!pending) {
            continue;
          }
          this.pending.delete(parsed.id);
          if (parsed.error?.message) {
            pending.reject(new Error(parsed.error.message));
          } else {
            pending.resolve(parsed.result);
          }
        } catch {
          continue;
        }
      }
    });

    child.stderr.on("data", (chunk: string) => {
      for (const line of chunk.split(/\r?\n/)) {
        const trimmed = line.trim();
        if (!trimmed) {
          continue;
        }
        console.error(`[godot:stderr] ${trimmed}`);
      }
    });

    child.on("exit", () => {
      this.disposeChild(new Error("Godot sidecar exited."));
    });

    await this.request("ping");
  }

  private resolveGodotBinary() {
    const candidates = [
      process.env.GODOT_BIN,
      path.resolve(this.projectRoot, "..", "..", "Godot_v4.6.2-stable_win64_console.exe"),
      path.resolve(this.projectRoot, "..", "..", "Godot_v4.4-stable_win64_console.exe"),
    ].filter((candidate): candidate is string => Boolean(candidate));

    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }

    throw new Error(
      "No Godot console binary found. Set GODOT_BIN or place Godot_v4.6.2-stable_win64_console.exe under F:/Godot.",
    );
  }

  private disposeChild(exitError?: Error) {
    if (this.child && !this.child.killed) {
      this.child.kill();
    }
    this.child = null;
    for (const pending of this.pending.values()) {
      pending.reject(exitError ?? new Error("Godot sidecar stopped."));
    }
    this.pending.clear();
    for (const listener of this.exitListeners) {
      listener();
    }
  }
}

export function resolveProjectRoot() {
  return path.resolve(process.cwd(), "..", "..");
}
