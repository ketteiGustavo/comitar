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

INSTALLER_VERSION="2.0.0"
REPO_URL="https://github.com/ketteiGustavo/comitar.git"
COMITAR_DIR="$HOME/.comitar"
BIN_TARGET="$HOME/.local/bin"
SHELL_RC=""

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
  $QUIET || echo -e "${BLUE}🔧 Instalando dependências com sudo...${NC}"
  if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y jq git
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y jq git
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm jq git
  else
    $QUIET || echo -e "${YELLOW}⚠ Gerenciador de pacotes não detectado. Instale manualmente: jq git${NC}"
  fi
}

check_dependencies() {
    if [[ "$FULL_INSTALL" == true ]]; then
        install_dependencies
    fi

    if ! command -v git &>/dev/null; then
        echo -e "${RED}❌ O 'git' é um requisito para a instalação, mas não foi encontrado.${NC}"
        echo -e "${YELLOW}💡 Instale o 'git' manualmente ou rode o instalador com a flag --full.${NC}"
        exit 1
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}❌ O 'jq' é um requisito para a instalação, mas não foi encontrado.${NC}"
        echo -e "${YELLOW}💡 Instale o 'jq' manualmente ou rode o instalador com a flag --full.${NC}"
        exit 1
    fi
}

install_repo() {
    $QUIET || echo -e "${BLUE}📁 Clonando repositório de $REPO_URL...${NC}"
    if [[ -d "$COMITAR_DIR" ]]; then
        $QUIET || echo -e "${YELLOW}⚠ Diretório $COMITAR_DIR já existe. Fazendo backup para $COMITAR_DIR.bak ...${NC}"
        mv "$COMITAR_DIR" "$COMITAR_DIR.bak.$(date +%s)"
    fi
    mkdir -p "$BIN_TARGET"
    git clone --depth=1 "$REPO_URL" "$COMITAR_DIR"
    $QUIET || echo -e "${GREEN}✔ Repositório clonado com sucesso!${NC}"
}

set_permissions() {
    $QUIET || echo -e "${BLUE}🔐 Configurando permissões dos scripts...${NC}"
    chmod +x "$COMITAR_DIR"/bin/*
    chmod +x "$COMITAR_DIR"/tools/*
    chmod +x "$COMITAR_DIR"/hooks/*
    chmod +x "$COMITAR_DIR"/run_tests.sh
}

install_man_page() {
    $QUIET || echo -e "\n${YELLOW}➡ Instalando manual...${NC}"
    if sudo -v &>/dev/null; then
        sudo mkdir -p /usr/local/man/man1
        if sudo cp "$COMITAR_DIR/man/comitar.1" /usr/local/man/man1/comitar.1 && sudo mandb /usr/local/man &>/dev/null; then
            $QUIET || echo -e "${GREEN}✔ Manual instalado com sucesso${NC}"
        else
            $QUIET || echo -e "${RED}⚠ Falha ao instalar o manual.${NC}"
        fi
    else
      $QUIET || echo -e "${YELLOW}⚠ Não foi possível instalar o manual (sem permissão de sudo).${NC}"
    fi
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
  $QUIET || echo -e "${YELLOW}📦 Instalando autocomplete...${NC}"
  local AUTOCOMPLETE_FILE="$COMITAR_DIR/tools/comitar-autocomplete"

  if [[ -n "$ZSH_VERSION" || "$SHELL" =~ zsh ]]; then
    local ZSH_COMPLETION="$HOME/.zshrc"
    if ! grep -q "$AUTOCOMPLETE_FILE" "$ZSH_COMPLETION"; then
      echo "source $AUTOCOMPLETE_FILE" >> "$ZSH_COMPLETION"
      $QUIET || echo -e "${GREEN}✔ Autocomplete configurado para Zsh${NC}"
    fi
    source "$AUTOCOMPLETE_FILE"
  elif [[ -n "$BASH_VERSION" || "$SHELL" =~ bash ]]; then
    local BASH_COMPLETION="$HOME/.bash_completion"
    if ! grep -q "$AUTOCOMPLETE_FILE" "$BASH_COMPLETION" 2>/dev/null; then
      echo "source $AUTOCOMPLETE_FILE" >> "$BASH_COMPLETION"
      $QUIET || echo -e "${GREEN}✔ Autocomplete configurado para Bash${NC}"
    fi
    source "$AUTOCOMPLETE_FILE"
  else
    $QUIET || echo -e "${YELLOW}⚠️ Shell não suportado automaticamente. Adicione manualmente:\nsource $AUTOCOMPLETE_FILE${NC}"
  fi
}

final_message() {
  $QUIET || echo -e "\n${GREEN}🎉 Instalação concluída com sucesso!${NC}"
  if [[ -n "$SHELL_RC" ]]; then
    $QUIET || echo -e "${YELLOW}⚙ Para que as mudanças tenham efeito, reinicie seu terminal ou execute:${NC}"
    $QUIET || echo -e "   ${BOLD}source $SHELL_RC${NC}"
  fi
  $QUIET || echo -e "\n${CYAN}🚀 Agora você pode usar:${NC}"
  $QUIET || echo -e "   comitar --commit"
  $QUIET || ([[ "$ADD_ALIAS" == true ]] && echo "   ou simplesmente: cmt")
}

main() {
  test_colors
  parse_args "$@"
  detect_shell
  check_dependencies
  install_repo
  set_permissions
  create_symlink
  add_path_and_alias
  install_autocomplete
  install_man_page
  final_message
}


main "$@"
