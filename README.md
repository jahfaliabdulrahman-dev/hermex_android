# Hermex Android

[![Tests](https://img.shields.io/badge/tests-529%2F529-brightgreen)](https://github.com/jahfaliabdulrahman-dev/hermex_android/actions)
[![Flutter](https://img.shields.io/badge/flutter-3.41%2B-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-purple)](LICENSE)

**Your Hermes Agent. On your phone. Anywhere.**

Chat with your AI agent, manage sessions, run tasks, browse workspaces — all from your Android phone. Connects directly to your own [Hermes Agent](https://hermes-agent.nousresearch.com) server. No cloud. No third parties. Your data stays yours.

---

## 📲 Download

👉 **[Download Latest APK](https://github.com/jahfaliabdulrahman-dev/hermex_android/releases/latest)**

> **Two builds available:**
> - `app-release.apk` (65 MB) — optimized, no debug overhead
> - `app-debug.apk` (178 MB) — includes debug symbols for troubleshooting

Tap the link on your phone, open the downloaded file to install. You may need to allow "Install from unknown sources" in Android Settings → Security.

---

## 🚀 Quick Start

### Option A: Same WiFi (Home / Office)

**1. Enable the API server on your computer:**
```bash
hermes config set platforms.api_server.extra.host 0.0.0.0
hermes gateway restart
```

**2. Find your computer's IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
→ You'll see something like `192.168.8.80` or `192.168.1.5`.

**3. Find your API key:**
```bash
grep API_SERVER_KEY ~/.hermes/.env
```

**4. Open the app and connect:**

| Field | Value |
|-------|-------|
| Server URL | `http://<YOUR_IP>:8642` |
| API Key | Paste the key from step 3 |

---

### Option B: Anywhere — WiFi + Mobile Data (Tailscale)

Works from anywhere, not just your home network.

1. Install [Tailscale](https://tailscale.com/download) on both your computer and phone
2. Sign in with the same Google account on both
3. On your computer: `tailscale status` → find your `100.x.x.x` IP
4. Use `http://<TAILSCALE_IP>:8642` as your server URL in the app

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 💬 **Chat** | Real-time AI conversation with Markdown rendering, code blocks, streaming |
| 🔄 **Model Switching** | Switch between AI models mid-conversation |
| 📋 **Sessions** | Browse, search, pin, and archive past conversations |
| ⏰ **Tasks** | Manage scheduled cron jobs — create, pause, run, view results |
| 🛠 **Skills** | Browse and toggle your agent's skill library |
| 📁 **Workspace** | Browse files on your Hermes server |
| 🧠 **Memory** | View what your agent remembers across sessions |
| ⚙️ **Settings** | Multiple server profiles, theme switching, disconnect |

---

## 🔧 Build from Source

```bash
git clone https://github.com/jahfaliabdulrahman-dev/hermex_android.git
cd hermex_android
flutter pub get
flutter test          # 529+ tests
flutter build apk --release
```

**Requirements:**
- Flutter 3.41+
- Android 8.0+ (API 26)
- A running [Hermes Agent](https://hermes-agent.nousresearch.com) server with `API_SERVER_ENABLED=true`

---

## 🏗 Architecture

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.41 |
| **State** | Riverpod (code generation) |
| **Routing** | GoRouter (ShellRoute + deep linking) |
| **HTTP** | Dio (REST) + `dart:io` HttpClient (SSE streaming) |
| **Storage** | Isar (local NoSQL) |
| **Theme** | Material 3 (navy `#001F5E`, cyan `#32C2FF`) |
| **Architecture** | Clean Architecture (core → features → models) |

Full specifications in [`app-spec/`](app-spec/) — 22 spec files covering architecture, routing, state management, and testing.

---

## 🧪 Testing

```bash
flutter test          # 529+ unit/widget tests
flutter analyze       # static analysis
flutter test --coverage
```

Test coverage includes: providers, repositories, models, API interceptors, SSE parsing, URL validation, and error classification.

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| "Server unreachable" | Check Hermes is running. Verify IP is correct. Both devices on same network (or Tailscale). |
| "HTTP only allowed on local network" | Update to the latest APK. The app validates private IP ranges (RFC 1918 + Tailscale 100.64.0.0/10). |
| "Invalid API key" | Copy the FULL key — one continuous string, no spaces. Run `grep API_SERVER_KEY ~/.hermes/.env`. |
| App won't install | Settings → Security → Allow "Install from unknown sources". |
| Works on WiFi but not mobile data | WiFi IPs (192.168.x.x) don't work on mobile data. Use Tailscale (Option B). |
| Arabic text or special characters fail | Ensure you're on the latest build. Older versions had `dart:io` UTF-8 encoding bugs. |

---

## 🤖 Built by the Hermex Swarm

This app was built by a **10-agent autonomous Flutter swarm** — AI agents collaborating via Kanban under a governance constitution. The Lead Architect (DeepSeek-v4-pro + Qwen3.7-Max + GLM-5.2) orchestrates 9 specialized engineers through a self-correcting pipeline.

See [`app-spec/`](app-spec/) for the complete development log, lessons learned, and traceability matrix.

---

## 📄 License

MIT — No tracking. No analytics. No telemetry. Your data, your server, your rules.
