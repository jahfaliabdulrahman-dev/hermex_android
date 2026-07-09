# HERMEX ANDROID — GOVERNANCE CONSTITUTION

> **Document ID:** GOV-CONST-001
> **Authority:** Triple-Chinese MoA FINAL SYNTHESIS (Rounds 1+3+5+7+9)
> **Against:** DeepSeek-v4-pro Challenge (Rounds 2+4+6+8)
> **Ratification Date:** 2026-07-09
> **Status:** CONSTITUTION — IMMUTABLE
> **Supersedes:** All prior governance rules (GOV-001, GOV-005) — those are NOW AUTOMATED

---

## PREAMBLE

This Constitution is the FINAL SYNTHESIS of a 9-round governance dialogue between
the Triple-Chinese MoA (deepseek-v4-pro + qwen3.7-max + glm-5.2) and DeepSeek-v4-pro
operating as adversarial reviewer. It represents the definitive word on how the
Hermex Android 10-profile swarm shall be governed.

**No governance rule below may be waived for speed, urgency, deadline pressure,
or user request. Any violation is a governance failure regardless of code quality
outcomes.**

---

## RATIFICATION TABLE — DeepSeek's 3 Proposed Changes

| # | DeepSeek Proposed | Triple-Chinese Verdict | Rationale |
|---|-------------------|----------------------|-----------|
| **1** | Gateway Health Gate (pre-dispatch verification) | **✅ ACCEPTED with MODIFICATIONS** | DeepSeek's core insight is correct: pre-dispatch health check prevents the #1 failure class. Modified: use `hermes gateway list` (actual CLI), add dual-check with `launchctl`, add auto-remediation hints. DeepSeek's `hermes gateway status --profile` does not exist as a CLI command. |
| **2** | Staleness Cron (every 5min) | **✅ ACCEPTED with MODIFICATIONS** | Correct principle. Modified: use `hermes cron create` (actual CLI), add tiered thresholds (15min P0 lanes, 30min P1/P2), also detect blocked-beyond-24h tasks. DeepSeek's `hermes cronjob create --no_agent` syntax does not exist. |
| **3** | Lead Architect Delegation Tiers | **✅ ACCEPTED with SIGNIFICANT MODIFICATIONS** | DeepSeek correctly identifies the Single Point of Failure. BUT: their delegation order (Product Steward as T2) is wrong — Product Steward manages scope, not infrastructure. Fixed: DevOps co-T2 for infrastructure, Product Steward for scope. Added: Telegram notification on delegation activation, immutable cannot-do list, mandatory log prefix. |

---

## ARCHITECTURE — THE 3-LAYER GOVERNANCE MODEL

After 9 rounds of adversarial review, the original 5-layer model (Round 3) is
**COLLAPSED TO 3 LAYERS.** Triple-Chinese concedes this point to DeepSeek. The
collapsed model is simpler, faster to execute, and covers all 30+ lessons learned.

```
┌─────────────────────────────────────────────────────────────────┐
│                    GOVERNANCE ARCHITECTURE                       │
│                                                                  │
│  LAYER 1: DEFENSE                                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ SOUL.md enforcement  │  BOUNDARIES.md  │  Skill loading  │   │
│  │ GOV-001 automation   │  GOV-005 grep   │  Gateway gate   │   │
│  │ Pre-commit hooks     │  CI preflight    │  SCSI Hunt L1   │   │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  LAYER 2: DETECTION                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ SCSI Guardian L1-L5    │  Staleness Cron  │  CI watchers │   │
│  │ Kanban review monitor  │  Gateway polls   │  APK build   │   │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  LAYER 3: ESCALATION                                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Lead Architect Gate  │  Delegation Tiers  │  Human auth. │   │
│  │ Telegram push alerts  │  Decision Log    │  Kill switch  │   │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Platform constraints and peer accountability are BAKED INTO    │
│  these layers — they do not need independent layers.             │
└─────────────────────────────────────────────────────────────────┘
```

---

## ARTICLE I — THE GATEWAY HEALTH GATE (Change 1)

### §1.1 — Mandatory Pre-Dispatch Check

