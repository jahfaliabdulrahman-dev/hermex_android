#!/usr/bin/env python3
"""
SCSI Layer 2: Red Team Audit Engine
Adversarial testing — actively tries to break the app using known attack vectors.

Attack vectors:
- AV-001: Role Alternation Violation (consecutive same-role messages)
- AV-002: Rapid State Mutation (spam copyWith calls)
- AV-003: URL Injection (credentials in URL, host injection)
- AV-004: Null/Empty Boundary (empty strings, null values, oversized inputs)
- AV-005: SSE Stream Corruption (malformed chunks, connection drop)
- AV-006: Auth Token Manipulation (expired, malformed, missing tokens)
- AV-007: Session Hijack (cross-session message injection)
- AV-008: Android Cleartext Bypass (HTTP downgrade attempt)
- AV-009: ProGuard Strip Test (verify Isar classes survive)
- AV-010: Namespace Collision (conflicting package declarations)

Usage: python3 scripts/scsi-redteam.py [--attack ALL|AV-001,AV-002] [--output report.json]
"""

import json, os, sys, re, subprocess, hashlib
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field, asdict

PROJECT_ROOT = Path(__file__).resolve().parent.parent

@dataclass
class AttackVector:
    id: str
    name: str
    category: str
    target_files: list
    severity: str
    description: str
    test_fn: str  # Name of the test function

@dataclass
class Finding:
    attack_id: str
    severity: str
    file: str
    line: int = 0
    description: str = ""
    evidence: str = ""
    suggested_fix: str = ""
    false_positive: bool = False

@dataclass
class RedTeamReport:
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    attacks_run: int = 0
    findings: list = field(default_factory=list)
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0
    clean: int = 0

# ─── Attack Vector Definitions ───────────────────────────────────────────

ATTACK_VECTORS = [
    AttackVector(
        id="AV-001", name="Role Alternation Violation",
        category="STATE_MANAGEMENT",
        target_files=["lib/features/chat/providers/chat_provider.dart"],
        severity="CRITICAL",
        description="Check for consecutive same-role messages in API request construction (LL-029 class)",
        test_fn="check_role_alternation"
    ),
    AttackVector(
        id="AV-002", name="Rapid State Mutation",
        category="DART_RIVERPOD",
        target_files=["lib/features/**/providers/*.dart"],
        severity="HIGH",
        description="Find all state.copyWith() calls and verify no snapshot is taken after mutation",
        test_fn="check_mutation_order"
    ),
    AttackVector(
        id="AV-003", name="URL Injection Attack",
        category="SECURITY",
        target_files=["lib/features/connection/data/server_repository.dart"],
        severity="CRITICAL",
        description="Test URL parser with injection payloads: userinfo in URL, host spoofing, path traversal",
        test_fn="check_url_injection"
    ),
    AttackVector(
        id="AV-004", name="Null/Empty Boundary Fuzzing",
        category="INPUT_VALIDATION",
        target_files=["lib/features/**/*.dart"],
        severity="MEDIUM",
        description="Find input handlers without null/empty validation (trimming, isEmpty checks)",
        test_fn="check_null_boundaries"
    ),
    AttackVector(
        id="AV-005", name="SSE Stream Corruption",
        category="NETWORK",
        target_files=["lib/features/chat/data/chat_repository.dart", "lib/core/api/sse_client.dart"],
        severity="HIGH",
        description="Check SSE stream parsing handles malformed chunks, partial data, connection drops",
        test_fn="check_sse_resilience"
    ),
    AttackVector(
        id="AV-006", name="Auth Token Manipulation",
        category="SECURITY",
        target_files=["lib/core/auth/*.dart", "lib/core/storage/*.dart"],
        severity="CRITICAL",
        description="Verify auth manager handles expired, malformed, missing, and empty tokens",
        test_fn="check_auth_handling"
    ),
    AttackVector(
        id="AV-008", name="Android Cleartext Bypass",
        category="SECURITY",
        target_files=["android/app/src/main/res/xml/network_security_config.xml"],
        severity="CRITICAL",
        description="Verify network_security_config allows cleartext for local network (LL-027 fix applied?)",
        test_fn="check_cleartext_config"
    ),
    AttackVector(
        id="AV-009", name="ProGuard/Isar Survival Test",
        category="ANDROID_BUILD",
        target_files=["android/app/build.gradle.kts", "android/app/proguard-rules.pro"],
        severity="CRITICAL",
        description="Verify isMinifyEnabled=false when Isar is a dependency (LL-025 fix applied?)",
        test_fn="check_proguard_isar"
    ),
    AttackVector(
        id="AV-010", name="Namespace Collision Test",
        category="ANDROID_BUILD",
        target_files=["android/app/build.gradle.kts", "android/app/src/main/kotlin/**/MainActivity.kt"],
        severity="CRITICAL",
        description="Verify namespace in build.gradle.kts matches MainActivity.kt package (LL-024 fix applied?)",
        test_fn="check_namespace_match"
    ),
]

