#!/usr/bin/env bash
################################################################################
# upgrade.sh - Atualizador oficial do COMITAR
# Fonte: https://github.com/ketteiGustavo/comitar
################################################################################

set -e

COMITAR_DIR="$HOME/.comitar"
SHELL_RC=""

# Cores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"
BOLD="\e[1m"

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

echo "➡ Sincronizando com o repositório oficial..."
(
  cd "$COMITAR_DIR"
  # Garante que o remote 'origin' está configurado corretamente
  git remote set-url origin https://github.com/ketteiGustavo/comitar.git &>/dev/null || git remote add origin https://github.com/ketteiGustavo/comitar.git &>/dev/null
  # Busca as últimas alterações do branch main
  git fetch origin main
  # Reseta o repositório local para ser um espelho exato do remoto, descartando alterações locais
  git reset --hard origin/main
)

echo -e "\n${YELLOW}➡ Atualizando manual...${NC}"
if sudo -v &>/dev/null; then
    sudo mkdir -p /usr/local/man/man1
    if sudo cp "$COMITAR_DIR/man/comitar.1" /usr/local/man/man1/comitar.1 && sudo mandb /usr/local/man &>/dev/null; then
        echo -e "${GREEN}✔ Manual atualizado com sucesso${NC}"
    else
        echo -e "${RED}⚠ Falha ao atualizar o manual.${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Não foi possível atualizar o manual (sem permissão de sudo).${NC}"
fi

detect_shell

echo -e "\n${GREEN}${BOLD}✅ Atualização concluída com sucesso!${NC}"
echo -e "${CYAN}🚀 Use ${BOLD}comitar news${NC} para ver as novidades."

if [[ -n "$SHELL_RC" ]]; then
  echo -e "\n${YELLOW}⚙ Para que as mudanças tenham efeito, reinicie seu terminal ou execute:${NC}"
  echo -e "   ${BOLD}source $SHELL_RC${NC}"
fi
