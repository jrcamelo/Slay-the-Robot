import fs from "node:fs";
import path from "node:path";
import { createServer, IncomingMessage, ServerResponse } from "node:http";
import {
  applyPresetRequestSchema,
  bootstrapResponseSchema,
  duplicateSessionRequestSchema,
  editorCardDocumentSchema,
  loadSessionRequestSchema,
  saveResultSchema,
  sessionEnvelopeSchema,
  sessionIdRequestSchema,
  sessionUpdateResultSchema,
  updateDocumentRequestSchema,
} from "../shared/schemas.js";
import type { EditorCardDocument } from "../shared/types.js";
import { GodotSidecarClient } from "./sidecar.js";

type CachedSession = {
  sidecarSessionId: string | null;
  document: EditorCardDocument;
};

type SessionEnvelope = {
  sessionId: string;
  document: EditorCardDocument;
};

export class CardEditorWebServer {
  private readonly sessions = new Map<string, CachedSession>();
  private nextPublicSessionId = 1;

  constructor(
    private readonly sidecar: GodotSidecarClient,
    private readonly staticRoot: string,
  ) {
    this.sidecar.onExit(() => {
      for (const session of this.sessions.values()) {
        session.sidecarSessionId = null;
      }
    });
  }

  createHttpServer() {
    return createServer(async (request, response) => {
      try {
        await this.handleRequest(request, response);
      } catch (error) {
        this.sendJson(response, 500, {
          error: error instanceof Error ? error.message : "Unexpected error.",
        });
      }
    });
  }

  private async handleRequest(request: IncomingMessage, response: ServerResponse) {
    const method = request.method ?? "GET";
    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");
    response.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,OPTIONS");

    if (method === "OPTIONS") {
      response.statusCode = 204;
      response.end();
      return;
    }

    if (method === "GET" && url.pathname === "/api/library") {
      const result = await this.sidecar.request<{ entries: unknown[] }>("library.list");
      this.sendJson(response, 200, result);
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/rescan-library") {
      const result = await this.sidecar.request<{ entries: unknown[] }>("session.rescan_library");
      this.sendJson(response, 200, result);
      return;
    }

    if (method === "GET" && url.pathname === "/api/metadata/actions") {
      const result = await this.sidecar.request<{ entries: unknown[] }>("metadata.actions");
      this.sendJson(response, 200, result);
      return;
    }

    if (method === "GET" && url.pathname === "/api/metadata/validators") {
      const result = await this.sidecar.request<{ entries: unknown[] }>("metadata.validators");
      this.sendJson(response, 200, result);
      return;
    }

    if (method === "GET" && url.pathname === "/api/presets") {
      const result = await this.sidecar.request<{ entries: unknown[] }>("presets.list");
      this.sendJson(response, 200, result);
      return;
    }

    if (method === "GET" && url.pathname === "/api/bootstrap") {
      const [library, actions, validators, presets] = await Promise.all([
        this.sidecar.request<{ entries: unknown[] }>("library.list"),
        this.sidecar.request<{ entries: unknown[] }>("metadata.actions"),
        this.sidecar.request<{ entries: unknown[] }>("metadata.validators"),
        this.sidecar.request<{ entries: unknown[] }>("presets.list"),
      ]);
      const payload = bootstrapResponseSchema.parse({
        library: library.entries,
        actions: actions.entries,
        validators: validators.entries,
        presets: presets.entries,
      });
      this.sendJson(response, 200, payload);
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/new") {
      const body = (await this.readJsonBody(request)) as Record<string, unknown>;
      const envelope = await this.sidecar.request<{ sessionId: string; document: unknown }>(
        "session.new",
        { presetId: typeof body.presetId === "string" ? body.presetId : "" },
      );
      this.sendJson(response, 200, this.bindNewSession(envelope));
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/load") {
      const body = loadSessionRequestSchema.parse(await this.readJsonBody(request));
      const envelope = await this.sidecar.request<{ sessionId: string; document: unknown }>(
        "session.load",
        body,
      );
      this.sendJson(response, 200, this.bindNewSession(envelope));
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/duplicate") {
      const body = duplicateSessionRequestSchema.parse(await this.readJsonBody(request));
      const cached = await this.ensureSidecarSession(body.sessionId);
      const envelope = await this.sidecar.request<{ sessionId: string; document: unknown }>(
        "session.duplicate",
        { sessionId: cached.sidecarSessionId },
      );
      this.sendJson(response, 200, this.bindNewSession(envelope));
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/apply-preset") {
      const body = applyPresetRequestSchema.parse(await this.readJsonBody(request));
      const cached = await this.ensureSidecarSession(body.sessionId);
      const envelope = await this.sidecar.request<{ sessionId: string; document: unknown }>(
        "session.apply_preset",
        {
          sessionId: cached.sidecarSessionId,
          presetId: body.presetId,
          preserveIdentity: body.preserveIdentity ?? true,
        },
      );
      const session = sessionEnvelopeSchema.parse({
        sessionId: body.sessionId,
        document: envelope.document,
      });
      cached.document = session.document;
      this.sendJson(response, 200, session);
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/validate") {
      const body = sessionIdRequestSchema.parse(await this.readJsonBody(request));
      const cached = await this.ensureSidecarSession(body.sessionId);
      const result = await this.sidecar.request<unknown>("session.validate", {
        sessionId: cached.sidecarSessionId,
      });
      this.sendJson(response, 200, sessionUpdateResultSchema.parse(result));
      return;
    }

    if (method === "PUT" && url.pathname === "/api/session/document") {
      const body = updateDocumentRequestSchema.parse(await this.readJsonBody(request));
      const cached = await this.ensureSidecarSession(body.sessionId);
      cached.document = editorCardDocumentSchema.parse(body.document);
      const result = await this.sidecar.request<unknown>("session.update_document", {
        sessionId: cached.sidecarSessionId,
        document: cached.document,
      });
      const parsed = sessionUpdateResultSchema.parse(result);
      cached.document = {
        ...cached.document,
        save: parsed.save,
        diagnostics: parsed.diagnostics,
      };
      this.sendJson(response, 200, parsed);
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/save-triage") {
      await this.handleSaveRequest(request, response, "session.save_triage");
      return;
    }

    if (method === "POST" && url.pathname === "/api/session/save-content") {
      await this.handleSaveRequest(request, response, "session.save_content");
      return;
    }

    if (method === "GET" && url.pathname === "/api/health") {
      this.sendJson(response, 200, { ok: true, sessions: this.sessions.size });
      return;
    }

    await this.serveStatic(url.pathname, response);
  }