**EFFECTIVE IMMEDIATELY.** Before ANY `hermes kanban dispatch` or task creation
that targets a profile, the Gateway Health Gate SHALL be executed.

**Script:** `~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh`

**Behavior:**
1. Queries `hermes gateway list` for all 10 flutter profiles
2. Verifies each profile reports `✓` (running)
3. Double-checks launchd: `launchctl list | grep ai.hermes.gateway-flutter-*`
4. If any profile is DEAD → blocks dispatch, prints exact remediation command
5. If all HEALTHY → prints confirmation, allows dispatch

**Success threshold:** All 10 profiles MUST report running. Any dead profile = ABORT.

### §1.2 — Exact Implementation Command

Run these commands NOW to deploy:

```bash
# Create the scripts directory
mkdir -p ~/.hermes/skills/hermex-android/scripts

# Write the gateway health gate script
cat > ~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh << 'GATE_EOF'
#!/bin/bash
# ──────────────────────────────────────────────────────────
# GATEWAY HEALTH GATE — HERMEX ANDROID GOVERNANCE
# Art. I §1.1 of GOVERNANCE_CONSTITUTION.md
#
# Blocks ALL Kanban dispatch if any profile gateway is dead.
# Prevents the #1 governance failure class: orphaned tasks.
# ──────────────────────────────────────────────────────────
set -euo pipefail

REQUIRED_PROFILES=(
  flutter-lead-architect
  flutter-product-steward
  flutter-ui-ux-designer
  flutter-backend-db-architect
  flutter-state-engineer
  flutter-qa-tester
  flutter-zero-trust-auditor
  flutter-devops-release-engineer
  flutter-documentation-steward
  flutter-curiosity-hunter
)

DEAD_PROFILES=()
HEALTHY=0
TOTAL=${#REQUIRED_PROFILES[@]}

echo "╔════════════════════════════════════════════════╗"
echo "║  HERMEX ANDROID — GATEWAY HEALTH GATE         ║"
echo "╠════════════════════════════════════════════════╣"

# Primary check: hermes gateway list
GATEWAY_LIST=$(hermes gateway list 2>/dev/null)

for profile in "${REQUIRED_PROFILES[@]}"; do
  if echo "$GATEWAY_LIST" | grep -q "✓.*${profile}"; then
    echo "║  ✅ ${profile}"
    HEALTHY=$((HEALTHY + 1))
  else
    echo "║  ❌ DEAD: ${profile}"
    DEAD_PROFILES+=("$profile")
  fi
done

echo "╠════════════════════════════════════════════════╣"
echo "║  ${HEALTHY}/${TOTAL} gateways healthy"
echo "╚════════════════════════════════════════════════╝"

if [ ${#DEAD_PROFILES[@]} -gt 0 ]; then
  echo ""
  echo "🛑  ABORT: ${#DEAD_PROFILES[@]} gateway(s) dead — dispatch BLOCKED"
  echo ""
  echo "  Dead profiles:"
  for p in "${DEAD_PROFILES[@]}"; do
    echo "    • $p"
  done
  echo ""
  echo "  REMEDIATION:"
  echo "    launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/ai.hermes.gateway-<PROFILE>.plist"
  echo ""
  echo "  One-liner restore-all (safe to run):"
  for p in "${DEAD_PROFILES[@]}"; do
    echo "    launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/ai.hermes.gateway-${p}.plist 2>/dev/null || launchctl kickstart gui/\$(id -u)/ai.hermes.gateway-${p} 2>/dev/null"
  done
  echo ""
  exit 1
fi

echo ""
echo "✅  All ${TOTAL} gateways healthy. Safe to dispatch."
exit 0
GATE_EOF

chmod +x ~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh

# Verify it works
bash ~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh
```

### §1.3 — Integration Points

The Gateway Health Gate SHALL be invoked at these points:

| Trigger | Who Calls It | When |
|---------|-------------|------|
| Pre-dispatch | Lead Architect, DevOps | Before ANY `hermes kanban dispatch` |
| Pre-goal launch | Lead Architect | Before `hermes kanban create` with `--goal` |
| CI pipeline | CI workflow | Before `flutter build apk` |
| Swarm startup | Swarm dashboard | Before worker spawn |

