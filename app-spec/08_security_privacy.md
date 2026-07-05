# 08 — Security & Privacy

## Credential Storage
- API keys → flutter_secure_storage (OS-level encryption)
- Server URLs → SharedPreferences (non-sensitive)

## Network Security
- HTTPS enforced for remote connections
- HTTP allowed only for local network (192.168.x.x, 10.x.x.x)
- Certificate pinning for production builds

## Data Privacy
- No analytics, no tracking, no third-party relay
- All data stays between app and user's own server
- No telemetry

## Attack Surface
- Credential interception (mitigated by secure storage)
- MITM on local network (mitigated by HTTPS preference)
- Server impersonation (mitigated by user verification of server URL)