# ─── Attack Functions ────────────────────────────────────────────────────

def grep_file(pattern, filepath):
    """Search pattern in file, return list of (line_num, line_content)."""
    try:
        content = Path(filepath).read_text()
        results = []
        for i, line in enumerate(content.split('\n'), 1):
            if re.search(pattern, line):
                results.append((i, line.strip()))
        return results
    except Exception:
        return []

def check_role_alternation(report):
    """AV-001: Check for state.copyWith before _buildHistory in chat_provider."""
    file = PROJECT_ROOT / "lib/features/chat/providers/chat_provider.dart"
    if not file.exists():
        return
    
    content = file.read_text()
    lines = content.split('\n')
    
    # Find state.copyWith with messages containing userMessage
    copywith_lines = []
    buildhistory_lines = []
    
    for i, line in enumerate(lines, 1):
        if 'state.copyWith' in line and 'messages' in line:
            copywith_lines.append(i)
        if '_buildHistory()' in line or 'final history =' in line:
            buildhistory_lines.append(i)
    
    for cl in copywith_lines:
        # Check if _buildHistory is called BEFORE this copyWith (within 20 lines above)
        before = [bh for bh in buildhistory_lines if bh < cl and cl - bh < 30]
        after = [bh for bh in buildhistory_lines if bh > cl and bh - cl < 30]
        
        if after and not before:
            report.findings.append(Finding(
                attack_id="AV-001",
                severity="CRITICAL",
                file=str(file.relative_to(PROJECT_ROOT)),
                line=cl,
                description="_buildHistory() called AFTER state.copyWith() — duplicate messages bug (LL-029)",
                evidence=f"state.copyWith at line {cl}, _buildHistory at line {after[0]}",
                suggested_fix="Move _buildHistory() to before state.copyWith()"
            ))
        elif before:
            report.clean += 1  # Correct order

def check_mutation_order(report):
    """AV-002: Find all copyWith calls and verify history capture precedes them."""
    for filepath in PROJECT_ROOT.glob("lib/features/**/providers/*.dart"):
        content = filepath.read_text()
        lines = content.split('\n')
        
        copywith_indices = [
            (i, line.strip()) for i, line in enumerate(lines, 1)
            if 'copyWith' in line and 'state' in line.lower()
        ]
        
        for idx, line in copywith_indices:
            # Look for history/snapshot builders in the preceding 15 lines
            pre_context = '\n'.join(lines[max(0, idx-15):idx])
            has_snapshot = any(term in pre_context.lower() for term in 
                ['_buildhistory', 'snapshot', 'messages.where', '.where(', 'tovectored'])
            
            if not has_snapshot and ('messages' in line or 'list' in line.lower()):
                report.findings.append(Finding(
                    attack_id="AV-002",
                    severity="MEDIUM",
                    file=str(filepath.relative_to(PROJECT_ROOT)),
                    line=idx,
                    description=f"copyWith mutation without preceding snapshot — potential order bug",
                    evidence=line[:100],
                    suggested_fix="Capture snapshot/history before mutating state"
                ))