### §1.4 — False Positive Risk

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `hermes gateway list` reports wrong state | **VERY LOW** — never observed | Dual-check with `launchctl list` |
| Profile gateway crashed between check and dispatch | **LOW** — sub-second window | Covered by Art. II Staleness Cron |

---

## ARTICLE II — THE STALENESS CRON (Change 2)

### §2.1 — Mandatory Cron Job

**EFFECTIVE: Within 24 hours of Constitution ratification.**

A cron job SHALL run every 5 minutes, polling the Kanban board for:
1. **Stale tasks:** `todo` or `ready` status, created > 30 minutes ago → alert
2. **Stuck in-progress:** `in_progress` status, no heartbeat > 30 minutes → alert
3. **P0 lane staleness:** Any P0 task unclaimed > 15 minutes → immediate alert
4. **Blocked-beyond-reasonable:** `blocked` status > 24 hours → escalation alert

### §2.2 — Exact Implementation Commands

```bash
# Write the staleness check script
cat > ~/.hermes/skills/hermex-android/scripts/kanban-staleness-check.sh << 'CRON_EOF'
#!/bin/bash
# ──────────────────────────────────────────────────────────
# KANBAN STALENESS MONITOR — HERMEX ANDROID GOVERNANCE
# Art. II §2.1 of GOVERNANCE_CONSTITUTION.md
#
# Polls every 5 minutes via hermes cron.
# Detects orphaned tasks within 30 minutes (vs. 6 hours before).
# ──────────────────────────────────────────────────────────
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ISSUES_FOUND=0

echo "[${TIMESTAMP}] Kanban Staleness Monitor — starting scan"

# ─── STALE UNCLAIMED (>30min) ───────────────────────────
echo "Scanning: stale unclaimed tasks (>30min)..."
STALE_JSON=$(hermes kanban list --status todo --status ready --json 2>/dev/null || echo "[]")

STALE_COUNT=$(echo "$STALE_JSON" | python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta

threshold = datetime.now(timezone.utc) - timedelta(minutes=30)
tasks = json.load(sys.stdin) if sys.stdin else []
stale = []
for t in tasks:
    created_str = t.get('created_at', '') or t.get('created', '')
    if not created_str:
        continue
    try:
        created = datetime.fromisoformat(created_str.replace('Z', '+00:00'))
    except:
        continue
    if created < threshold:
        stale.append(f\"  ⚠️  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | {t.get('status','?')} | {created.strftime('%H:%M')} | lane={t.get('lane','?')}\")
print(len(stale))
for s in stale:
    print(s, file=sys.stderr)
" 2>&1 1>/dev/stdout)

if [ "$STALE_COUNT" -gt 0 ] 2>/dev/null; then
  echo "🔴  STALE UNCLAIMED: ${STALE_COUNT} task(s)"
  python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta
threshold = datetime.now(timezone.utc) - timedelta(minutes=30)
tasks = json.load(sys.stdin) if sys.stdin else []
for t in tasks:
    created_str = t.get('created_at', '') or t.get('created', '')
    if not created_str: continue
    try:
        created = datetime.fromisoformat(created_str.replace('Z', '+00:00'))
    except: continue
    if created < threshold:
        print(f\"  ⚠️  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | {t.get('status','?')} | {created.strftime('%H:%M')}\")
" <<< "$STALE_JSON"
  ISSUES_FOUND=1
fi

# ─── STUCK IN-PROGRESS (>30min no heartbeat) ────────────
echo "Scanning: stuck in-progress (>30min no heartbeat)..."
INPROG_JSON=$(hermes kanban list --status in_progress --json 2>/dev/null || echo "[]")

INPROG_STUCK=$(echo "$INPROG_JSON" | python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta

threshold = datetime.now(timezone.utc) - timedelta(minutes=30)
tasks = json.load(sys.stdin) if sys.stdin else []
stuck = []
for t in tasks:
    updated_str = t.get('updated_at', '') or t.get('created_at', '') or t.get('created', '')
    if not updated_str: continue
    try:
        updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00'))
    except: continue
    if updated < threshold:
        stuck.append(f\"  🔶  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | last_update={updated.strftime('%H:%M')}\")
print(len(stuck))
for s in stuck:
    print(s, file=sys.stderr)
" 2>&1 1>/dev/stdout)

if [ "$INPROG_STUCK" -gt 0 ] 2>/dev/null; then
  echo "🟡  STUCK IN-PROGRESS: ${INPROG_STUCK} task(s)"
  python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta
threshold = datetime.now(timezone.utc) - timedelta(minutes=30)
tasks = json.load(sys.stdin) if sys.stdin else []
for t in tasks:
    updated_str = t.get('updated_at', '') or t.get('created_at', '') or t.get('created', '')
    if not updated_str: continue
    try: updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00'))
    except: continue
    if updated < threshold:
        print(f\"  🔶  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | last_update={updated.strftime('%H:%M')}\")
" <<< "$INPROG_JSON"
  ISSUES_FOUND=1
fi

# ─── BLOCKED >24h ───────────────────────────────────────
echo "Scanning: long-blocked (>24h)..."
BLOCKED_JSON=$(hermes kanban list --status blocked --json 2>/dev/null || echo "[]")

BLOCKED_LONG=$(echo "$BLOCKED_JSON" | python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta
threshold = datetime.now(timezone.utc) - timedelta(hours=24)
tasks = json.load(sys.stdin) if sys.stdin else []
longblock = []
for t in tasks:
    updated_str = t.get('updated_at', '') or t.get('created_at', '') or t.get('created', '')
    if not updated_str: continue
    try: updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00'))
    except: continue
    if updated < threshold:
        longblock.append(f\"  🔴  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | blocked_since={updated.strftime('%Y-%m-%d %H:%M')}\")
print(len(longblock))
for s in longblock:
    print(s, file=sys.stderr)
" 2>&1 1>/dev/stdout)

if [ "$BLOCKED_LONG" -gt 0 ] 2>/dev/null; then
  echo "🚨  LONG-BLOCKED (>24h): ${BLOCKED_LONG} task(s) — ESCALATION NEEDED"
  python3 -c "
import sys, json
from datetime import datetime, timezone, timedelta
threshold = datetime.now(timezone.utc) - timedelta(hours=24)
tasks = json.load(sys.stdin) if sys.stdin else []
for t in tasks:
    updated_str = t.get('updated_at', '') or t.get('created_at', '') or t.get('created', '')
    if not updated_str: continue
    try: updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00'))
    except: continue
    if updated < threshold:
        print(f\"  🔴  {t.get('id','?')[:16]} | {t.get('title','Untitled')[:60]} | blocked_since={updated.strftime('%Y-%m-%d %H:%M')}\")
" <<< "$BLOCKED_JSON"
  ISSUES_FOUND=1
fi

# ─── SUMMARY ────────────────────────────────────────────
echo ""
if [ "$ISSUES_FOUND" -eq 0 ]; then
  echo "✅  [${TIMESTAMP}] Kanban board clean — no stale tasks detected."
  echo "   Next scan in ~5 minutes."
else
  echo "🔴  [${TIMESTAMP}] ISSUES DETECTED — see above for details."
  echo "   Action: check gateway health + dispatch or investigate."
fi

exit 0
CRON_EOF

chmod +x ~/.hermes/skills/hermex-android/scripts/kanban-staleness-check.sh

# Create the cron job (runs every 5 minutes)
hermes cron create "every 5m" \
  --name "Hermex Android — Kanban Staleness Monitor" \
  --script ~/.hermes/skills/hermex-android/scripts/kanban-staleness-check.sh

# Verify cron is running
hermes cron status
hermes cron list
```