  private async handleSaveRequest(
    request: IncomingMessage,
    response: ServerResponse,
    method: "session.save_triage" | "session.save_content",
  ) {
    const body = sessionIdRequestSchema.parse(await this.readJsonBody(request));
    const cached = await this.ensureSidecarSession(body.sessionId);
    const result = await this.sidecar.request<unknown>(method, {
      sessionId: cached.sidecarSessionId,
    });
    const parsed = saveResultSchema.parse(result);
    cached.document = parsed.document;
    this.sendJson(response, 200, parsed);
  }

  private bindNewSession(envelope: { sessionId: string; document: unknown }): SessionEnvelope {
    const publicSessionId = `web_session_${this.nextPublicSessionId++}`;
    const session = sessionEnvelopeSchema.parse({
      sessionId: publicSessionId,
      document: envelope.document,
    });
    this.sessions.set(publicSessionId, {
      sidecarSessionId: envelope.sessionId,
      document: session.document,
    });
    return session;
  }

  private async ensureSidecarSession(publicSessionId: string): Promise<CachedSession> {
    const cached = this.sessions.get(publicSessionId);
    if (!cached) {
      throw new Error(`Unknown session: ${publicSessionId}`);
    }

    if (cached.sidecarSessionId) {
      return cached;
    }

    const newSession = await this.sidecar.request<{ sessionId: string; document: unknown }>(
      "session.new",
      {},
    );
    cached.sidecarSessionId = newSession.sessionId;
    await this.sidecar.request("session.update_document", {
      sessionId: cached.sidecarSessionId,
      document: cached.document,
    });
    return cached;
  }

  private async serveStatic(pathname: string, response: ServerResponse) {
    const normalizedPath = pathname === "/" ? "/index.html" : pathname;
    const targetPath = path.join(this.staticRoot, normalizedPath);
    if (fs.existsSync(targetPath) && fs.statSync(targetPath).isFile()) {
      const contentType = targetPath.endsWith(".js")
        ? "text/javascript"
        : targetPath.endsWith(".css")
          ? "text/css"
          : targetPath.endsWith(".html")
            ? "text/html"
            : "application/octet-stream";
      response.writeHead(200, { "Content-Type": contentType });
      fs.createReadStream(targetPath).pipe(response);
      return;
    }

    const fallback = path.join(this.staticRoot, "index.html");
    if (fs.existsSync(fallback)) {
      response.writeHead(200, { "Content-Type": "text/html" });
      fs.createReadStream(fallback).pipe(response);
      return;
    }

    this.sendJson(response, 404, { error: "Not found." });
  }

  private async readJsonBody(request: IncomingMessage) {
    const chunks: Buffer[] = [];
    for await (const chunk of request) {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    const body = Buffer.concat(chunks).toString("utf8");
    return body === "" ? {} : JSON.parse(body);
  }

  private sendJson(response: ServerResponse, statusCode: number, payload: unknown) {
    response.writeHead(statusCode, { "Content-Type": "application/json" });
    response.end(JSON.stringify(payload));
  }
}
