#!/usr/bin/env python3
"""
SCSI Layers 3, 4, 5: RCA Pipeline + Gate Factory + Intelligence Accumulator

L3 - RCA Pipeline: Automatic root cause analysis when bugs are found
L4 - Gate Factory: Auto-generate prevention gates (preflight/pre-commit checks)
L5 - Intelligence Accumulator: Pattern transfer, risk scoring, anomaly detection

Usage: python3 scripts/scsi-engine.py [--findings findings.json] [--auto-fix]
"""

import json, os, re, sys, sqlite3, subprocess, hashlib
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field, asdict

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = Path.home() / ".hermes" / "bug-corpus" / "patterns.db"

# ─── Layer 3: RCA Pipeline ──────────────────────────────────────────────

BUG_CLASSES = {
    "state_mutation_order": {
        "category": "DART_RIVERPOD",
        "severity": "CRITICAL",
        "pattern": "state.copyWith before snapshot capture",
        "detection": r"state\.copyWith.*messages.*\[.*userMessage.*\]",
        "target_files": "lib/features/**/providers/*.dart",
        "prevention_template": "Verify _buildHistory/snapshot called BEFORE state.copyWith"
    },
    "namespace_mismatch": {
        "category": "ANDROID_BUILD",
        "severity": "CRITICAL",
        "pattern": "namespace != MainActivity package",
        "detection": "verify: bash scripts/android-preflight.sh Gate 1",
        "target_files": "android/app/build.gradle.kts",
        "prevention_template": "Run android-preflight.sh Gate 1"
    },
    "isar_proguard_conflict": {
        "category": "ANDROID_BUILD", 
        "severity": "CRITICAL",
        "pattern": "isMinifyEnabled=true + Isar dependency",
        "detection": "verify: bash scripts/android-preflight.sh Gate 2",
        "target_files": "android/app/build.gradle.kts",
        "prevention_template": "Set isMinifyEnabled=false when Isar is a dependency"
    },
    "cleartext_blocked": {
        "category": "SECURITY",
        "severity": "CRITICAL",
        "pattern": "network_security_config blocks HTTP",
        "detection": "verify: bash scripts/android-preflight.sh Gate 5",
        "target_files": "android/app/src/main/res/xml/network_security_config.xml",
        "prevention_template": "Set base-config cleartextTrafficPermitted=true"
    },
    "duplicate_messages": {
        "category": "STATE_MANAGEMENT",
        "severity": "HIGH",
        "pattern": "Two consecutive same-role messages in API request",
        "detection": r"role.*user.*\n.*role.*user",
        "target_files": "lib/features/chat/**/*.dart",
        "prevention_template": "Add unit test verifying message role alternation"
    },
    "missing_input_validation": {
        "category": "INPUT_VALIDATION",
        "severity": "MEDIUM",
        "pattern": "Input handler without validation",
        "detection": r"Future.*\w+\(.*text.*\).*{(?!.*\.trim|.*isEmpty|.*validate)",
        "target_files": "lib/features/**/*.dart",
        "prevention_template": "Add .trim() and isEmpty check before processing"
    },
    "firewall_block": {
        "category": "NETWORK",
        "severity": "HIGH",
        "pattern": "macOS firewall blocks Python binary",
        "detection": "system: check socketfilterfw for hermes python path",
        "target_files": None,
        "prevention_template": "Add hermes Python to macOS firewall allow list"
    },
}

def classify_bug(finding):
    """Auto-classify a bug finding into the taxonomy."""
    desc = finding.get('description', '').lower()
    file_path = finding.get('file', '')
    
    if 'namespace' in desc and 'package' in desc:
        return "namespace_mismatch"
    if 'isminify' in desc or 'proguard' in desc or 'isar' in desc:
        return "isar_proguard_conflict"
    if 'cleartext' in desc or 'network_security' in desc:
        return "cleartext_blocked"
    if 'duplicate' in desc and ('message' in desc or 'role' in desc):
        return "duplicate_messages"
    if 'copywith' in desc or ('state' in desc and 'history' in desc):
        return "state_mutation_order"
    if 'validation' in desc or 'null' in desc or 'empty' in desc:
        return "missing_input_validation"
    if 'firewall' in desc:
        return "firewall_block"
    
    return "unknown"