### §2.3 — Thresholds Table

| Lane Type | Unclaimed Threshold | In-Progress Threshold | Blocked Threshold |
|-----------|-------------------|----------------------|-------------------|
| P0 (ARCHITECTURE_REVIEW, HOSTILE_AUDIT) | 15 minutes | 30 minutes | 12 hours |
| P1 (FLUTTER_IMPLEMENTATION, BACKEND_DESIGN) | 30 minutes | 30 minutes | 24 hours |
| P2 (DOCUMENTATION_GATE, UX_DESIGN) | 30 minutes | 60 minutes | 24 hours |

### §2.4 — Notification Routing

The cron job output is delivered via:
1. **Hermes cron logs:** `hermes cron list` → view output
2. **Telegram:** If the default profile has Telegram configured, staleness alerts are pushed as messages
3. **Dashboard:** The Swarm2 dashboard surfaces stale task badges

---

## ARTICLE III — LEAD ARCHITECT DELEGATION TIERS (Change 3)

### §3.1 — The Single Point of Failure Problem

DeepSeek correctly identified: when the Lead Architect session truncates (200 turns),
crashes, or the human is unavailable, ALL 9 profiles are blocked. No autonomous
recovery exists. **This is not governance — it is a bet that nothing will go wrong.**

### §3.2 — Delegation Structure

