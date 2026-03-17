#!/usr/bin/env sh
# env.sh - central loader for user environment fragments
# Designed to be sourced from bash or zsh. Safe to source multiple times.

# 1. FIXED: Do not export this variable, otherwise subshells will skip loading
# aliases and functions, which are not inherited across environments.
if [ -n "${OSSETUP_USER_ENV_LOADED:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
OSSETUP_USER_ENV_LOADED=1

# Resolve the directory of this script in a portable way (bash and zsh).
SCRIPT_FILE=""
if [ -n "${BASH_VERSION:-}" ]; then
    SCRIPT_FILE="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    SCRIPT_FILE="$(eval 'printf "%s" "${(%):-%x}"')"
else
    SCRIPT_FILE="$0"
fi
SCRIPT_DIR="$(cd -- "$(dirname "$SCRIPT_FILE")" >/dev/null 2>&1 && pwd)"

# Helper: source all files in a directory (sorted)
_source_dir() {
    dir="$1"
    [ -d "$dir" ] || return 0
    
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        
        # Skip disabled or sample files
        case "$(basename -- "$f")" in
            *.disabled|*.sample) continue ;;
        esac
        
        # If file ends with .sh, source it. Otherwise, try to export assignments.
        case "$f" in
            *.sh)
                # shellcheck disable=SC1090
                . "$f"
                ;;
            *)
                # Try to load as plain KEY=VAL assignments and export them
                set -a
                # shellcheck disable=SC1090
                . "$f" 2>/dev/null || true
                set +a
                ;;
        esac
    done
}

# 1) Load environment variable fragments from env.d/
_source_dir "$SCRIPT_DIR/env.d"

# 2) Load functions from functions.d/ (all files)
_source_dir "$SCRIPT_DIR/functions.d"

# 3) Load aliases from aliases.d/ (optional)
_source_dir "$SCRIPT_DIR/aliases.d"

# Provide a convenience function to reload the user_env while interactive
reload_user_env() {
    # FIXED: Unset the guard variable so the script actually runs again
    unset OSSETUP_USER_ENV_LOADED
    # shellcheck disable=SC1090
    . "$SCRIPT_DIR/env.sh"
    echo "Environment reloaded."
}

# Cleanup internal variables
unset _source_dir SCRIPT_FILE