def trace_root_cause(finding):
    """Trace bug to root cause using git blame and pattern matching."""
    file_path = finding.get('file', '')
    line = finding.get('line', 0)
    
    result = {
        'bug_class': classify_bug(finding),
        'root_cause': finding.get('description', 'Unknown'),
        'introduced_by': 'unknown',
        'introduced_date': 'unknown',
        'related_ll': [],
    }
    
    # Classify and link to existing LLs
    bc = result['bug_class']
    ll_map = {
        "namespace_mismatch": ["LL-024"],
        "isar_proguard_conflict": ["LL-025"],
        "cleartext_blocked": ["LL-027"],
        "firewall_block": ["LL-028"],
        "duplicate_messages": ["LL-029"],
        "state_mutation_order": ["LL-029"],
    }
    result['related_ll'] = ll_map.get(bc, [])
    
    # Try git blame for the offending line
    if file_path and line:
        try:
            full_path = PROJECT_ROOT / file_path
            if full_path.exists():
                result_blame = subprocess.run(
                    ['git', 'blame', '-L', f'{line},{line}', '--', file_path],
                    cwd=str(PROJECT_ROOT), capture_output=True, text=True, timeout=5
                )
                if result_blame.returncode == 0 and result_blame.stdout:
                    parts = result_blame.stdout.split()
                    if len(parts) >= 3:
                        result['introduced_by'] = parts[0][:8]  # Commit hash
        except Exception:
            pass
    
    return result

# ─── Layer 4: Gate Factory ───────────────────────────────────────────────

def generate_preflight_gate(bug_class, finding):
    """Generate a new preflight gate check for a bug class."""
    bc_info = BUG_CLASSES.get(bug_class, {})
    
    gates = {
        "namespace_mismatch": {
            'file': 'scripts/android-preflight.sh',
            'gate_name': f'Gate {finding.get("ll_id", "NEW")}: Namespace Match (auto-generated)',
            'check': 'NS=$(gradle_prop "namespace" android/app/build.gradle.kts)\nPKG=$(find android/app/src/main/kotlin -name "*.kt" -exec grep "^package" {} \\; 2>/dev/null | head -1 | sed "s/package //" | tr -d "[:space:]")\nif [ "$NS" != "$PKG" ]; then echo "FAIL"; fi',
        },
        "state_mutation_order": {
            'file': 'scripts/scsi-hunt.py',
            'gate_name': 'Pattern: Mutation Before Snapshot',
            'check': f'grep_pattern="{bc_info.get("detection", "")}"',
        },
        "missing_input_validation": {
            'file': 'scripts/scsi-redteam.py',
            'gate_name': 'AV-004 Enhanced: Input Validation',
            'check': f'attack_id="AV-004"',
        },
    }
    
    return gates.get(bug_class, {
        'file': 'scripts/scsi-hunt.py',
        'gate_name': f'Auto-gate for {bug_class}',
        'check': f'# Pattern: {bug_class}',
    })

def update_pattern_db(bug_class, finding, rca):
    """Update the pattern database with a new finding."""
    if not DB_PATH.exists():
        return False
    
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    bc_info = BUG_CLASSES.get(bug_class, {})
    
    # Check if this pattern already exists
    c.execute("SELECT id FROM patterns WHERE title LIKE ?", (f'%{bug_class}%',))
    existing = c.fetchone()
    
    if existing:
        # Update hit count
        c.execute("UPDATE patterns SET hit_count = hit_count + 1, last_hit = ? WHERE id = ?",
                  (datetime.now().isoformat(), existing[0]))
    else:
        # Insert new pattern
        ts = datetime.now().strftime("%Y%m%d%H%M%S"); new_ll = f"LL-AUTO-{ts}-{bug_class[:15].replace(chr(95), chr(45))}"
        c.execute("""
            INSERT OR IGNORE INTO patterns (ll_id, title, category, severity, root_cause, fix_summary, 
                                  date_found, found_by, pattern_regex, file_glob, prevention_gate)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'scsi-auto', ?, ?, ?)
        """, (
            new_ll,
            finding.get('description', 'Auto-detected bug')[:200],
            bc_info.get('category', 'UNKNOWN'),
            finding.get('severity', bc_info.get('severity', 'MEDIUM')),
            rca.get('root_cause', 'Unknown'),
            finding.get('suggested_fix', ''),
            datetime.now().isoformat(),
            bc_info.get('detection'),
            bc_info.get('target_files'),
            bc_info.get('prevention_template'),
        ))
    
    conn.commit()
    conn.close()
    return True