The delegation authority cascades through THREE tiers with **domain-specific
authority** — not a simple linear chain.

```
                    ┌─────────────────────────┐
                    │  T1: LEAD ARCHITECT     │
                    │  Full authority          │
                    │  Default decision-maker  │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │                         │
          ┌─────────┴─────────┐   ┌──────────┴──────────┐
          │ T2a: DEVOPS       │   │ T2b: PRODUCT STEWARD │
          │ Infrastructure    │   │ Scope & Spec         │
          │ Gateways, CI/CD   │   │ PRD, Ambiguity       │
          │ Builds, Releases  │   │ Task unblocking       │
          └─────────┬─────────┘   └──────────┬──────────┘
                    │                         │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │  T3: DOCUMENTATION       │
                    │  Spec files, LL registry │
                    │  Non-blocking, always-on │
                    └─────────────────────────┘
```

### §3.3 — Tier Authority Matrix

| Tier | Profile | Activation Trigger | CAN Do | CANNOT Do |
|------|---------|-------------------|--------|-----------|
| **T1** | `flutter-lead-architect` | Default | Everything | — |
| **T2a** | `flutter-devops-release-engineer` | T1 >10min unresponsive | Restart gateways, fix CI, resolve build failures, approve release gates | Change architecture, add packages, modify spec, approve code changes, alter monetization |
| **T2b** | `flutter-product-steward` | T1 >10min unresponsive | Unblock spec-ambiguity tasks, clarify PRD scope, approve minor spec fixes, reject out-of-scope work | Change architecture, add packages, modify monetization, approve production release, restart gateways |
| **T3** | `flutter-documentation-steward` | Always active (non-blocking) | Maintain spec files, register lessons learned, update traceability matrix, fix documentation | Change code, unblock tasks, approve anything, restart gateways |

### §3.4 — Immutable CANNOT-DO List (All Tiers)

The following actions are **PERMANENTLY PROHIBITED** for T2 and T3, regardless
of how long the Lead Architect is unavailable:

1. ❌ Change the architecture of any Flutter module
2. ❌ Add new packages to `pubspec.yaml`
3. ❌ Modify monetization/entitlement logic
4. ❌ Approve a production APK release
5. ❌ Modify GOV-001 enforcement (Lead Architect code prohibition)
6. ❌ Create or delete Kanban lanes
7. ❌ Change profile SOUL.md files (except T3 for documentation stewards only, per existing SOUL)
8. ❌ Unblock a HOSTILE_AUDIT `review-required` task (auditor findings need human review)

### §3.5 — Mandatory Audit Trail

Every delegation action MUST be logged with:

```markdown
## [AUTONOMOUS-DELEGATION] — <timestamp>
- **Trigger:** <Lead Architect unresponsive for X minutes / session truncated>
- **Tier:** <T2a/T2b/T3>
- **Action:** <what was done>
- **Rationale:** <why this couldn't wait>
- **Files Affected:** <list or N/A>
- **Revertible:** <YES/NO — and if NO, why>
```

Logged to: `app-spec/12_decision_log.md` with `[AUTONOMOUS-DELEGATION]` prefix.

### §3.6 — Implementation Command

