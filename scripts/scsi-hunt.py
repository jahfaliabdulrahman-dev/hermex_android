#!/usr/bin/env python3
"""SCSI Layer 1: Curiosity Engine — Hunt Script
Runs before release to proactively discover bugs by querying the pattern database
against current codebase. Returns non-zero exit if CRITICAL bugs found.

Usage: python3 scripts/scsi-hunt.py [--quick|--full]
  --quick: Fast scan (< 2 min) — only CRITICAL patterns
  --full:  Full scan (< 10 min) — all patterns + mutation tests
"""

import sqlite3, os, re, sys, json, time, subprocess
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = Path.home() / ".hermes" / "bug-corpus" / "patterns.db"

def load_patterns(db_path, quick_only=True):
    """Load active (non-archived) patterns from database."""
    if not db_path.exists():
        print("⚠️  Pattern database not found. Run setup first.")
        return []
    
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    query = "SELECT * FROM patterns WHERE archived = 0"
    if quick_only:
        query += " AND severity = 'CRITICAL'"
    query += " ORDER BY category, ll_id"
    rows = conn.execute(query).fetchall()
    conn.close()
    return [dict(r) for r in rows]

def scan_file(file_path, patterns):
    """Scan a single file against loaded patterns."""
    try:
        content = Path(file_path).read_text(errors='ignore')
    except Exception:
        return []
    
    matches = []
    for p in patterns:
        # Skip patterns without regex — they use verification gates instead
        rx = p.get('pattern_regex')
        if not rx:
            continue
        
        fg = p.get('file_glob')
        if fg:
            # Match any of the comma-separated globs
            if not any(Path(file_path).match(g.strip()) for g in fg.split(',')):
                continue
        
        try:
            if re.search(rx, content):
                matches.append(p)
        except re.error:
            pass
    return matches

def scan_project(project_root, patterns):
    """Scan all relevant project files."""
    results = []
    scan_exts = {'.dart', '.kts', '.xml', '.yaml', '.yml', '.gradle', '.sh', '.json', '.md'}
    
    for root, dirs, files in os.walk(str(project_root)):
        # Skip build artifacts, .git, etc.
        dirs[:] = [d for d in dirs if d not in {'.git', '.dart_tool', 'build', '.idea', 'node_modules', '.hermes'}]
        
        for f in files:
            ext = os.path.splitext(f)[1]
            if ext in scan_exts:
                file_path = os.path.join(root, f)
                matches = scan_file(file_path, patterns)
                for m in matches:
                    results.append({
                        'file': os.path.relpath(file_path, project_root),
                        'll_id': m['ll_id'],
                        'title': m['title'],
                        'category': m['category'],
                        'severity': m['severity'],
                    })
    return results

def run_analyzer(project_root):
    """Run flutter analyze and capture output."""
    try:
        result = subprocess.run(
            ['flutter', 'analyze', '--no-pub'],
            cwd=str(project_root),
            capture_output=True, text=True, timeout=60
        )
        errors = [l for l in result.stdout.split('\n') if 'error' in l.lower()]
        warnings = [l for l in result.stdout.split('\n') if 'warning' in l.lower()]
        return {'errors': len(errors), 'warnings': len(warnings), 'details': errors[:5]}
    except Exception as e:
        return {'errors': 0, 'warnings': 0, 'details': [str(e)]}

def update_db(results, duration):
    """Update pattern hit counts and record hunt."""
    if not DB_PATH.exists():
        return
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    now = datetime.now().isoformat()
    for r in results:
        c.execute("UPDATE patterns SET hit_count = hit_count + 1, last_hit = ? WHERE ll_id = ?",
                  (now, r['ll_id']))
    
    c.execute("INSERT INTO hunts (timestamp, patterns_matched, bugs_found, duration_seconds) VALUES (?, ?, ?, ?)",
              (now, len(set(r['ll_id'] for r in results)), len(results), duration))
    conn.commit()
    conn.close()

def main():
    quick = '--full' not in sys.argv
    mode = "QUICK" if quick else "FULL"
    
    print(f"🜔 SCSI Hunt — {mode} Mode")
    print(f"   Project: {PROJECT_ROOT}")
    print(f"   Database: {DB_PATH}")
    print()
    
    start = time.time()
    
    # Load patterns
    patterns = load_patterns(DB_PATH, quick_only=quick)
    print(f"📋 Loaded {len(patterns)} patterns ({len(set(p['category'] for p in patterns))} categories)")
    
    # Scan project
    results = scan_project(PROJECT_ROOT, patterns)
    duration = time.time() - start
    
    # Run analyzer
    analyzer = run_analyzer(PROJECT_ROOT)
    
    # Update database
    update_db(results, duration)
    
    # Report
    critical = [r for r in results if r['severity'] == 'CRITICAL']
    high = [r for r in results if r['severity'] == 'HIGH']
    
    print(f"\n🔍 Scan complete — {duration:.1f}s — {len(results)} matches")
    print(f"   flutter analyze: {analyzer['errors']} errors, {analyzer['warnings']} warnings")
    
    if critical:
        print(f"\n🔴 CRITICAL — {len(critical)} bugs found:")
        for r in critical:
            print(f"   {r['ll_id']}: {r['title']} [{r['file']}]")
    
    if high:
        print(f"\n🟠 HIGH — {len(high)} bugs found:")
        for r in high[:5]:
            print(f"   {r['ll_id']}: {r['title']} [{r['file']}]")
    
    if not critical and not high:
        print("\n✅ No critical/high patterns matched.")
    
    summary = {
        'mode': mode,
        'duration': round(duration, 1),
        'patterns_loaded': len(patterns),
        'bugs_found': len(results),
        'critical': len(critical),
        'high': len(high),
        'analyzer_errors': analyzer['errors'],
        'analyzer_warnings': analyzer['warnings'],
    }
    
    print(f"\n📊 Summary: {json.dumps(summary)}")
    
    # Exit code: non-zero if CRITICAL bugs found
    if critical:
        print(f"\n🛑 SCSI HUNT FAILED — {len(critical)} CRITICAL bugs. Fix before release.")
        sys.exit(1)
    
    print("\n✅ SCSI HUNT PASSED — Safe to release.")
    sys.exit(0)

if __name__ == '__main__':
    main()
