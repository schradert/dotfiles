#!/bin/bash

# Nix Store Lock Cleaner
# Finds and optionally removes stale lock files in /nix/store

set -euo pipefail

NIX_STORE="/nix/store"
DRY_RUN=${1:-"--dry-run"}

if [[ ! -d "$NIX_STORE" ]]; then
    echo "Error: $NIX_STORE not found"
    exit 1
fi

echo "Scanning for stale lock files in $NIX_STORE..."
echo

stale_locks=()

# Find all .lock files in /nix/store
while IFS= read -r -d '' lock_file; do
    # Get the path this lock is supposed to protect
    target_path="${lock_file%.lock}"

    # Check if the lock file is empty (indicating stale lock)
    if [[ ! -s "$lock_file" ]]; then
        if [[ ! -e "$target_path" ]]; then
            echo "STALE (no target): $lock_file -> $target_path"
        else
            echo "STALE (empty lock): $lock_file"
        fi
        stale_locks+=("$lock_file")
    else
        # Non-empty lock file - could be active
        if [[ ! -e "$target_path" ]]; then
            echo "SUSPICIOUS (non-empty, no target): $lock_file"
            # You might want to add these to stale_locks too, but being more cautious
            # stale_locks+=("$lock_file")
        fi
    fi
done < <(find "$NIX_STORE" -maxdepth 1 -name "*.lock" -print0)

echo
echo "Found ${#stale_locks[@]} stale lock files"

if [[ ${#stale_locks[@]} -eq 0 ]]; then
    echo "No stale locks found!"
    exit 0
fi

if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo
    echo "DRY RUN - would remove these locks:"
    printf '%s\n' "${stale_locks[@]}"
    echo
    echo "Run with '--remove' to actually delete them:"
    echo "  $0 --remove"
elif [[ "$DRY_RUN" == "--remove" ]]; then
    echo
    echo "Remounting /nix/store as read-write..."
    if ! sudo mount -o remount,rw,bind "$NIX_STORE" 2>/dev/null; then
        echo "Warning: Could not remount $NIX_STORE as RW (might already be RW)"
    fi

    echo "Removing stale locks..."
    removed=0

    # Remove all locks in one command for efficiency
    if [[ ${#stale_locks[@]} -gt 0 ]]; then
        if sudo rm -f "${stale_locks[@]}" 2>/dev/null; then
            echo "  Removed all ${#stale_locks[@]} stale locks"
            removed=${#stale_locks[@]}
        else
            # Fallback: remove one by one to see which ones fail
            echo "  Batch removal failed, trying individually..."
            for lock in "${stale_locks[@]}"; do
                if sudo rm -f "$lock" 2>/dev/null; then
                    echo "  Removed: $lock"
                    ((removed++))
                else
                    echo "  Failed to remove: $lock"
                fi
            done
        fi
    fi

    echo
    echo "Successfully removed $removed/${#stale_locks[@]} stale locks"

    # Attempt to remount as read-only (may fail on some systems)
    if ! sudo mount -o remount,ro,bind "$NIX_STORE" 2>/dev/null; then
        echo "Note: Could not remount $NIX_STORE as read-only"
    fi
else
    echo
    echo "Usage:"
    echo "  $0 [--dry-run|--remove]"
    echo
    echo "  --dry-run  : Show what would be removed (default)"
    echo "  --remove   : Actually remove the stale locks"
fi
