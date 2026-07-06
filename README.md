# Hermex Android

**Your Hermes Agent. On your phone. No middleman.**

Hermex connects your Android device directly to your self-hosted Hermes Agent API Server over WiFi — no cloud, no third-party servers. Chat, manage sessions, run cron jobs, browse skills, and more.

---

## 📲 Quick Start

### 1. Download the APK

👉 **[Download Latest APK](https://github.com/jahfaliabdulrahman-dev/hermex_android/releases/latest)**

### 2. Enable Your Hermes API Server

Add to your Hermes config:

```yaml
api_server:
  enabled: true
  extra:
    port: 8642
    host: 0.0.0.0  # Required for phone WiFi access
```

Restart: `hermes restart`

### 3. Find Your Computer's IP

```bash
ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'
```

### 4. Connect

In the app, enter:

| Field | Value |
|-------|-------|
| Server URL | `http://YOUR_COMPUTER_IP:8642` |
| API Key | Your Hermes API key |

---

## 🔧 Troubleshooting

| Symptom | Solution |
|---------|----------|
| "Server not reachable" | Add `host: 0.0.0.0` to API server config and restart |
| "Invalid API key" | Check your key in Hermes config |
| Phone can't find server | Both devices must be on the same WiFi network |
| App won't install | Enable "Install from unknown sources" on your Android |

---

## ✨ Features

- **Chat** — Real-time SSE streaming with markdown and model selection
- **Sessions** — Browse, search, create, archive, pin conversations
- **Tasks** — Manage cron jobs: create, pause, resume, view output
- **Skills** — Browse and toggle installed agent skills
- **Workspace** — Browse server file system
- **Memory & Insights** — View agent memory and usage stats
- **Settings** — Server profiles, dark/light theme, model switching

---

## 🏗️ Build From Source

```bash
git clone https://github.com/jahfaliabdulrahman-dev/hermex_android.git
cd hermex_android
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

API target: Android 8.0+ (API 26) | Flutter 3.41+

---

## 🛡️ Android Build Gates

Before every build, our CI runs `scripts/android-preflight.sh`:

| Gate | Check |
|------|-------|
| 1 | `namespace` == `MainActivity.kt` package |
| 2 | Isar + ProGuard compatible |
| 3 | `applicationId` consistent |
| 4 | AGP 8.8+ compat hooks present |

All gates must pass before APK is built.

---

## 📐 Architecture

```
Phone (Hermex) --WiFi--> Computer (Hermes API Server :8642)
```

| Concern | Technology |
|---------|-----------|
| Framework | Flutter (Dart) |
| State | Riverpod |
| Routing | GoRouter |
| Network | Dio (REST) + HttpClient (SSE) |
| Storage | Isar + SecureStorage + SharedPreferences |
| Theme | Material 3 dark (navy #001F5E, cyan #32C2FF) |

---

## 📚 Documentation

- **User Guide:** Load skill `/flutter/hermex-android-app`
- **Spec Pack:** `app-spec/` directory (22+ files)
- **Lessons Learned:** `app-spec/00_lessons_learned.md`
- **Android Build:** `app-spec/10_devops_release_observability.md`

---

## 🤖 Development Swarm

Built by 9 autonomous Flutter profiles via Kanban orchestration:
Lead Architect · Product Steward · UI/UX Designer · Backend/DB Architect · State Engineer · QA Tester · Zero-Trust Auditor · DevOps Engineer · Documentation Steward

**Model:** Triple Chinese MoA (DeepSeek V4 Pro + Qwen 3.7 Max + GLM 5.2)

---

## 📄 License

MIT — Free and open source. No analytics, no tracking. All data stays between your phone and your own server.