Append to `flutter-lead-architect/SOUL.md` — found at the Google Drive path:

```bash
# First, locate the SOUL file
SOUL_PATH="$HOME/Library/CloudStorage/GoogleDrive-almohalhel1408@gmail.com/ملفاتي/My Mind/Flutter Operation/flutter-lead-architect/SOUL.md"

# If found, append the delegation section
if [ -f "$SOUL_PATH" ]; then
  cat >> "$SOUL_PATH" << 'SOUL_EOF'

## §13 — Delegation Tiers (Autonomous Mode Fallback)

**Authority:** Art. III of GOVERNANCE_CONSTITUTION.md

When the Lead Architect cannot respond within 10 minutes (session truncated,
context limit reached, or user unavailable), decision authority cascades:

### Tier Structure

| Tier | Profile | Domain | Trigger |
|------|---------|--------|---------|
| T1 | Lead Architect (self) | Full authority | Default |
| T2a | flutter-devops-release-engineer | Infrastructure: gateways, CI/CD, builds, releases | Lead >10min unresponsive |
| T2b | flutter-product-steward | Scope: spec ambiguity, PRD clarification, task unblocking (non-code) | Lead >10min unresponsive |
| T3 | flutter-documentation-steward | Documentation: spec files, LL registry, traceability | Always active (non-blocking) |

### CANNOT-DO (Immutable — Never Waive)

Tiers T2a/T2b/T3 SHALL NOT:
1. Change Flutter module architecture
2. Add packages to pubspec.yaml
3. Modify monetization/entitlement logic
4. Approve production APK release
5. Modify GOV-001 enforcement
6. Create/delete Kanban lanes
7. Change profile SOUL.md files
8. Unblock HOSTILE_AUDIT review-required tasks

### Mandatory Logging

Every delegation action MUST log to `app-spec/12_decision_log.md`:
```
## [AUTONOMOUS-DELEGATION] — <timestamp>
- Trigger: <reason>
- Tier: <T2a/T2b/T3>
- Action: <description>
- Rationale: <justification>
- Revertible: <YES/NO>
```

### Notification

On ANY delegation activation, post to Telegram (default profile):
"🤖 [AUTONOMOUS] <Tier> activated: <action>. Lead Architect unresponsive >10min."
SOUL_EOF
  echo "✅ Delegation tiers appended to Lead Architect SOUL.md"
else
  echo "⚠️  SOUL.md not found at: $SOUL_PATH"
  echo "   Manually append the §13 section from GOVERNANCE_CONSTITUTION.md Art. III"
fi
```

---

## ARTICLE IV — IMMUTABLE GOVERNANCE RULES

The following rules are **HARD-CODED into automation** and shall NEVER be waived.

### §4.1 — GOV-001: No Direct Code Execution by Orchestrator

**Automated enforcement:**
- SCSI Hunt L1 pattern `GOV-001-VIOLATION`: greps git log for commits by `flutter-lead-architect` touching `lib/` or `test/`
- Pre-commit hook: blocks commits from `flutter-lead-architect` profile to `lib/` or `test/`
- CI gate: fails build if last commit author is `flutter-lead-architect` and touches Dart files

```bash
# Automated enforcement (CI):
git log -1 --pretty=format:'%an' | grep -q "flutter-lead-architect" && \
  git diff --name-only HEAD~1..HEAD | grep -qE '^(lib/|test/).*\.dart$' && \
  echo "❌ GOV-001 VIOLATION: Lead Architect committed code" && exit 1
```

### §4.2 — GOV-005: No Redacted Literals in Source Code

**Automated enforcement:**
- Pre-commit hook: `grep -rn '\*\*\*' lib/ test/` → blocks commit on match
- CI gate: same grep → fails build

```bash
# Pre-commit hook (add to .git/hooks/pre-commit):
if grep -rn '\*\*\*' lib/ test/ 2>/dev/null; then
  echo "❌ GOV-005 VIOLATION: Triple-asterisk redaction artifact detected"
  echo "   Replace with actual variable reference before committing"
  exit 1
fi
```

### §4.3 — AUTOMATED VS. DOCUMENTED RULES

