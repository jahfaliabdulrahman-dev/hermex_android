#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# Hermex project shell wrapper
# Load with: source scripts/env.sh
# Or use direnv: echo 'source_env scripts/env.sh' > .envrc
#
# Purpose: prevent keystore passwords from leaking into
# shell history during release builds and other sensitive ops.
# ──────────────────────────────────────────────────────────

# Prevent commands from being written to shell history
# when working in the Hermex project directory.
# Comment this out if you need history for debugging,
# but re-enable before running any command with secrets.
unset HISTFILE

# Alternative: skip saving just the current session's commands
# that contain sensitive patterns (supported on bash/zsh):
# export HISTIGNORE="*keytool*:*keystore*:*key.properties*:*storePassword*"

echo "[hermex env] HISTFILE unset — shell history disabled for this session"
