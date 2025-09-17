#!/usr/bin/env bash
################################################################################
# upgrade.sh - Atualizador oficial do COMITAR
# Fonte: https://github.com/ketteiGustavo/comitar
################################################################################

set -e

REPO_RAW="https://raw.githubusercontent.com/ketteiGustavo/comitar/main"
COMITAR_DIR="$HOME/.comitar"

BIN_DIR="$COMITAR_DIR/bin"
CONFIG_DIR="$COMITAR_DIR/config"
HOOKS_DIR="$COMITAR_DIR/hooks"
MAN_DIR="$COMITAR_DIR/man"
TOOLS_DIR="$COMITAR_DIR/tools"
SHELL_RC=""

# Cores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"
BOLD="\e[1m"
BLINK="\e[5m"

# Detecta shell atual para mensagem final
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

# Pede senha do sudo no início para evitar problemas
echo -e "${CYAN}Para instalar o manual, pode ser necessário privilégio de administrador.${NC}"
sudo -v

# Atualiza binário principal
echo -e "${YELLOW}➡ Atualizando binário...${NC}"
curl -fsSL "$REPO_RAW/bin/comitar" -o "$BIN_DIR/comitar"
chmod +x "$BIN_DIR/comitar"

# Atualiza configuração apenas se não modificada
if curl -fsSL "$REPO_RAW/config/comitar.json" -o "$CONFIG_DIR/comitar.json.default"; then
  echo -e "${GREEN}✔ Configuração padrão atualizada (comitar.json.default)${NC}"
else
  echo -e "${RED}❌ Falha ao atualizar configuração padrão${NC}"
fi

# Atualiza hooks
echo -e "${YELLOW}➡ Atualizando hooks...${NC}"
curl -fsSL "$REPO_RAW/hooks/commit-check" -o "$HOOKS_DIR/commit-check"
chmod +x "$HOOKS_DIR/commit-check"

# Atualiza manpage
echo -e "${YELLOW}➡ Atualizando manual...${NC}"
curl -fsSL "$REPO_RAW/man/comitar.1" -o "$MAN_DIR/comitar.1"

# Copia manual para diretório global
echo -e "${YELLOW}➡ Copiando manual para /usr/local/man/man1...${NC}"
sudo mkdir -p /usr/local/man/man1
if sudo cp "$MAN_DIR/comitar.1" /usr/local/man/man1/comitar.1 && sudo mandb /usr/local/man &>/dev/null; then
    echo -e "${GREEN}✔ Manual atualizado com sucesso${NC}"
else
    echo -e "${RED}⚠ Falha ao instalar o manual.${NC}"
    echo -e "${YELLOW}💡 Tente executar manualmente:${NC}"
    echo -e "${CYAN}   sudo mkdir -p /usr/local/man/man1 ${NC}"
    echo -e "${CYAN}   sudo cp $MAN_DIR/comitar.1 /usr/local/man/man1/ ${NC}"
    echo -e "${CYAN}   sudo mandb /usr/local/man ${NC}"
fi


# Atualiza changelog
echo -e "${YELLOW}➡ Atualizando changelog...${NC}"
curl -fsSL "$REPO_RAW/changelog.md" -o "$COMITAR_DIR/changelog.md"

# Atualiza ferramentas auxiliares
for script in upgrade.sh uninstall.sh changelog.sh comitar-autocomplete; do
  echo -e "${YELLOW}➡ Atualizando tools/$script...${NC}"
  curl -fsSL "$REPO_RAW/tools/$script" -o "$TOOLS_DIR/$script"
  chmod +x "$TOOLS_DIR/$script"
done

detect_shell

echo -e "\n${GREEN}${BOLD}✅ Atualização concluída com sucesso!${NC}"
echo -e "${CYAN}🚀 Use ${BOLD}comitar news${NC} para ver as novidades."

if [[ -n "$SHELL_RC" ]]; then
  echo -e "\n${YELLOW}⚙ Para que as mudanças (como o autocomplete) tenham efeito, reinicie seu terminal ou execute:${NC}"
  echo -e "   ${BOLD}source $SHELL_RC${NC}
fi