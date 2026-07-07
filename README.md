# Hermex Android

**Your Hermes Agent. On your phone. Anywhere.**

Chat with your AI agent, manage sessions, run tasks — all from your Android phone. Connects directly to your own Hermes server. No cloud. No third parties. Your data stays yours.

---

## 📲 Download

👉 **[Download Latest APK](https://github.com/jahfaliabdulrahman-dev/hermex_android/releases/latest)**

*(Tap the link on your phone, then open the downloaded file to install. You may need to allow "Install from unknown sources" in your Android settings.)*

---

## 🚀 Setup — Two Options

### Option A: Same WiFi Network (Simplest)

You only need this if your phone and computer are on the same WiFi. Works at home, office, etc.

**Step 1 — Enable server on your computer**

Open a **new Terminal window** (not inside Hermes) and run:

```
hermes config set platforms.api_server.extra.host 0.0.0.0
hermes gateway restart
```

**Step 2 — Find your computer's IP address**

```
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Look for a number like `192.168.8.80` or `192.168.1.5`.

**Step 3 — Find your API key**

```
grep API_SERVER_KEY ~/.hermes/.env
```

Copy everything after the `=` sign. It should look like:
`carsah-local-51578e9b29eddd957aca5a0f71c39fb2`

> ⚠️ The key is ONE continuous string — no spaces or line breaks.

**Step 4 — Open the app and connect**

| Field | What to type |
|-------|-------------|
| Server URL | `http://192.168.x.x:8642` *(use your computer's IP from Step 2)* |
| API Key | Paste the key from Step 3 |

Tap **Connect**. Done!

---

### Option B: Anywhere — Mobile Data + WiFi (Tailscale)

Use this if you want the app to work from **anywhere** — not just when you're on the same WiFi.

**Step 1 — Install Tailscale on your computer**

```
https://tailscale.com/download
```

Download, install, sign in with Google.

**Step 2 — Install Tailscale on your phone**

Get it from the Play Store. Sign in with the **same Google account**.

**Step 3 — Find your computer's Tailscale IP**

On your computer:

```
tailscale status
```

Look for your computer's entry. The IP will start with `100.` — like `100.93.122.47`.

**Step 4 — Find your API key** *(same as Option A)*

```
grep API_SERVER_KEY ~/.hermes/.env
```

**Step 5 — Open the app and connect**

| Field | What to type |
|-------|-------------|
| Server URL | `http://100.x.x.x:8642` *(your Tailscale IP from Step 3)* |
| API Key | Paste the key from Step 4 |

Tap **Connect**. Works on WiFi AND mobile data!

---

## ❓ Common Problems — Quick Fixes

| Problem | Solution |
|---------|----------|
| "Server unreachable" | Make sure Hermes is running. Check your IP is correct. Both devices on same WiFi (or using Tailscale). |
| "HTTP is only allowed on local network" | Update to the latest APK from the download link above. |
| "Invalid API key" | Make sure you copied the FULL key from `.env` file — one continuous string, no spaces. |
| App won't install | Go to Android Settings → Security → Allow "Install from unknown sources". |
| Can't find API key | Run `grep API_SERVER_KEY ~/.hermes/.env` in Terminal. If empty, add: `echo 'API_SERVER_KEY=your-key-here' >> ~/.hermes/.env` then restart Hermes. |
| Server works on WiFi but not mobile data | Use Tailscale (Option B above). WiFi IPs (192.168.x.x) don't work on mobile data. |
| Connected but chat shows error | Make sure you have the latest APK. Old versions had encoding bugs with Arabic text. |

---

## ✨ What You Can Do

| Feature | What it does |
|---------|-------------|
| 💬 **Chat** | Talk to your AI. Markdown, code blocks, model switching. |
| 📋 **Sessions** | Browse past conversations. Search, pin, archive. |
| ⏰ **Tasks** | Manage scheduled jobs. Create, pause, run, view results. |
| 🛠 **Skills** | Browse your agent's skills. Toggle them on/off. |
| 📁 **Workspace** | Browse files on your server. |
| 🧠 **Memory** | View what your agent remembers. |
| ⚙️ **Settings** | Switch servers. Change theme. Disconnect & Exit. |

---

## 🔧 Advanced

**Build from source:**

```
git clone https://github.com/jahfaliabdulrahman-dev/hermex_android.git
cd hermex_android
flutter pub get
flutter build apk --release
```

Requires: Flutter 3.41+, Android 8.0+ (API 26)

**Architecture:** Flutter + Riverpod + GoRouter + Dio + Isar  
**Theme:** Material 3 (navy #001F5E, cyan #32C2FF)  
**License:** MIT — No tracking. No analytics. Your data, your server.

---

Made with ❤️ by the Hermex Swarm — 10 autonomous Flutter AI agents.