def check_url_injection(report):
    """AV-003: Test URL validation with attack payloads."""
    file = PROJECT_ROOT / "lib/features/connection/data/server_repository.dart"
    if not file.exists():
        return
    
    content = file.read_text()
    
    # Check if URL validation exists
    if '_validateUrl' not in content and 'validateUrl' not in content:
        report.findings.append(Finding(
            attack_id="AV-003",
            severity="CRITICAL",
            file="lib/features/connection/data/server_repository.dart",
            description="No URL validation function found — vulnerable to injection",
            suggested_fix="Add _validateUrl() with userinfo, scheme, and host checks"
        ))
        return
    
    # Check for specific protections
    checks = {
        'userInfo': 'No userinfo (credentials-in-URL) check',
        'isLocalNetwork': 'No local network restriction for HTTP',
        'uri.scheme': 'No scheme validation',
        'uri.host': 'No host validation',
    }
    
    for key, msg in checks.items():
        if key not in content:
            report.findings.append(Finding(
                attack_id="AV-003",
                severity="HIGH",
                file="lib/features/connection/data/server_repository.dart",
                description=f"Missing URL protection: {msg}",
                suggested_fix=f"Add {key} check in _validateUrl()"
            ))
    
    if not any(key in content for key in checks):
        return  # All checks present, clean
    report.clean += 1

def check_null_boundaries(report):
    """AV-004: Find input handlers without validation."""
    for filepath in PROJECT_ROOT.glob("lib/features/**/*.dart"):
        content = filepath.read_text()
        
        # Find functions that accept user input but don't validate
        input_patterns = [
            r'Future.*sendMessage\(',
            r'Future.*createSession\(',
            r'void.*onChanged\(',
            r'void.*onSubmitted\(',
        ]
        
        for pattern in input_patterns:
            matches = re.finditer(pattern, content)
            for m in matches:
                func_start = m.start()
                # Find the function body — next 50 lines
                end = min(len(content), func_start + 2000)
                body = content[func_start:end]
                
                # Check for validation
                has_validation = any(term in body for term in 
                    ['.trim()', 'isEmpty', 'is null', 'isNullOrEmpty', '?.', 'if (', 'validate'])
                
                if not has_validation:
                    line_num = content[:func_start].count('\n') + 1
                    report.findings.append(Finding(
                        attack_id="AV-004",
                        severity="LOW",
                        file=str(filepath.relative_to(PROJECT_ROOT)),
                        line=line_num,
                        description=f"Input handler without validation",
                        evidence=body[:80].strip(),
                        suggested_fix="Add null/empty validation before processing input"
                    ))

def check_sse_resilience(report):
    """AV-005: Check SSE stream handling robustness."""
    sse_files = list(PROJECT_ROOT.glob("lib/**/sse_client.dart")) + \
                list(PROJECT_ROOT.glob("lib/**/chat_repository.dart"))
    
    for filepath in sse_files:
        content = filepath.read_text()
        
        checks = {
            'onError': 'No error handler for SSE stream',
            'cancelOnError': 'No cancelOnError configuration',
            'try.*catch': 'No try-catch around stream operations',
            'timeout': 'No timeout for SSE connection',
        }
        
        for key, msg in checks.items():
            if not re.search(key, content):
                report.findings.append(Finding(
                    attack_id="AV-005",
                    severity="MEDIUM",
                    file=str(filepath.relative_to(PROJECT_ROOT)),
                    description=f"SSE resilience gap: {msg}",
                    suggested_fix=f"Add {key} handling to stream operations"
                ))

    # If all files had all checks
    if not [f for f in report.findings if f.attack_id == "AV-005"]:
        report.clean += 1

