#!/usr/bin/env bash
# Encrypted developer docs. Plaintext lives in docs/dev/ (gitignored), only
# docs/dev.tar.gpg goes to GitHub (AES-256, password-based, via gpg).
#
#   docs/docs.sh unlock   decrypt docs/dev.tar.gpg into docs/dev/
#   docs/docs.sh lock     encrypt docs/dev/ into docs/dev.tar.gpg
#   docs/docs.sh status   "changed" if docs/dev/ differs from the last lock/unlock
#   docs/docs.sh hooks    use the repo's .githooks (pre-push, post-merge)
set -euo pipefail

repo="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
plain="$repo/docs/dev"
crypt="$repo/docs/dev.tar.gpg"
stamp="$(git -C "$repo" rev-parse --absolute-git-dir)/fluid-docs.hash"

command -v gpg >/dev/null || { echo "docs: gpg is missing (Arch: gnupg, macOS: brew install gnupg)" >&2; exit 1; }

# Content hash of the plaintext (git's own hashing, same on Linux and macOS)
hash_plain() {
    [ -d "$plain" ] || { echo none; return; }
    (cd "$plain" && find . -type f ! -name .DS_Store | LC_ALL=C sort | while IFS= read -r f; do
        printf '%s %s\n' "$(git hash-object "$f")" "$f"
    done) | git hash-object --stdin
}

ask_password() {   # $1 = prompt; reads from the terminal even inside git hooks
    local pw
    IFS= read -rsp "$1" pw </dev/tty; echo >/dev/tty
    printf '%s' "$pw"
}

gpg_run() {        # $1 = password, rest = gpg args; password goes through a pipe, never argv or disk
    local pw="$1"; shift
    gpg --batch --yes --quiet --no-symkey-cache --pinentry-mode loopback --passphrase-fd 3 "$@" 3< <(printf '%s' "$pw")
}

use_hooks() {
    [ "$(git -C "$repo" config core.hooksPath || true)" = .githooks ] && return
    git -C "$repo" config core.hooksPath .githooks
    echo "docs: git hooks enabled (.githooks)"
}

lock() {
    [ -d "$plain" ] || { echo "docs: nothing to encrypt, $plain is missing" >&2; exit 1; }
    local pw pw2
    pw="$(ask_password "Password for the docs: ")"
    pw2="$(ask_password "Again: ")"
    [ "$pw" = "$pw2" ] || { echo "docs: passwords don't match" >&2; exit 1; }
    [ -n "$pw" ] || { echo "docs: empty password" >&2; exit 1; }
    COPYFILE_DISABLE=1 tar -C "$repo/docs" --exclude .DS_Store -cf - dev \
        | gpg_run "$pw" --symmetric --cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65011712 -o "$crypt.tmp"
    mv "$crypt.tmp" "$crypt"
    hash_plain > "$stamp"
    use_hooks
    echo "docs: encrypted -> docs/dev.tar.gpg"
}

unlock() {
    [ -f "$crypt" ] || { echo "docs: $crypt doesn't exist yet" >&2; exit 1; }
    if [ -d "$plain" ] && [ "$(hash_plain)" != "$(cat "$stamp" 2>/dev/null)" ]; then
        local a
        read -rp "docs/dev/ has changes that aren't encrypted yet; overwrite them? [y/N] " a </dev/tty
        [[ "$a" =~ ^[yY] ]] || { echo "docs: kept your local docs (run 'docs/docs.sh lock' to save them)"; exit 0; }
    fi
    local pw
    pw="$(ask_password "Password for the docs: ")"
    tmp="$(mktemp -d)"     # global: the EXIT trap runs after this function returns
    trap 'rm -rf "$tmp"' EXIT
    if ! gpg_run "$pw" --decrypt "$crypt" | tar -C "$tmp" -xf -; then
        echo "docs: wrong password or damaged file" >&2; exit 1
    fi
    rm -rf "$plain"
    mv "$tmp/dev" "$plain"
    hash_plain > "$stamp"
    use_hooks
    echo "docs: decrypted -> docs/dev/"
}

case "${1:-}" in
    lock) lock ;;
    unlock) unlock ;;
    status) [ "$(hash_plain)" = "$(cat "$stamp" 2>/dev/null)" ] && echo unchanged || echo changed ;;
    hooks) use_hooks ;;
    *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
