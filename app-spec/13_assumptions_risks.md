# 13 — Assumptions & Risks

## Assumptions
1. Hermes Agent API Server is running and accessible from phone
2. User has API_SERVER_KEY configured
3. Network connection between phone and server is stable
4. SSE streaming works on mobile networks

## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| API breaking changes | High | Low | /v1/capabilities detection, version pinning |
| SSE unreliable on mobile | Medium | Medium | Fallback to polling, reconnection logic |
| Flutter SSE library immature | Medium | High | Custom HttpClient implementation |
| Server not reachable | High | Medium | Clear error messages, connection testing |