# ─── Layer 5: Intelligence Accumulator ────────────────────────────────────

def calculate_file_risk(file_path):
    """Calculate risk score for a file based on bug history and complexity."""
    if not DB_PATH.exists():
        return 0.0
    
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    # Count bugs associated with this file pattern
    c.execute("""
        SELECT COUNT(*), SUM(CASE WHEN severity='CRITICAL' THEN 3 
                                   WHEN severity='HIGH' THEN 2 
                                   ELSE 1 END)
        FROM patterns WHERE file_glob IS NOT NULL
    """)
    total, weighted = c.fetchone()
    
    # Get file-level bug count
    c.execute("SELECT bug_count FROM file_risk WHERE file_path = ?", (file_path,))
    row = c.fetchone()
    
    conn.close()
    
    base_risk = (weighted or 0) / max(total, 1) * 10
    file_bugs = row[0] if row else 0
    
    return round(base_risk + file_bugs * 2, 1)

def get_high_risk_files(threshold=5.0):
    """Get list of high-risk files that need extra scrutiny."""
    high_risk = []
    
    for ext in ['.dart', '.kts', '.xml']:
        for filepath in PROJECT_ROOT.rglob(f'*{ext}'):
            rel = str(filepath.relative_to(PROJECT_ROOT))
            if 'build/' in rel or '.dart_tool/' in rel or '.git/' in rel:
                continue
            
            risk = calculate_file_risk(rel)
            if risk >= threshold:
                high_risk.append((rel, risk))
    
    return sorted(high_risk, key=lambda x: x[1], reverse=True)

def update_file_risk_scores():
    """Update file risk scores in the database."""
    if not DB_PATH.exists():
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    c.execute("CREATE TABLE IF NOT EXISTS file_risk (file_path TEXT PRIMARY KEY, risk_score REAL DEFAULT 0.0, last_scanned TEXT, bug_count INTEGER DEFAULT 0, categories TEXT)")
    
    high_risk = get_high_risk_files(threshold=0.0)
    now = datetime.now().isoformat()
    
    for file_path, risk in high_risk[:50]:  # Top 50
        c.execute("""
            INSERT OR REPLACE INTO file_risk (file_path, risk_score, last_scanned, bug_count)
            VALUES (?, ?, ?, COALESCE((SELECT bug_count FROM file_risk WHERE file_path = ?), 0) + 1)
        """, (file_path, risk, now, file_path))
    
    conn.commit()
    conn.close()
    return high_risk[:20]

def detect_anomalies():
    """Detect anomalies in build metrics."""
    if not DB_PATH.exists():
        return []
    
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    anomalies = []
    
    # Check for sudden increase in findings
    c.execute("""
        SELECT bugs_found, timestamp FROM hunts 
        ORDER BY timestamp DESC LIMIT 10
    """)
    recent = c.fetchall()
    
    if len(recent) >= 3:
        avg = sum(r[0] for r in recent[1:]) / max(len(recent) - 1, 1)
        latest = recent[0][0]
        if latest > avg * 2:
            anomalies.append({
                'type': 'SPIKE',
                'description': f'Bug count spiked from avg {avg:.1f} to {latest}',
                'severity': 'HIGH'
            })
    
    # Check for patterns that never fire (stale gates)
    c.execute("SELECT ll_id, hit_count FROM patterns WHERE hit_count = 0 AND archived = 0")
    stale = c.fetchall()
    for ll_id, _ in stale:
        anomalies.append({
            'type': 'STALE_GATE',
            'description': f'Pattern {ll_id} has never fired — consider archiving',
            'severity': 'LOW'
        })
    
    conn.close()
    return anomalies

# ─── Main: Unified SCSI Engine ────────────────────────────────────────────