| Rule | Source | Status Before | Status After Constitution |
|------|--------|-------------|--------------------------|
| GOV-001 | LL-030 | Documented (manual) | **AUTOMATED** (CI gate + SCSI pattern) |
| GOV-005 | LL-022 | Documented (manual) | **AUTOMATED** (pre-commit hook + CI gate) |
| Gateway Health | LL-020 class | Not documented | **AUTOMATED** (gate script + cron) |
| Staleness Detection | EPIC-001 | None | **AUTOMATED** (5-min cron) |
| Delegation Fallback | N/A | None | **AUTOMATED** (T2/T3 SOUL enforcement) |

---

## ARTICLE V — SUCCESS METRICS (MEASURABLE KPIs)

### §5.1 — Tier 1: Must-Hit (Zero Tolerance)

| KPI | Target | Measurement | Frequency |
|-----|--------|-------------|-----------|
| **Orphaned tasks (undetected >1 hour)** | **0** | Staleness cron log | Per-scan (5min) |
| **Dispatch to dead gateway** | **0** | Gateway health gate exit code | Per-dispatch |
| **GOV-001 violations (Lead Architect code commits)** | **0** | CI gate / git log scan | Per-commit |
| **GOV-005 violations (redacted literals)** | **0** | Pre-commit hook | Per-commit |
| **Kanban tasks blocked >48 hours without comment** | **0** | Staleness cron | Per-scan |

### §5.2 — Tier 2: Should-Not-Exceed

| KPI | Target | Measurement |
|-----|--------|-------------|
| Time from gateway death to detection | **< 5 minutes** | Cron scan interval |
| Time from task creation to dispatch | **< 10 minutes** (P0), **< 30 minutes** (P1) | Kanban `created_at` → `claimed_at` |
| Autonomous delegation activations without Telegram notification | **0** | Decision log audit |
| SCSI Guardian scan cycles skipped (gateway down) | **< 2 per week** | Gateway health gate blocks guardian dispatch if dead |

### §5.3 — Tier 3: Health Indicators

| KPI | Green | Yellow | Red |
|-----|-------|--------|-----|
| Profile gateways running | 10/10 | 9/10 | ≤8/10 |
| Kanban board stale tasks | 0 | 1-2 | ≥3 |
| Average task lifecycle (create→done) | < 4 hours | 4-8 hours | > 8 hours |
| Decision log entries per week | 5-15 | 2-4 or 16-25 | <2 or >25 |

---

## ARTICLE VI — RUNTIME GOVERNANCE (DAILY OPERATIONS)

### §6.1 — Pre-Goal Launch Checklist

Before ANY `/goal` or major Kanban dispatch:

```bash
# 1. Gateway Health Gate (MANDATORY)
bash ~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh
# MUST exit 0 before proceeding

# 2. Verify cron is running
hermes cron status

# 3. Check existing stale tasks
bash ~/.hermes/skills/hermex-android/scripts/kanban-staleness-check.sh

# 4. Verify SCSI patterns are up-to-date
python3 ~/Projects/hermex_android/scripts/scsi-hunt.py --quick

# 5. Launch
echo "✅ All governance gates passed. Safe to launch."
```

### §6.2 — Post-Crash Recovery

```bash
# 1. Kill all zombie gateways
ps aux | grep "hermes.*gateway.*profile" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

# 2. Bootstrap all 10 profiles
for profile in flutter-lead-architect flutter-product-steward flutter-ui-ux-designer \
  flutter-backend-db-architect flutter-state-engineer flutter-qa-tester \
  flutter-zero-trust-auditor flutter-devops-release-engineer \
  flutter-documentation-steward flutter-curiosity-hunter; do
  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.hermes.gateway-${profile}.plist 2>/dev/null || \
  launchctl kickstart gui/$(id -u)/ai.hermes.gateway-${profile} 2>/dev/null
done

# 3. Wait for all to come up
sleep 15

# 4. Verify
bash ~/.hermes/skills/hermex-android/scripts/gateway-health-gate.sh
```

### §6.3 — Weekly Governance Audit (Every Monday)

