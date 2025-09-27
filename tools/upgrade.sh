#!/usr/bin/env bash
################################################################################
# upgrade.sh - Atualizador oficial do COMITAR
# Fonte: https://github.com/ketteiGustavo/comitar
################################################################################

set -e

COMITAR_DIR="$HOME/.comitar"
SHELL_RC=""


test_colors() {
  if [ "$(tput colors 2>/dev/null)" -ge 8 ]; then
    RED="\e[31m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    BLUE="\e[34m"
    MAGENTA="\e[35m"
    CYAN="\e[36m"
    GRAY="\e[37m"
    BOLD="\e[1m"
    BLINK="\e[5m"
    NC="\e[0m"   # no_color
  else
    USE_COLORS=0
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    GRAY=""
    BOLD=""
    BLINK=""
    NC=""
  fi
}
test_colors

detect_shell() {
  if [[ $SHELL =~ bash ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ $SHELL =~ zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ $SHELL =~ fish ]]; then
    SHELL_RC="$HOME/.config/fish/config.fish"
  else
    SHELL_RC=""
  fi
}

echo -e "${CYAN}${BOLD}🔄 Iniciando atualização do COMITAR...${NC}"

if [[ ! -d "$COMITAR_DIR/.git" ]]; then
  echo -e "${RED}❌ Instalação do Comitar não encontrada ou não é um repositório git.${NC}"
  echo -e "${YELLOW}💡 Por favor, reinstale usando o script de instalação mais recente.${NC}"
  exit 1
fi

set_permissions() {
    $QUIET || echo -e "${BLUE}🔐 Configurando permissões dos scripts...${NC}"
    # Torna todos os scripts .sh executáveis
    find "$COMITAR_DIR" -type f -name "*.sh" -exec chmod +x {} +
    # Torna executáveis os scripts que não têm extensão .sh
    chmod +x "$COMITAR_DIR"/bin/comitar
    chmod +x "$COMITAR_DIR"/hooks/commit-check
    chmod +x "$COMITAR_DIR"/tools/comitar-autocomplete
}

echo "➡ Sincronizando com o repositório oficial..."
(
  cd "$COMITAR_DIR"
  # Garante que o remote 'origin' está configurado corretamente
  git remote set-url origin https://github.com/ketteiGustavo/comitar.git &>/dev/null || git remote add origin https://github.com/ketteiGustavo/comitar.git &>/dev/null
  # Busca as últimas alterações do branch main
  git fetch origin main &>/dev/null
  # Reseta o repositório local para ser um espelho exato do remoto, descartando alterações locais
  git reset --hard origin/main &>/dev/null
)

echo -e "\n${YELLOW}➡ Verificando manual...${NC}"
if sudo -v &>/dev/null; then
    MAN_SOURCE_DIR="$COMITAR_DIR/man"
    MAN_DEST_DIR="/usr/local/man/man1"
    needs_update=false

    sudo mkdir -p "$MAN_DEST_DIR"

    if ! sudo diff -q "$MAN_SOURCE_DIR/comitar.1" "$MAN_DEST_DIR/comitar.1" >/dev/null 2>&1; then
        needs_update=true
    fi

    if [ ! -e "$MAN_DEST_DIR/cmt.1" ]; then
        needs_update=true
    fi

    if [[ "$needs_update" == true ]]; then
        echo -e "${CYAN}   Atualizando arquivos de manual...${NC}"
        if sudo cp "$MAN_SOURCE_DIR"/* "$MAN_DEST_DIR/" && sudo mandb &>/dev/null; then
            echo -e "${GREEN}✔ Manual atualizado com sucesso${NC}"
        else
            echo -e "${RED}⚠ Falha ao atualizar o manual.${NC}"
        fi
    else
        echo -e "${GREEN}✔ Manual já está atualizado.${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Não foi possível verificar o manual (sem permissão de sudo).${NC}"
fi

detect_shell
set_permissions

echo -e "\n${GREEN}${BOLD}✅ Atualização concluída com sucesso!${NC}"
echo -e "${CYAN}🚀 Use ${BOLD}comitar news${NC} para ver as novidades."

if [[ -n "$SHELL_RC" ]]; then
  echo -e "\n${YELLOW}⚙ Para que as mudanças tenham efeito, reinicie seu terminal ou execute:${NC}"
  echo -e "   ${BOLD}source $SHELL_RC${NC}"
fi
