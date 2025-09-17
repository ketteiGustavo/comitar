#!/usr/bin/env bash
################################################################################
# install.sh - Instalador oficial do COMITAR
#
# Instalação via:
#   curl -fsSL https://raw.githubusercontent.com/ketteiGustavo/comitar/main/tools/install.sh | bash
#
# DATA: 25/07/2025
# -------------------------------------------------------------------------------
# Autor: Luiz Gustavo <luizg.devlx@gmail.com>
################################################################################

set -e

INSTALLER_VERSION="1.0.0"
REPO_RAW="https://raw.githubusercontent.com/ketteiGustavo/comitar/main"
COMITAR_DIR="$HOME/.comitar"
BIN_TARGET="$HOME/.local/bin"
CONFIG_DIR="$COMITAR_DIR/config"
HOOKS_DIR="$COMITAR_DIR/hooks"
TOOLS_DIR="$COMITAR_DIR/tools"
MAN_DIR="$COMITAR_DIR/man"

ADD_ALIAS=true
FULL_INSTALL=false
QUIET=false


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

print_help() {
  printf "${BOLD}COMITAR - Commits padronizados com Conventional Commits + Hook\n\n${NC}"
  printf "${CYAN}USO:${NC}\n"
  printf "  bash install.sh [opções]\n\n"
  printf "${CYAN}OPÇÕES:${NC}\n"
  printf "  -h, --help         Exibe esta ajuda e sai\n"
  printf "  -V, --version      Exibe a versão do instalador\n"
  printf "  --full             Instala dependências (jq, git) com sudo\n"
  printf "  --no-alias         Não adiciona alias 'cmt' ao shell\n"
  printf "  --quiet            Modo silencioso (oculta mensagens)\n\n"
  printf "${CYAN}EXEMPLO:${NC}\n"
  printf "  curl -fsSL https://raw.githubusercontent.com/ketteiGustavo/comitar/main/tools/install.sh | bash -s -- --full\n\n"
  exit 0
}

print_version() {
  echo -e "COMITAR install.sh v$INSTALLER_VERSION"
  exit 0
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help) print_help;;
      -V | --version) print_version ;;
      --no-alias) ADD_ALIAS=false ;;
      --full) FULL_INSTALL=true ;;
      --quiet) QUIET=true ;;
      --install-dir) BIN_TARGET="$2"; shift ;;
      *)
        echo -e "${RED}❌ Argumento inválido:${NC} $1"
        echo "Use --help para ver as opções disponíveis."
        exit 1
        ;;
    esac
    shift
  done
}


# Detecta shell atual
detect_shell() {
  if [[ $SHELL =~ bash ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ $SHELL =~ zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ $SHELL =~ fish ]]; then
    SHELL_RC="$HOME/.config/fish/config.fish"
  else
    echo -e "${YELLOW}⚠ Shell não reconhecido. Adicione o PATH manualmente ao seu shell.${NC}"
    SHELL_RC=""
  fi
}

install_dependencies() {
  echo -e "${BLUE}🔧 Instalando dependências com sudo...${NC}"
  if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y jq git
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y jq git
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm jq git
  else
    echo -e "${YELLOW}⚠ Gerenciador de pacotes não detectado. Instale manualmente: jq git${NC}"
  fi
}

create_directories() {
  $QUIET || echo -e "${BLUE}📁 Criando diretórios em $COMITAR_DIR...${NC}"
  mkdir -p "$COMITAR_DIR" "$BIN_TARGET" "$CONFIG_DIR" "$HOOKS_DIR" "$TOOLS_DIR" "$MAN_DIR"
}