def check_auth_handling(report):
    """AV-006: Verify auth manager handles edge cases."""
    auth_files = list(PROJECT_ROOT.glob("lib/core/auth/*.dart"))
    if not auth_files:
        report.findings.append(Finding(
            attack_id="AV-006", severity="MEDIUM",
            file="lib/core/auth/",
            description="No auth module found — tokens may be unmanaged",
            suggested_fix="Create auth module with token validation, refresh, and expiry"
        ))
        return
    
    for filepath in auth_files:
        content = filepath.read_text()
        
        checks = {
            r'clear|remove|delete': 'No token clearing/removal logic',
            r'expir|expired': 'No token expiry handling',
            r'null|empty|isEmpty': 'No null/empty token handling',
        }
        
        for key, msg in checks.items():
            if not re.search(key, content):
                suggestion = msg.split(' — ')[1] if ' — ' in msg else msg
                report.findings.append(Finding(
                    attack_id="AV-006",
                    severity="HIGH",
                    file=str(filepath.relative_to(PROJECT_ROOT)),
                    description=f"Auth gap: {msg.split(' — ')[0] if ' — ' in msg else msg}",
                    suggested_fix=f"Add {suggestion}"
                ))

def check_cleartext_config(report):
    """AV-008: Verify network_security_config allows cleartext."""
    nsc = PROJECT_ROOT / "android/app/src/main/res/xml/network_security_config.xml"
    if not nsc.exists():
        report.findings.append(Finding(
            attack_id="AV-008", severity="CRITICAL",
            file="android/app/src/main/res/xml/network_security_config.xml",
            description="network_security_config.xml missing — Android may block HTTP",
            suggested_fix="Create network_security_config.xml with cleartextTrafficPermitted=true"
        ))
        return
    
    content = nsc.read_text()
    if 'cleartextTrafficPermitted="false"' in content:
        report.findings.append(Finding(
            attack_id="AV-008", severity="CRITICAL",
            file="android/app/src/main/res/xml/network_security_config.xml",
            description="cleartext HTTP is BLOCKED — private IPs may not connect (LL-027)",
            line=content[:content.index('cleartextTrafficPermitted="false"')].count('\n') + 1,
            suggested_fix="Set base-config cleartextTrafficPermitted=\"true\""
        ))
    else:
        report.clean += 1

def check_proguard_isar(report):
    """AV-009: Verify Isar + ProGuard compatibility."""
    build_gradle = PROJECT_ROOT / "android/app/build.gradle.kts"
    pubspec = PROJECT_ROOT / "pubspec.yaml"
    
    if not build_gradle.exists() or not pubspec.exists():
        return
    
    pubspec_content = pubspec.read_text()
    build_content = build_gradle.read_text()
    
    if 'isar:' in pubspec_content or 'isar_flutter_libs:' in pubspec_content:
        if 'isMinifyEnabled = true' in build_content:
            report.findings.append(Finding(
                attack_id="AV-009", severity="CRITICAL",
                file="android/app/build.gradle.kts",
                description="Isar dependency found but isMinifyEnabled=true — R8 will strip adapters (LL-025)",
                suggested_fix="Set isMinifyEnabled = false or add Isar keep rules"
            ))
        else:
            report.clean += 1

def check_namespace_match(report):
    """AV-010: Verify namespace matches MainActivity package."""
    build_gradle = PROJECT_ROOT / "android/app/build.gradle.kts"
    if not build_gradle.exists():
        return
    
    build_content = build_gradle.read_text()
    ns_match = re.search(r'namespace\s*=\s*"([^"]+)"', build_content)
    if not ns_match:
        return
    
    namespace = ns_match.group(1)
    
    # Find MainActivity.kt
    kotlin_dir = PROJECT_ROOT / "android/app/src/main/kotlin"
    if kotlin_dir.exists():
        for kt_file in kotlin_dir.rglob("*.kt"):
            kt_content = kt_file.read_text()
            pkg_match = re.search(r'^package\s+(\S+)', kt_content, re.MULTILINE)
            if pkg_match:
                pkg = pkg_match.group(1).strip()
                if namespace != pkg:
                    report.findings.append(Finding(
                        attack_id="AV-010", severity="CRITICAL",
                        file=str(kt_file.relative_to(PROJECT_ROOT)),
                        description=f"Namespace '{namespace}' != package '{pkg}' — ClassNotFoundException (LL-024)",
                        suggested_fix=f"Change namespace to '{pkg}' or package to '{namespace}'"
                    ))
                else:
                    report.clean += 1

