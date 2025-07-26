#!/usr/bin/env bash
################################################################################
# changelog.sh - Gera changelog formatado a partir de commits semânticos
#
# Uso:
#   ./tools/changelog.sh [ATÉ_COMMIT] [DESDE_COMMIT] [--text|--md|--raw]
#
# Exemplos:
#   changelog.sh                    # HEAD até último tag, formato texto
#   changelog.sh HEAD v1.2.0 --md   # HEAD até v1.2.0, formato Markdown
#
# Autor: Luiz Gustavo <luizg.devlx@gmail.com>
################################################################################

set -e

# Configurações
types=(feat fix docs chore refactor test build ci style perf)
main_types=(feat fix docs)
other_types=(refactor test build ci style chore perf)
output="text"
since=""
until="HEAD"

# Detectar argumentos
for arg in "$@"; do
  case "$arg" in
    --text|--md|--raw) output="${arg#--}" ;;
    HEAD|main|master|v*) [[ -z "$until_set" ]] && until="$arg" && until_set=1 || since="$arg" ;;
  esac
done

# Mapeamento de tipo para descrição legível
declare -A type_labels=(
  [feat]="✨ Features"
  [fix]="🐞 Bug Fixes"
  [docs]="📚 Documentation"
  [chore]="🧹 Chores"
  [refactor]="🔨 Refactoring"
  [test]="🧪 Tests"
  [build]="🏗 Build"
  [ci]="🔁 CI"
  [style]="🎨 Style"
  [perf]="⚡ Performance"
  [other]="📦 Other"
)

# Formatação por tipo de saída
format_header() {
  local level="$1"
  local title="$2"
  case "$output" in
    md) printf '%s %s\n\n' "$(head -c "$level" < <(yes '#'))" "$title" ;;
    raw) echo -e "$title\n$(printf '%.0s-' $(seq 1 ${#title}))\n" ;;
    text) echo -e "\033[1m$title\033[0m" ;;
  esac
}

format_entry() {
  local type="$1" scope="$2" msg="$3" hash="$4"

  local prefix=" - "
  local short_hash="${hash:0:7}"
  local scope_fmt=""
  [[ -n "$scope" ]] && scope_fmt="[$scope] "

  case "$output" in
    raw)
      echo "$prefix$scope_fmt$msg ($short_hash)"
      ;;
    md)
      repo_url=$(git remote get-url origin | sed -e 's/\.git$//')
      echo "$prefix$scope_fmt$msg ([`$short_hash`]($repo_url/commit/$hash))"
      ;;
    text)
      echo -e "$prefix$scope_fmt$msg \033[2m($short_hash)\033[0m"
      ;;
  esac
}

# Coleta commits no intervalo
range="${since:+$since..}$until"
commits=$(git log $range --no-merges --pretty=format:'%H|%s|%b')

declare -A sections
declare -A breakings
declare -A reverts

# Processa cada commit
while IFS='|' read -r hash subject body; do
  if [[ "$subject" =~ ^([a-z]+)(\(([^)]+)\))?(!)?:\ (.+) ]]; then
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[3]}"
    msg="${BASH_REMATCH[5]}"
  else
    type="other"
    msg="$subject"
    scope=""
  fi

  # Detecta BREAKING CHANGE
  if echo "$body" | grep -q 'BREAKING CHANGE:' || [[ "$subject" =~ !: ]]; then
    breakings["$hash"]="$msg"
  fi

  # Detecta revert
  if [[ "$subject" =~ ^Revert ]]; then
    if [[ "$body" =~ [Rr]everts commit ([0-9a-f]{7,40}) ]]; then
      reverts["${BASH_REMATCH[1]}"]=1
      continue
    fi
  fi

  # Ignora se foi revertido
  [[ -n "${reverts[$hash]}" ]] && continue

  sections["$type"]+="$hash|$scope|$msg"$'\n'
done <<< "$commits"

# Exibe changelog
format_header 2 "Changelog"

# BREAKING CHANGES
if [[ ${#breakings[@]} -gt 0 ]]; then
  format_header 3 "⚠ Breaking Changes"
  for hash in "${!breakings[@]}"; do
    format_entry "break" "" "${breakings[$hash]}" "$hash"
  done
  echo ""
fi

# Tipos principais
for t in "${main_types[@]}"; do
  [[ -n "${sections[$t]}" ]] || continue
  format_header 3 "${type_labels[$t]}"
  while IFS='|' read -r hash scope msg; do
    [[ -z "$hash" ]] && continue
    format_entry "$t" "$scope" "$msg" "$hash"
  done <<< "${sections[$t]}"
  echo ""
done

# Outros tipos
if [[ "$output" != "md" ]]; then
  format_header 3 "📦 Other Changes"
fi
for t in "${other_types[@]}"; do
  [[ -n "${sections[$t]}" ]] || continue
  while IFS='|' read -r hash scope msg; do
    [[ -z "$hash" ]] && continue
    format_entry "$t" "$scope" "$msg" "$hash"
  done <<< "${sections[$t]}"
done