download_files() {
  $QUIET || echo -e "${GREEN}⬇ Baixando arquivos...${NC}"

  mkdir -p "$COMITAR_DIR/bin"
  curl -fsSL "$REPO_RAW/bin/comitar" -o "$COMITAR_DIR/bin/comitar"
  chmod +x "$COMITAR_DIR/bin/comitar"

  curl -fsSL "$REPO_RAW/config/comitar.json" -o "$CONFIG_DIR/comitar.json"
  curl -fsSL "$REPO_RAW/hooks/commit-check" -o "$HOOKS_DIR/commit-check"
  chmod +x "$HOOKS_DIR/commit-check"

  curl -fsSL "$REPO_RAW/man/comitar.1" -o "$MAN_DIR/comitar.1"
  curl -fsSL "$REPO_RAW/changelog.md" -o "$COMITAR_DIR/changelog.md"

  for script in upgrade.sh uninstall.sh changelog.sh comitar-autocomplete; do
    $QUIET || echo -e "${CYAN}📥 tools/$script${NC}"
    curl -fsSL "$REPO_RAW/tools/$script" -o "$TOOLS_DIR/$script"
    chmod +x "$TOOLS_DIR/$script"
  done
}

create_symlink() {
  $QUIET || echo -e "${BLUE}🔗 Criando symlink em $BIN_TARGET/comitar...${NC}"
  ln -sf "$COMITAR_DIR/bin/comitar" "$BIN_TARGET/comitar"
}

add_path_and_alias() {
  if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q "$BIN_TARGET" "$SHELL_RC"; then
      echo "export PATH=\"\$PATH:$BIN_TARGET\"" >> "$SHELL_RC"
      $QUIET || echo -e "${GREEN}✔ PATH atualizado em $SHELL_RC${NC}"
    fi

    if [[ "$ADD_ALIAS" == true ]] && ! grep -q "alias cmt=" "$SHELL_RC"; then
      echo "alias cmt='$BIN_TARGET/comitar'" >> "$SHELL_RC"
      $QUIET || echo -e "${GREEN}✔ Alias 'cmt' adicionado a $SHELL_RC${NC}"
    fi
  fi
}

install_autocomplete() {
  echo -e "${YELLOW}📦 Instalando autocomplete...${NC}"
  AUTOCOMPLETE_FILE="$TOOLS_DIR/comitar-autocomplete"

  if [[ -n "$ZSH_VERSION" || "$SHELL" =~ zsh ]]; then
    # Zsh
    ZSH_COMPLETION="$HOME/.zshrc"
    if ! grep -q "$AUTOCOMPLETE_FILE" "$ZSH_COMPLETION"; then
      echo "source $AUTOCOMPLETE_FILE" >> "$ZSH_COMPLETION"
      echo -e "${GREEN}✔ Autocomplete configurado para Zsh${NC}"
    fi
    source "$AUTOCOMPLETE_FILE"
  elif [[ -n "$BASH_VERSION" || "$SHELL" =~ bash ]]; then
    # Bash
    BASH_COMPLETION="$HOME/.bash_completion"
    if ! grep -q "$AUTOCOMPLETE_FILE" "$BASH_COMPLETION" 2>/dev/null; then
      echo "source $AUTOCOMPLETE_FILE" >> "$BASH_COMPLETION"
      echo -e "${GREEN}✔ Autocomplete configurado para Bash${NC}"
    fi
    source "$AUTOCOMPLETE_FILE"
  else
    echo -e "${YELLOW}⚠️ Shell não suportado automaticamente. Adicione manualmente:${NC}"
    echo "source $AUTOCOMPLETE_FILE"
  fi
}

final_message() {
  echo -e "\n${GREEN}🎉 Instalação concluída com sucesso!${NC}"
  echo "⚙ Reinicie o terminal ou execute:"
  echo "   source $SHELL_RC"
  echo ""
  echo "🚀 Assim você poderá usar:"
  echo "   comitar --commit"
  echo "   ou simplesmente: cmt"
}

main() {
  parse_args "$@"
  detect_shell
  $FULL_INSTALL && install_dependencies
  create_directories
  download_files
  create_symlink
  add_path_and_alias
  install_autocomplete
  final_message
}


main "$@"
