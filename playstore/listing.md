# Play Store Listing — Hermex Android

## App Name
**Hermex** — Your AI Agent on Android

## Short Description (max 80 chars)
Chat with your Hermes AI agent from anywhere. Connect to your own server.

## Full Description (max 4000 chars)

**Your Hermes Agent. On your phone. Anywhere.**

Hermex lets you chat with your personal AI agent, manage sessions, run scheduled tasks, and browse your server's workspace — all from your Android phone. It connects directly to your own Hermes Agent server. No cloud. No third parties. Your data stays yours.

### ✨ Features

- **💬 Real-time Chat** — Talk to your AI with full Markdown rendering, code blocks with syntax highlighting, and streaming responses
- **🔄 Model Switching** — Switch between AI models mid-conversation. Supports reasoning effort control (minimal to max)
- **📋 Session Management** — Browse, search, pin, and archive all your past conversations. Server-side search with cursor-based pagination
- **⏰ Task Manager** — Create, pause, resume, and monitor scheduled jobs (cron, memory, workspace, skills)
- **🛠 Skills Browser** — Browse your agent's skill library and toggle individual skills on/off
- **📁 Workspace Explorer** — Browse files and directories on your Hermes server
- **🧠 Memory Viewer** — See what your agent remembers across conversations
- **⚙️ Multi-Server Support** — Save multiple server profiles (home, work, cloud) with per-server model and reasoning preferences

### 🔒 Privacy First

Hermex collects **zero** data. No analytics, no tracking, no telemetry. It connects directly to YOUR server — we never see your messages, your API keys, or your data. All credentials are stored in Android Keystore (hardware-backed encryption).

### 🚀 Quick Setup

1. Download and install Hermex
2. Enable the API server on your Hermes Agent: `hermes config set platforms.api_server.extra.host 0.0.0.0`
3. Find your computer's IP and API key
4. Enter them in the app — done!

Works on WiFi. Works anywhere with Tailscale.

### 📋 Requirements

- An Android device running Android 8.0 (Oreo) or newer
- A running [Hermes Agent](https://hermes-agent.nousresearch.com) server with API enabled

### 🛠 Open Source

Hermex is open source (MIT). Built by a 10-agent autonomous Flutter swarm. 529+ tests. Zero tracking.

**Source:** https://github.com/jahfaliabdulrahman-dev/hermex_android

---

## Arabic Description (وصف بالعربية)

**وكيل Hermes الذكي. في جوالك. في أي مكان.**

تطبيق Hermex يتيح لك التحدث مع وكيلك الذكي، إدارة الجلسات، تشغيل المهام المجدولة، وتصفح ملفات الخادم — كل هذا من جوالك الأندرويد. يتصل مباشرة بخادم Hermes Agent الخاص بك. بدون سحابة. بدون أطراف ثالثة. بياناتك تبقى لك.

### ✨ الميزات

- **💬 المحادثة المباشرة** — تحدث مع وكيلك الذكي مع دعم Markdown وعرض الأكواد البرمجية والبث المباشر
- **🔄 تبديل النماذج** — تنقل بين نماذج الذكاء الاصطناعي أثناء المحادثة
- **📋 الجلسات** — تصفح وابحث وثبّت وأرشِف جميع محادثاتك السابقة
- **⏰ المهام** — أنشئ وأوقف واستأنف المهام المجدولة
- **🛠 المهارات** — تصفح مهارات وكيلك وفعّلها أو عطّلها
- **📁 مساحة العمل** — تصفح ملفات الخادم
- **🧠 الذاكرة** — شاهد ما يتذكره وكيلك
- **⚙️ السيرفرات المتعددة** — احفظ إعدادات عدة سيرفرات مع تفضيلات لكل منها

### 🔒 الخصوصية أولاً

Hermex لا يجمع أي بيانات. لا تحليلات، لا تتبع، لا قياس عن بعد. يتصل مباشرة بخادمك — لا نرى رسائلك ولا مفاتيحك ولا بياناتك أبداً.

### 🚀 الإعداد السريع

1. حمّل ونصّب Hermex
2. فعّل خادم API في Hermes Agent
3. أدخل عنوان IP ومفتاح API
4. خلاص — أنت جاهز!

يعمل على الواي فاي. ويعمل في أي مكان مع Tailscale.

---

## Categories
- **Primary:** Tools
- **Secondary:** Productivity

## Target Audience
18+, users who run their own AI agent servers

## Content Rating
To be completed in Google Play Console questionnaire. Expected: **Everyone** (no objectionable content)

---

## Required Assets Checklist

| Asset | Size | Status |
|-------|------|--------|
| App icon | 512×512 PNG | ✅ Have mipmap icons (need to generate 512px version) |
| Feature graphic | 1024×500 PNG | ❌ Need to create |
| Phone screenshots | Min 2, JPEG/PNG 16:9 or 9:16 | ❌ Need to capture from device |
| AAB signed | N/A | ✅ `build/app/outputs/bundle/release/app-release.aab` (53MB) |
| Privacy policy URL | N/A | ✅ Need to host somewhere (GitHub Pages or repo raw URL) |

---

## How to Host Privacy Policy

Option A (quickest): Use the raw GitHub URL:
```
https://raw.githubusercontent.com/jahfaliabdulrahman-dev/hermex_android/main/playstore/privacy-policy.md
```
But Play Store requires HTML, not Markdown.

Option B (recommended): Create a simple HTML version and host via GitHub Pages:
1. Create `docs/index.html` with the privacy policy content
2. Enable GitHub Pages in repo Settings → Pages → Source: `main` branch, `/docs` folder
3. URL will be: `https://jahfaliabdulrahman-dev.github.io/hermex_android/`

---

## Submission Checklist

- [ ] Google Play Developer account created ($25 one-time fee)
- [ ] App signed with release keystore
- [ ] AAB uploaded to Play Console
- [ ] Store listing filled (descriptions above)
- [ ] Privacy policy URL provided
- [ ] Screenshots uploaded (min 2 phone screenshots)
- [ ] App icon (512×512) uploaded
- [ ] Feature graphic (1024×500) uploaded
- [ ] Content rating questionnaire completed
- [ ] Data safety section completed
- [ ] App category selected (Tools)
- [ ] Pricing: Free
- [ ] Countries: All countries available
