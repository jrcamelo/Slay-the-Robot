# Card Editor Web

React + TypeScript frontend with a local Node backend and a headless Godot sidecar.

## Requirements

- Node.js 20+
- Godot 4.4 console executable

## Environment

Set `GODOT_BIN` to your local Godot 4.4 executable.

Example on Windows PowerShell:

```powershell
$env:GODOT_BIN = "C:\Path\To\Godot_v4.4-stable_win64_console.exe"
```

## Install

```powershell
npm install
```

## Development

Run the API server:

```powershell
npm run dev:server
```

Run the frontend dev server in a second terminal:

```powershell
npm run dev:web
```

Frontend:

- [http://127.0.0.1:4174](http://127.0.0.1:4174)

Backend:

- [http://127.0.0.1:4173](http://127.0.0.1:4173)

## Production Build

```powershell
npm run build
npm start
```

## Notes

- The browser never reads or writes `.tres` directly.
- The Godot sidecar is the authoritative card parser, validator, migrator, and saver.
- If the sidecar restarts, the Node backend keeps the last browser document and rehydrates the session.
