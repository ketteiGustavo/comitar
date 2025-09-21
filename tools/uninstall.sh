#!/usr/bin/env bash
################################################################################
# uninstall.sh - Desinstalador oficial do COMITAR
# Fonte: https://github.com/ketteiGustavo/comitar
################################################################################

set -e

COMITAR_DIR="$HOME/.comitar"
BIN_TARGET="$HOME/.local/bin/comitar"
SHELL_RC=""
MANPAGE_PATHS=("/usr/local/man/man1/comitar.1" "/usr/local/man/man1/cmt.1")

# Cores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"
BOLD="\e[1m"

# Detecta shell atual
detect_shell() {
  if [[ $SHELL =~ bash ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ $SHELL =~ zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ $SHELL =~ fish ]]; then
    SHELL_RC="$HOME/.config/fish/config.fish"
  fi
}

confirm_uninstall() {
  echo -e "${YELLOW}${BOLD}⚠ Tem certeza que deseja remover o COMITAR?${NC}"
  read -r -p "Digite 'sim' para confirmar: " confirmation
  if [[ "$confirmation" != "sim" ]]; then
    echo -e "${CYAN}❎ Desinstalação cancelada.${NC}"
    exit 0
  fi
}

remove_files() {
  echo -e "${YELLOW}🧹 Removendo arquivos...${NC}"

  if [[ -d "$COMITAR_DIR" ]]; then
    rm -rf "$COMITAR_DIR"
    echo -e "${GREEN}✔ Diretório $COMITAR_DIR removido.${NC}"
  fi

  if [[ -f "$BIN_TARGET" ]]; then
    rm -f "$BIN_TARGET"
    echo -e "${GREEN}✔ Binário $BIN_TARGET removido.${NC}"
  fi

  if [[ -f "${MANPAGE_PATHS[0]}" ]]; then
    sudo rm -f "${MANPAGE_PATHS[@]}" && sudo mandb /usr/local/man &>/dev/null
    echo -e "${GREEN}✔ Manuais removidos de /usr/local/man/man1/${NC}"
  fi
}

remove_alias_from_rc() {
  if [[ -n "$SHELL_RC" && -f "$SHELL_RC" ]]; then
    sed -i '/alias cmt=/d' "$SHELL_RC"
    sed -i '/alias comitar=/d' "$SHELL_RC"
    sed -i '\|.local/bin|d' "$SHELL_RC"
    echo -e "${GREEN}✔ Alias e PATH removidos de $SHELL_RC${NC}"
  fi
}

remove_auto_complete() {
  if [[ -n "$SHELL_RC" && -f "$SHELL_RC" ]]; then
    sed -i '\|comitar-autocomplete|d' "$SHELL_RC"
    echo -e "${GREEN}✔ Autocomplete removido de $SHELL_RC${NC}"
  fi
}

final_message() {
  echo -e "\n${CYAN}${BOLD}🧼 COMITAR foi desinstalado com sucesso.${NC}"
  echo -e "${YELLOW}⚙ Reinicie seu terminal ou execute:${NC}"
  echo -e "${CYAN}   source $SHELL_RC${NC}"
}

main() {
  detect_shell
  confirm_uninstall
  remove_files
  remove_alias_from_rc
  remove_auto_complete
  final_message
}

main "$@"
