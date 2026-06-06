#!/usr/bin/env bash
# Compare the mod versions pinned in packwiz (.pw.toml) against the latest
# available on Modrinth / CurseForge for this pack's Minecraft + loader.
#
# Read-only: this NEVER edits .pw.toml. To actually apply updates, use
# `packwiz update --all`. This is just a "what's stale?" report.
#
# Modrinth checks need no API key. CurseForge checks require a key:
#   export CF_API_KEY=... ; ./scripts/check-updates.sh
# Without it, CurseForge mods are listed as SKIPPED.
#
# Requires: curl, jq.
#
# Usage:
#   ./scripts/check-updates.sh            # all mods
#   ./scripts/check-updates.sh -u         # only show mods with updates
#   ./scripts/check-updates.sh mods/foo.pw.toml ...  # specific files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

command -v curl >/dev/null || { echo "ERROR: curl not on PATH" >&2; exit 1; }
command -v jq   >/dev/null || { echo "ERROR: jq not on PATH" >&2; exit 1; }

UA="underpunks-create-age/check-updates (github)"

MC=$(grep '^minecraft = ' pack.toml | sed 's/.*"\(.*\)"/\1/')
# Loader = whichever loader key appears under [versions] (neoforge/forge/fabric/quilt).
LOADER=$(grep -E '^(neoforge|forge|fabric|quilt) = ' pack.toml | head -1 | sed 's/ .*//')
echo ">> Pack target: Minecraft $MC, loader $LOADER"
[[ -z "${CF_API_KEY:-}" ]] && echo ">> CF_API_KEY not set: CurseForge mods will be SKIPPED"
echo ""

UPDATES_ONLY=0
FILES=()
for arg in "$@"; do
  case "$arg" in
    -u|--updates-only) UPDATES_ONLY=1 ;;
    *) FILES+=("$arg") ;;
  esac
done
[[ ${#FILES[@]} -eq 0 ]] && FILES=(mods/*.pw.toml)

n_update=0 n_ok=0 n_skip=0
cf_skipped=()  # "name|project-id" for mods we couldn't check (manual lookup list)

# read a `key = "value"` line out of a toml file
tget() { grep -E "^$2 = " "$1" | head -1 | sed 's/.*= *//; s/^"//; s/"$//'; }

printf "%-44s %-20s %-20s %s\n" "MOD" "INSTALLED" "LATEST" "STATUS"
printf '%.0s-' {1..100}; echo

for f in "${FILES[@]}"; do
  name=$(tget "$f" name)

  if grep -q '\[update.modrinth\]' "$f"; then
    proj=$(tget "$f" mod-id)
    cur=$(tget "$f" version)   # this is the installed *version id*
    resp=$(curl -fsS --get \
      -H "User-Agent: $UA" \
      --data-urlencode "game_versions=[\"$MC\"]" \
      --data-urlencode "loaders=[\"$LOADER\"]" \
      "https://api.modrinth.com/v2/project/$proj/version" 2>/dev/null) || resp="[]"
    latest_id=$(jq -r '.[0].id // empty' <<<"$resp")
    latest_no=$(jq -r '.[0].version_number // "?"' <<<"$resp")
    cur_no=$(jq -r --arg id "$cur" '.[] | select(.id==$id) | .version_number' <<<"$resp")
    cur_no=${cur_no:-$cur}
    if [[ -z "$latest_id" ]]; then
      status="NO MATCH (no $LOADER/$MC build)"
    elif [[ "$latest_id" == "$cur" ]]; then
      status="ok"; n_ok=$((n_ok+1))
    else
      status="UPDATE"; n_update=$((n_update+1))
    fi

  elif grep -q '\[update.curseforge\]' "$f"; then
    latest_no="-"; cur_no=$(tget "$f" filename)
    proj=$(tget "$f" project-id)
    if [[ -z "${CF_API_KEY:-}" ]]; then
      status="SKIPPED (no CF key)"; n_skip=$((n_skip+1))
      cf_skipped+=("$name|$proj")
    else
      curfile=$(tget "$f" file-id)
      # modLoaderType: 1=Forge 4=Fabric 5=Quilt 6=NeoForge
      case "$LOADER" in neoforge) lt=6;; forge) lt=1;; fabric) lt=4;; quilt) lt=5;; *) lt=6;; esac
      resp=$(curl -fsS -H "x-api-key: $CF_API_KEY" -H "Accept: application/json" \
        "https://api.curseforge.com/v1/mods/$proj/files?gameVersion=$MC&modLoaderType=$lt&pageSize=1" 2>/dev/null) || resp='{}'
      latest_file=$(jq -r '.data[0].id // empty' <<<"$resp")
      latest_no=$(jq -r '.data[0].fileName // "?"' <<<"$resp")
      if [[ -z "$latest_file" ]]; then
        status="NO MATCH"
      elif [[ "$latest_file" == "$curfile" ]]; then
        status="ok"; n_ok=$((n_ok+1))
      else
        status="UPDATE"; n_update=$((n_update+1))
      fi
    fi
  else
    status="no update source"; cur_no="-"; latest_no="-"
  fi

  if [[ $UPDATES_ONLY -eq 1 && "$status" == "ok" ]]; then continue; fi
  printf "%-44s %-20.20s %-20.20s %s\n" "$name" "$cur_no" "$latest_no" "$status"
done

echo ""
echo "Summary: $n_update update(s) available, $n_ok up to date, $n_skip skipped."

if [[ ${#cf_skipped[@]} -gt 0 ]]; then
  echo ""
  echo "CurseForge mods to check manually (open link, compare to installed file):"
  for entry in "${cf_skipped[@]}"; do
    cf_name=${entry%%|*}; cf_id=${entry##*|}
    # /projects/<id> redirects to the mod's CurseForge page
    printf "  %-42s https://www.curseforge.com/projects/%s\n" "$cf_name" "$cf_id"
  done
  echo ""
  echo "Tip: set CF_API_KEY (https://console.curseforge.com) to automate these."
fi
echo "To apply updates: packwiz update --all"