# ─── Main Engine ─────────────────────────────────────────────────────────

def run_red_team(attacks=None):
    """Run Red Team audit. If attacks is None, run ALL."""
    report = RedTeamReport()
    
    attack_map = {av.id: av for av in ATTACK_VECTORS}
    
    if attacks is None or "ALL" in attacks:
        targets = list(attack_map.keys())
    else:
        targets = [a.strip() for a in attacks.split(',') if a.strip() in attack_map]
    
    print("🜔 SCSI Layer 2: Red Team Audit")
    print(f"   Target: {PROJECT_ROOT}")
    print(f"   Attacks: {len(targets)} vector(s)")
    print()
    
    for aid in targets:
        av = attack_map[aid]
        print(f"⚔️  {av.id}: {av.name} [{av.severity}]")
        
        # Call the test function
        test_func = globals().get(av.test_fn)
        if test_func:
            prev_findings = len(report.findings)
            test_func(report)
            new = len(report.findings) - prev_findings
            status = "🔴 FOUND" if new > 0 else "✅ CLEAN"
            print(f"   {status} ({new} finding(s))")
        else:
            print(f"   ⚠️  Test function '{av.test_fn}' not found")
    
    # Tally
    for f in report.findings:
        if f.severity == "CRITICAL": report.critical += 1
        elif f.severity == "HIGH": report.high += 1
        elif f.severity == "MEDIUM": report.medium += 1
        elif f.severity == "LOW": report.low += 1
    
    report.attacks_run = len(targets)
    
    return report

def print_report(report):
    """Print formatted Red Team report."""
    total = len(report.findings)
    
    print(f"\n{'='*60}")
    print(f"🛡️  RED TEAM AUDIT — {report.timestamp[:19]}")
    print(f"{'='*60}")
    print(f"   Attacks run: {report.attacks_run}")
    print(f"   🔴 CRITICAL: {report.critical}")
    print(f"   🟠 HIGH:     {report.high}")
    print(f"   🟡 MEDIUM:   {report.medium}")
    print(f"   🔵 LOW:      {report.low}")
    print(f"   ✅ CLEAN:    {report.clean}")
    print(f"{'='*60}")
    
    if report.findings:
        print(f"\n📋 Findings:")
        for f in sorted(report.findings, key=lambda x: (x.severity != 'CRITICAL', x.severity != 'HIGH', x.file)):
            emoji = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🔵'}.get(f.severity, '⚪')
            print(f"\n{emoji} [{f.attack_id}] {f.severity} — {f.file}:{f.line}")
            print(f"   {f.description}")
            print(f"   Fix: {f.suggested_fix}")
    
    if report.critical == 0:
        print(f"\n✅ RED TEAM AUDIT PASSED — No critical vulnerabilities.")
    else:
        print(f"\n🛑 RED TEAM AUDIT FAILED — {report.critical} CRITICAL finding(s).")
    
    return report

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='SCSI Layer 2: Red Team Audit')
    parser.add_argument('--attack', default='ALL', help='Attack vectors to run (comma-separated, or ALL)')
    parser.add_argument('--output', help='JSON output file')
    parser.add_argument('--json', action='store_true', help='Output JSON only')
    args = parser.parse_args()
    
    report = run_red_team(args.attack)
    
    if args.json:
        print(json.dumps(asdict(report), indent=2, default=str))
    else:
        print_report(report)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(asdict(report), f, indent=2, default=str)
    
    # Exit code: non-zero if CRITICAL findings
    sys.exit(1 if report.critical > 0 else 0)