def run_scsi_full(findings_file=None, auto_fix=False):
    """Run the complete SCSI pipeline (L3+L4+L5) on findings."""
    
    print("🜔 SCSI Engine — Layers 3, 4, 5")
    print(f"   Project: {PROJECT_ROOT}")
    print(f"   Database: {DB_PATH}")
    print()
    
    findings = []
    
    # Load findings from Red Team output if provided
    if findings_file and Path(findings_file).exists():
        with open(findings_file) as f:
            data = json.load(f)
            findings = data.get('findings', [])
    
    # ─── L3: RCA Pipeline ───
    print("── Layer 3: RCA Pipeline ──")
    rca_results = []
    
    if findings:
        for finding in findings[:10]:  # Process up to 10 findings
            bug_class = classify_bug(finding)
            rca = trace_root_cause(finding)
            rca['bug_class'] = bug_class
            rca_results.append(rca)
            
            emoji = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🔵'}.get(
                finding.get('severity', 'MEDIUM'), '⚪')
            print(f"  {emoji} {bug_class}: {rca['root_cause'][:80]}")
            if rca['related_ll']:
                print(f"     Related: {', '.join(rca['related_ll'])}")
    else:
        print("  ℹ️  No findings to analyze. Feed this pipeline with Red Team output.")
    
    # ─── L4: Gate Factory ───
    print("\n── Layer 4: Gate Factory ──")
    gates_generated = 0
    
    for rca_item in rca_results:
        bc = rca_item.get('bug_class', 'unknown')
        finding = {'description': rca_item.get('root_cause', ''), 'severity': 'MEDIUM'}
        gate = generate_preflight_gate(bc, finding)
        
        if auto_fix and bc in BUG_CLASSES:
            updated = update_pattern_db(bc, finding, rca_item)
            if updated:
                print(f"  🛡️  Pattern DB updated: {bc}")
            print(f"  📝  Gate template: {gate['file']} → {gate['gate_name']}")
            gates_generated += 1
        else:
            print(f"  📋  Gate available: {gate['file']} — {gate['gate_name']}")
    
    print(f"  ℹ️  {gates_generated} gates {'auto-applied' if auto_fix else 'available'}.")
    
    # ─── L5: Intelligence Accumulator ───
    print("\n── Layer 5: Intelligence Accumulator ──")
    
    print("  📊 Calculating file risk scores...")
    high_risk = update_file_risk_scores()
    
    if high_risk:
        print(f"  🎯 Top 5 high-risk files:")
        for file_path, risk in high_risk[:5]:
            bar = '█' * int(risk) + '░' * (10 - int(risk))
            print(f"     [{bar}] {risk:.1f} — {file_path}")
    
    print("\n  🔍 Detecting anomalies...")
    anomalies = detect_anomalies()
    
    if anomalies:
        for a in anomalies:
            emoji = {'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🔵'}.get(a.get('severity', 'LOW'), '⚪')
            print(f"  {emoji} [{a['type']}] {a['description']}")
    else:
        print("  ✅ No anomalies detected.")
    
    # Summary
    print(f"\n{'='*60}")
    print(f"📊 SCSI ENGINE — COMPLETE")
    print(f"   L3: {len(rca_results)} bugs classified")
    print(f"   L4: {gates_generated} gates generated")
    print(f"   L5: {len(high_risk)} files scored, {len(anomalies)} anomalies")
    print(f"{'='*60}")
    
    return {
        'rca': rca_results,
        'gates': gates_generated,
        'high_risk_files': high_risk[:10] if high_risk else [],
        'anomalies': anomalies if anomalies else [],
    }

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='SCSI Layers 3-5: RCA + Gate Factory + Intelligence')
    parser.add_argument('--findings', help='JSON file from Red Team audit (L2 output)')
    parser.add_argument('--auto-fix', action='store_true', help='Auto-apply gates to pattern DB')
    parser.add_argument('--risk-report', action='store_true', help='Only show file risk report')
    parser.add_argument('--anomalies', action='store_true', help='Only show anomaly detection')
    args = parser.parse_args()
    
    if args.risk_report:
        high_risk = update_file_risk_scores()
        for fp, risk in high_risk[:20]:
            print(f"{risk:.1f}\t{fp}")
    elif args.anomalies:
        for a in detect_anomalies():
            print(f"[{a['type']}] {a['description']}")
    else:
        run_scsi_full(args.findings, args.auto_fix)
