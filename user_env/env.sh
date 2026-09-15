#!/usr/bin/env sh
# env.sh - central loader for user environment fragments
# Designed to be sourced from bash or zsh. Safe to source multiple times.

# 1. FIXED: Do not export this variable, otherwise subshells will skip loading
# aliases and functions, which are not inherited across environments.
if [ -n "${OSSETUP_USER_ENV_LOADED:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
OSSETUP_USER_ENV_LOADED=1

# managed by ossetuphelper
export PATH="$HOME/.local/bin:$PATH"

[ -d "$HOME/.config/env/bin" ] && export PATH="$HOME/.config/env/bin:$PATH"

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

    # zsh treats a glob with zero matches as a fatal error by default (NOMATCH),
    # which would abort the rest of this sourced script — including the
    # reload_env/reload_user_env definitions below. `null_glob` makes an empty
    # dir expand to nothing instead, like bash already does. Scoped to this
    # function only (local_options), so it doesn't change the caller's shell.
    if [ -n "${ZSH_VERSION:-}" ]; then
        setopt local_options null_glob
    fi

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

# De-duplicate PATH. Several env.d/ fragments (android.env, gcloud.env,
# python.env, ...) prepend to PATH directly and aren't individually guarded,
# so re-sourcing this file (every reload_env call re-runs all of env.d/)
# would otherwise pile up repeated entries. Doing it once here, after
# everything has loaded, guarantees no duplicates regardless of what any
# individual fragment does — no need to audit/guard each fragment separately.
_dedupe_path() {
    # zsh doesn't IFS-word-split unquoted expansions by default (unlike bash/sh),
    # so `for _dir in $PATH` would otherwise iterate exactly once over the
    # whole colon-joined string instead of once per entry, silently no-op-ing
    # this whole function. sh_word_split restores the POSIX behavior, scoped
    # to this function only.
    if [ -n "${ZSH_VERSION:-}" ]; then
        setopt local_options sh_word_split
    fi
    _old_ifs="$IFS"
    IFS=':'
    _new_path=""
    for _dir in $PATH; do
        [ -n "$_dir" ] || continue
        case ":$_new_path:" in
            *":$_dir:"*) ;;
            *) _new_path="${_new_path:+$_new_path:}$_dir" ;;
        esac
    done
    IFS="$_old_ifs"
    export PATH="$_new_path"
    unset _old_ifs _new_path _dir
}
_dedupe_path

# Reload the user env in the current interactive shell (safe to call anytime;
# re-sourcing is idempotent thanks to the guard above and the PATH dedupe).
reload_user_env() {
    # FIXED: Unset the guard variable so the script actually runs again
    unset OSSETUP_USER_ENV_LOADED
    # shellcheck disable=SC1090
    . "$SCRIPT_DIR/env.sh"
    echo "Environment reloaded."
}
# Alias kept for discoverability — this used to be a separate, broken
# function in functions.d/functions that pointed at a $PWD-relative path.
reload_env() {
    reload_user_env
}

# Cleanup internal variables
unset _source_dir _dedupe_path SCRIPT_FILE