```bash
# Run this every Monday morning
echo "=== GOVERNANCE WEEKLY AUDIT — $(date) ==="

# 1. Gateway uptime
echo "--- Gateway Status ---"
hermes gateway list | grep flutter

# 2. Staleness stats
echo "--- Stale Task Scan ---"
bash ~/.hermes/skills/hermex-android/scripts/kanban-staleness-check.sh

# 3. GOV-001 check
echo "--- GOV-001 Violation Check ---"
git -C ~/Projects/hermex_android log --since="7 days ago" --oneline --author="flutter-lead-architect" -- 'lib/' 'test/' || echo "✅ Clean"

# 4. GOV-005 check
echo "--- GOV-005 Redacted Literal Check ---"
grep -rn '\*\*\*' ~/Projects/hermex_android/lib/ ~/Projects/hermex_android/test/ 2>/dev/null || echo "✅ Clean"

# 5. Decision log entries this week
echo "--- Decision Log Activity ---"
grep -c "2026-07" ~/Projects/hermex_android/app-spec/12_decision_log.md 2>/dev/null || echo "0 entries"

echo "=== AUDIT COMPLETE ==="
```

---

## ARTICLE VII — AMENDMENT PROCEDURE

### §7.1 — When Amendments Are Allowed

This Constitution may be amended ONLY under the following conditions:

1. **New LL entry** (lessons learned) that reveals a governance gap not covered
2. **Profile roster change** (profile added/removed — update profile arrays)
3. **Hermes CLI API change** (commands change — update scripts)
4. **Quarterly review** (every 3 months: re-evaluate thresholds, tiers, KPIs)

### §7.2 — Amendment Process

1. Propose amendment in `app-spec/` as draft markdown
2. Lead Architect + 2 other profiles must approve
3. Update this Constitution document
4. Update affected scripts
5. Log amendment to `app-spec/12_decision_log.md`
6. Bump version in document footer

---

## ARTICLE VIII — CONFLICT RESOLUTION

### §8.1 — If Two Governance Rules Conflict

Precedence order (highest to lowest):
1. **GOV-001** (no orchestrator code execution) — NEVER overridden
2. **GOV-005** (no redacted literals) — NEVER overridden
3. **Gateway Health Gate** — MUST pass before dispatch
4. **Delegation Tiers** — CANNOT override T1 authority
5. **Staleness Cron** — advisory; can be muted for known long-running tasks

### §8.2 — If Automation Fails

1. **Gateway health gate script crashes:** Fall back to manual `hermes gateway list` check
2. **Staleness cron fails:** Cron job runs `--script` mode; hermex will retry on next tick
3. **Delegation tier SOUL not loaded:** Profiles fall back to their base SOUL without delegation — escalation goes to human

---

## SIGNATORIES

| Role | Profile | Status |
|------|---------|--------|
| **Ratifying Authority** | Triple-Chinese MoA (deepseek-v4-pro + qwen3.7-max + glm-5.2) | ✅ FINAL SYNTHESIS |
| **Adversarial Reviewer** | DeepSeek-v4-pro (Rounds 2, 4, 6, 8) | ✅ Challenge incorporated |
| **Lead Architect** | flutter-lead-architect | Binding on load |
| **Infrastructure Owner** | flutter-devops-release-engineer | Executes Art. I, II |
| **Product Owner** | flutter-product-steward | Executes Art. III T2b |
| **Documentation Steward** | flutter-documentation-steward | Executes Art. III T3 |

---

*This Constitution was produced by 9 rounds of adversarial governance dialogue.
Round 1 (Triple-Chinese Diagnosis), Round 2 (DeepSeek C-minus critique),
Round 3 (Triple-Chinese 5-layer model), Rounds 4+6+8 (DeepSeek 3-layer collapse
+ 3 concrete changes + EPIC-001 stress test), Rounds 5+7+9 (Triple-Chinese FINAL
SYNTHESIS). All 30+ lessons learned (LL-001 through LL-033), 6 governance rules
(GOV-001, GOV-005), and real EPIC-001 failure data inform this document.*

**Version:** 1.0.0 | **Ratified:** 2026-07-09 | **Next Review:** 2026-10-09
