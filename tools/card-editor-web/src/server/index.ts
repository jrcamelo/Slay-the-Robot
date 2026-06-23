import path from "node:path";
import { CardEditorWebServer } from "./server.js";
import { GodotSidecarClient, resolveProjectRoot } from "./sidecar.js";

const projectRoot = resolveProjectRoot();
const sidecar = new GodotSidecarClient(projectRoot);
const staticRoot = path.resolve(process.cwd(), "dist", "web");
const server = new CardEditorWebServer(sidecar, staticRoot);
const httpServer = server.createHttpServer();
const port = Number(process.env.PORT ?? 4173);

httpServer.listen(port, "127.0.0.1", () => {
  console.log(`Card editor server listening on http://127.0.0.1:${port}`);
});
