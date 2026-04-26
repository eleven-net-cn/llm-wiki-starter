#!/usr/bin/env bash
# llm-wiki-starter — Create an LLM Wiki knowledge base in one command
# Author: eleven-net-cn
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
#   bash install.sh [OPTIONS]
#
# Modes:
#   Default:      Install tools → Create wiki → Install Obsidian plugins
#   --only-tools: Install all tools only (no wiki creation)
#   --only-obsidian: Install Obsidian plugins/themes/config only (merge with existing)
#   --only-wiki:  Create wiki from template only (skip tools installation)
#
# Flow: Detect → Install Tools → Create Wiki → Finalize

set -euo pipefail
export LC_MESSAGES=C

VERSION="1.0.1"
TEMPLATE_REPO="eleven-net-cn/llm-wiki-starter"
TEMPLATE_REPO_URL="https://github.com/$TEMPLATE_REPO"

# ─── State ────────────────────────────────────────────────────────────────────

OS=""
PKG_MGR=""
LOCAL_TEMPLATE=""
NON_INTERACTIVE=false
SKIP_INSTALL=false
WIKI_NAME=""
WIKI_DIR=""
WIKI_LANG=""
WIKI_TARGET=""
TEMPLATE_TMPDIR=""
CLONE_STATUS=""
LLM_WIKI_DIR="${LLM_WIKI_DIR:-}"  # Environment variable for custom wiki location

# Mode flags
ONLY_TOOLS=false
ONLY_OBSIDIAN=false
ONLY_WIKI=false

# Detection flags (set by detect_installed)
HAS_GIT=false
HAS_NODE=false
HAS_BREW=false
HAS_OBSIDIAN=false
HAS_CLAUDE_CODE=false
HAS_OBSIDIAN_SKILLS=false
HAS_VISUAL_SKILLS=false

# Version strings (set by detect_installed)
VER_GIT=""
VER_NODE=""

# ─── Colors (auto-disable for non-TTY) ───────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
SUCCESS='\033[0;92m'    # bright green (distinct from GREEN)
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
RESET='\033[0m'

[[ ! -t 1 ]] && RED='' GREEN='' SUCCESS='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' DIM='' UNDERLINE='' RESET=''

info()    { printf "${GREEN}→${RESET} %b\n" "$1"; }
success() { printf "${GREEN}✓${RESET} %b\n" "$1"; }
warn()    { printf "${YELLOW}⚠${RESET} %b\n" "$1"; }
fail()    { printf "${RED}✗ %b${RESET}\n" "$1" >&2; exit 1; }
stepn()   { printf "\n${BOLD}${GREEN}[%s/%s]${RESET} ${BOLD}%b${RESET}\n" "$1" "$2" "$3"; }
rel_path() { local p="$1" cwd="$(pwd)"; echo "${p#$cwd/}"; }

# ─── Interactive Prompts (bash 3.2 compatible) ────────────────────────────────

prompt_input() {
  local question="$1" default="$2" result
  if $NON_INTERACTIVE; then echo "$default"; return; fi
  printf "  ${GREEN}>${RESET} ${BOLD}%s${RESET} ${DIM}(Default: %s)${RESET}: " "$question" "$default" >&2
  read -r result < /dev/tty
  echo "${result:-$default}"
}

prompt_confirm() {
  local question="$1" default="${2:-Y}" result lower
  if $NON_INTERACTIVE; then
    [[ "$default" == "Y" ]] && return 0 || return 1
  fi
  if [[ "$default" == "Y" ]]; then
    printf "  ${BOLD}%s${RESET} [${GREEN}Y${RESET}/n]: " "$question"
  else
    printf "  ${BOLD}%s${RESET} [y/${RED}N${RESET}]: " "$question"
  fi
  read -r result < /dev/tty
  result="${result:-$default}"
  lower=$(echo "$result" | tr '[:upper:]' '[:lower:]')
  [[ "$lower" == "y" || "$lower" == "yes" ]]
}

# Prompt wiki name with duplicate detection
prompt_wiki_name() {
  local default_name="$1" result target_dir

  if $NON_INTERACTIVE; then
    echo "$default_name"
    return 0
  fi

  while true; do
    printf "  ${GREEN}>${RESET} ${BOLD}Please enter wiki name${RESET} ${DIM}(Default: %s)${RESET}: " "$default_name" >&2
    read -r result < /dev/tty
    result="${result:-$default_name}"

    # Determine target directory
    if [[ -n "$WIKI_DIR" ]]; then
      target_dir="$WIKI_DIR"
    elif [[ -n "$LLM_WIKI_DIR" ]]; then
      target_dir="$LLM_WIKI_DIR"
    else
      target_dir="$(pwd)/$result"
    fi

    # Check if directory already exists
    if [[ -d "$target_dir" ]]; then
      if [[ -f "$target_dir/CLAUDE.md" ]]; then
        printf "  ${YELLOW}⚠${RESET} Directory ${CYAN}$target_dir${RESET} already contains an LLM Wiki\n" >&2
      else
        printf "  ${YELLOW}⚠${RESET} Directory ${CYAN}$target_dir${RESET} already exists\n" >&2
      fi
      printf "  ${YELLOW}Please choose a different name, or use --dir to specify a different location${RESET}\n" >&2
      # Keep same default, don't suggest new name
      continue
    else
      echo "$result"
      return 0
    fi
  done
}

prompt_language() {
  if [[ -n "$WIKI_LANG" ]]; then echo "$WIKI_LANG"; return; fi
  if $NON_INTERACTIVE; then echo "en"; return; fi

  printf "\n  ${GREEN}>${RESET} ${BOLD}Wiki language / Wiki 语言:${RESET}\n" >&2
  printf "    ${GREEN}1${RESET}) English ${DIM}(default)${RESET}\n" >&2
  printf "    ${GREEN}2${RESET}) 中文\n" >&2
  printf "  ${GREEN}>${RESET} ${BOLD}Choose${RESET} ${DIM}(Default: 1)${RESET}: " >&2
  local choice
  read -r choice < /dev/tty
  case "$choice" in
    2|zh|chinese) echo "zh" ;;
    *) echo "en" ;;
  esac
}

# ─── OS Detection ─────────────────────────────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Darwin*)          OS="macos" ;;
    Linux*)           OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;  # Git Bash on Windows
    *)                fail "Unsupported OS: $(uname -s)" ;;
  esac

  if [[ "$OS" == "macos" ]]; then
    command -v brew &>/dev/null && { PKG_MGR="brew"; HAS_BREW=true; }
  elif [[ "$OS" == "linux" ]]; then
    if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
    elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
    elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
    fi
  elif [[ "$OS" == "windows" ]]; then
    # Windows package managers: winget, chocolatey, scoop
    if   command -v winget    &>/dev/null; then PKG_MGR="winget"
    elif command -v choco     &>/dev/null; then PKG_MGR="choco"
    elif command -v scoop     &>/dev/null; then PKG_MGR="scoop"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 1: Detect
# ═══════════════════════════════════════════════════════════════════════════════

detect_installed() {
  # Git
  if command -v git &>/dev/null; then
    HAS_GIT=true
    VER_GIT=$(git --version 2>/dev/null | awk '{print $3}')
  fi

  # Homebrew (macOS only)
  [[ "$OS" == "macos" ]] && command -v brew &>/dev/null && HAS_BREW=true

  # Node.js
  if command -v node &>/dev/null; then
    HAS_NODE=true
    VER_NODE=$(node --version 2>/dev/null)
  fi

  # Claude Code
  command -v claude &>/dev/null && HAS_CLAUDE_CODE=true

  # Obsidian
  if [[ "$OS" == "macos" && -d "/Applications/Obsidian.app" ]]; then
    HAS_OBSIDIAN=true
  elif [[ "$OS" == "linux" ]] && command -v obsidian &>/dev/null; then
    HAS_OBSIDIAN=true
  elif [[ "$OS" == "windows" ]]; then
    # Check common Windows install locations
    if [[ -d "/c/Users/$USER/AppData/Local/obsidian" ]] || \
       [[ -d "$LOCALAPPDATA/obsidian" ]] || \
       command -v obsidian &>/dev/null; then
      HAS_OBSIDIAN=true
    fi
  fi

  # Claude Code Skills — check ~/.claude/skills/, ~/.agents/skills/, and plugins/marketplaces/
  local skills_dir="$HOME/.claude/skills"
  local agents_dir="$HOME/.agents/skills"
  local plugins_dir="$HOME/.claude/plugins/marketplaces"

  if [[ -d "$skills_dir/obsidian-markdown" || -d "$skills_dir/obsidian-cli" || \
        -d "$agents_dir/obsidian-markdown" || -d "$agents_dir/obsidian-cli" ]]; then
    HAS_OBSIDIAN_SKILLS=true
  fi
  if [[ -d "$skills_dir/excalidraw-diagram" || -d "$skills_dir/obsidian-canvas-creator" || \
        -d "$agents_dir/excalidraw-diagram" || -d "$agents_dir/obsidian-canvas-creator" || \
        -d "$plugins_dir/axton-obsidian-visual-skills/excalidraw-diagram" ]]; then
    HAS_VISUAL_SKILLS=true
  fi
}

print_detection_results() {
  printf "\n"

  # Claude Code
  if $HAS_CLAUDE_CODE; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Claude Code"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}recommended AI agent${RESET}\n" "Claude Code"
  fi

  # Node.js
  if $HAS_NODE; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}%s${RESET}\n" "Node.js" "$VER_NODE"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}required for Claude Code${RESET}\n" "Node.js"
  fi

  # Obsidian
  if $HAS_OBSIDIAN; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Obsidian"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}wiki editor${RESET}\n" "Obsidian"
  fi

  # Obsidian Skills
  if $HAS_OBSIDIAN_SKILLS; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Obsidian Skills"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}kepano/obsidian-skills${RESET}\n" "Obsidian Skills"
  fi

  # Visual Skills
  if $HAS_VISUAL_SKILLS; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Visual Skills"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}excalidraw / canvas / mermaid${RESET}\n" "Visual Skills"
  fi

  # Git
  if $HAS_GIT; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}%s${RESET}\n" "Git" "$VER_GIT"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}optional, for versioning${RESET}\n" "Git"
  fi

  # Obsidian Plugins (always installed per-wiki)
  printf "  ${GREEN}→${RESET}  %-20s ${DIM}auto-configured with wiki${RESET}\n" "Obsidian Plugins"

  printf "\n"
}

is_all_installed() {
  $HAS_OBSIDIAN && $HAS_NODE && $HAS_CLAUDE_CODE && \
  $HAS_OBSIDIAN_SKILLS && $HAS_VISUAL_SKILLS && $HAS_GIT
}

print_manual_guide() {
  printf "\n  ${BOLD}Manual install guide:${RESET}\n\n"

  $HAS_OBSIDIAN || \
    printf "  %-20s ${DIM}${UNDERLINE}https://obsidian.md${RESET}\n" "Obsidian"

  $HAS_NODE || \
    printf "  %-20s ${DIM}${UNDERLINE}https://nodejs.org${RESET}\n" "Node.js"

  if ! $HAS_CLAUDE_CODE; then
    printf "  %-20s ${DIM}${UNDERLINE}https://claude.ai/claude-code${RESET}\n" "Claude Code"
    printf "  %-20s ${GREEN}npm install -g @anthropic-ai/claude-code${RESET}\n" ""
  fi

  $HAS_OBSIDIAN_SKILLS || \
    printf "  %-20s ${DIM}${UNDERLINE}https://github.com/kepano/obsidian-skills${RESET}\n" "Obsidian Skills"

  $HAS_VISUAL_SKILLS || \
    printf "  %-20s ${DIM}${UNDERLINE}https://github.com/axtonliu/axton-obsidian-visual-skills${RESET}\n" "Visual Skills"

  $HAS_GIT || \
    printf "  %-20s ${DIM}${UNDERLINE}https://git-scm.com${RESET}\n" "Git"

  # Web Clipper (manual install only)
  printf "  %-20s ${DIM}${UNDERLINE}https://obsidian.md/clip${RESET} ${DIM}(save web pages to wiki)${RESET}\n" "Web Clipper"

  printf "\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 2: Install Tools
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Manual Install Guide (fallback) ─────────────────────────────────────────

print_manual_install() {
  local tool="$1" url="$2" notes="$3"
  printf "\n  ${BOLD}${YELLOW}Manual install required:${RESET}\n"
  printf "  ${BOLD}Tool:${RESET}     %s\n" "$tool"
  printf "  ${BOLD}Official:${RESET}  ${UNDERLINE}%s${RESET}\n" "$url"
  [[ -n "$notes" ]] && printf "  ${BOLD}Notes:${RESET}    ${DIM}%s${RESET}\n" "$notes"
  printf "\n"
}

# ─── Homebrew (macOS only) ───────────────────────────────────────────────────

ensure_brew() {
  [[ "$OS" != "macos" ]] && return 0
  $HAS_BREW && return 0

  info "Installing ${GREEN}Homebrew${RESET}..."
  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)" || true
    PKG_MGR="brew"
    HAS_BREW=true
    success "Homebrew installed"
  else
    print_manual_install "Homebrew" "https://brew.sh" "Required for auto-install on macOS"
    return 1
  fi
}

# ─── Obsidian ────────────────────────────────────────────────────────────────

install_obsidian() {
  $HAS_OBSIDIAN && return 0

  info "Installing ${GREEN}Obsidian${RESET}..."
  local installed=false

  case "$OS" in
    macos)
      # Try brew first, fallback to manual
      if command -v brew &>/dev/null; then
        if brew install --cask obsidian 2>&1; then
          installed=true
        fi
      fi
      ;;
    linux)
      # Try snap, then flatpak, then AppImage hint
      if command -v snap &>/dev/null; then
        if sudo snap install obsidian --classic 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v flatpak &>/dev/null; then
        if flatpak install -y flathub md.obsidian.Obsidian 2>&1; then
          installed=true
        fi
      fi
      ;;
    windows)
      # Try winget, then choco, then scoop
      if command -v winget &>/dev/null; then
        if winget install --id Obsidian.Obsidian --accept-source-agreements --accept-package-agreements 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v choco &>/dev/null; then
        if choco install obsidian -y 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v scoop &>/dev/null; then
        if scoop install obsidian 2>&1; then
          installed=true
        fi
      fi
      ;;
  esac

  if $installed; then
    HAS_OBSIDIAN=true
    success "Obsidian installed"
  else
    print_manual_install "Obsidian" "https://obsidian.md/download" \
      "Download the installer for your platform, or use your system's app store"
    return 1
  fi
}

# ─── Node.js ─────────────────────────────────────────────────────────────────

install_node() {
  $HAS_NODE && return 0

  info "Installing ${GREEN}Node.js${RESET}..."
  local installed=false

  case "$OS" in
    macos)
      if command -v brew &>/dev/null; then
        if brew install node 2>&1; then
          installed=true
        fi
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        if sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v dnf &>/dev/null; then
        if sudo dnf install -y -q nodejs npm 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm nodejs npm 2>&1; then
          installed=true
        fi
      fi
      ;;
    windows)
      if command -v winget &>/dev/null; then
        if winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v choco &>/dev/null; then
        if choco install nodejs-lts -y 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v scoop &>/dev/null; then
        if scoop install nodejs-lts 2>&1; then
          installed=true
        fi
      fi
      ;;
  esac

  if $installed && command -v node &>/dev/null; then
    HAS_NODE=true
    success "Node.js installed ($(node --version))"
  else
    print_manual_install "Node.js (LTS version recommended)" "https://nodejs.org" \
      "Download the LTS installer, or use 'nvm' for version management"
    return 1
  fi
}

install_jq() {
  command -v jq &>/dev/null && return 0

  info "Installing ${GREEN}jq${RESET} (JSON processor)..."
  local installed=false

  case "$OS" in
    macos)
      if command -v brew &>/dev/null; then
        if brew install jq 2>&1; then
          installed=true
        fi
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        if sudo apt-get install -y -qq jq 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v dnf &>/dev/null; then
        if sudo dnf install -y -q jq 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm jq 2>&1; then
          installed=true
        fi
      fi
      ;;
    windows)
      if command -v winget &>/dev/null; then
        if winget install jqlang.jq --accept-source-agreements --accept-package-agreements 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v choco &>/dev/null; then
        if choco install jq -y 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v scoop &>/dev/null; then
        if scoop install jq 2>&1; then
          installed=true
        fi
      fi
      ;;
  esac

  if $installed && command -v jq &>/dev/null; then
    success "jq installed ($(jq --version 2>/dev/null | head -1))"
  else
    warn "jq installation failed — will use Python fallback for JSON merge"
    return 1
  fi
}

# ─── Claude Code ─────────────────────────────────────────────────────────────

install_claude_code() {
  $HAS_CLAUDE_CODE && return 0

  # Requires Node.js + npm
  if ! command -v npm &>/dev/null; then
    warn "npm not available — install Node.js first"
    print_manual_install "Claude Code" "https://claude.ai/claude-code" \
      "Requires Node.js. After Node is installed: npm install -g @anthropic-ai/claude-code"
    return 1
  fi

  info "Installing ${GREEN}Claude Code${RESET}..."
  if npm install -g @anthropic-ai/claude-code 2>&1 | tail -5; then
    # Verify installation
    sleep 2  # Give npm time to update PATH
    if command -v claude &>/dev/null; then
      HAS_CLAUDE_CODE=true
      success "Claude Code installed"
    else
      warn "Install succeeded but 'claude' command not found"
      print_manual_install "Claude Code" "https://claude.ai/claude-code" \
        "May need to restart terminal or add npm global bin to PATH"
      return 1
    fi
  else
    print_manual_install "Claude Code" "https://claude.ai/claude-code" \
      "Run manually: npm install -g @anthropic-ai/claude-code"
    return 1
  fi
}

# ─── Git ─────────────────────────────────────────────────────────────────────

install_git() {
  $HAS_GIT && return 0

  info "Installing ${GREEN}Git${RESET}..."
  local installed=false

  case "$OS" in
    macos)
      # Prefer brew (faster, CLI-based), fallback to xcode-select
      if command -v brew &>/dev/null; then
        if brew install git 2>&1; then
          installed=true
        fi
      fi
      # Fallback to Xcode CLI Tools (includes Git + other dev tools)
      if ! $installed; then
        info "Installing via Xcode CLI Tools (includes Git)..."
        xcode-select --install 2>&1 || true
        if ! $NON_INTERACTIVE; then
          printf "  ${DIM}Xcode CLI Tools installer opened. Press Enter after it completes...${RESET}"
          read -r < /dev/tty
        fi
        installed=true  # Assume success after user confirmation
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        if sudo apt-get update -qq && sudo apt-get install -y -qq git 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v dnf &>/dev/null; then
        if sudo dnf install -y -q git 2>&1; then
          installed=true
        fi
      elif ! $installed && command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm git 2>&1; then
          installed=true
        fi
      fi
      ;;
    windows)
      # Git Bash usually includes Git; try package managers as fallback
      if command -v winget &>/dev/null; then
        if winget install Git.Git --accept-source-agreements --accept-package-agreements 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v choco &>/dev/null; then
        if choco install git -y 2>&1; then
          installed=true
        fi
      fi
      if ! $installed && command -v scoop &>/dev/null; then
        if scoop install git 2>&1; then
          installed=true
        fi
      fi
      ;;
  esac

  # Verify Git is actually available
  if command -v git &>/dev/null; then
    HAS_GIT=true
    success "Git installed ($(git --version | awk '{print $3}'))"
  else
    print_manual_install "Git" "https://git-scm.com/downloads" \
      "Download installer for your platform, or use your system's package manager"
    return 1
  fi
}

# ─── Claude Code Skills ──────────────────────────────────────────────────────

install_skills() {
  # Requires Node.js + npx
  if ! command -v npx &>/dev/null; then
    warn "npx not available — install Node.js first"
    return 1
  fi

  # Obsidian Skills (kepano)
  if ! $HAS_OBSIDIAN_SKILLS; then
    info "Installing ${GREEN}kepano/obsidian-skills${RESET}..."
    if npx -y skills add kepano/obsidian-skills -g -y 2>&1 | tail -3; then
      # Re-check detection
      if [[ -d "$HOME/.claude/skills/obsidian-markdown" ]] || \
         [[ -d "$HOME/.claude/skills/obsidian-cli" ]] || \
         [[ -d "$HOME/.agents/skills/obsidian-markdown" ]]; then
        HAS_OBSIDIAN_SKILLS=true
        success "kepano/obsidian-skills installed"
      else
        warn "Install succeeded but skills not detected in expected locations"
      fi
    else
      warn "Failed to install kepano/obsidian-skills"
      print_manual_install "obsidian-skills" "https://github.com/kepano/obsidian-skills" \
        "Run manually: npx -y skills add kepano/obsidian-skills -g -y"
    fi
  fi

  # Visual Skills (axtonliu)
  if ! $HAS_VISUAL_SKILLS; then
    info "Installing ${GREEN}axtonliu/axton-obsidian-visual-skills${RESET}..."
    if npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y 2>&1 | tail -3; then
      # Re-check detection
      if [[ -d "$HOME/.claude/plugins/marketplaces/axton-obsidian-visual-skills" ]] || \
         [[ -d "$HOME/.claude/skills/excalidraw-diagram" ]] || \
         [[ -d "$HOME/.agents/skills/excalidraw-diagram" ]]; then
        HAS_VISUAL_SKILLS=true
        success "axtonliu/visual-skills installed"
      else
        warn "Install succeeded but skills not detected in expected locations"
      fi
    else
      warn "Failed to install axtonliu/axton-obsidian-visual-skills"
      print_manual_install "axton-obsidian-visual-skills" "https://github.com/axtonliu/axton-obsidian-visual-skills" \
        "Run manually: npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y"
    fi
  fi
}

# ─── Run All Installs ────────────────────────────────────────────────────────

run_install() {
  [[ "$OS" == "macos" ]] && ! $HAS_BREW && ensure_brew || true

  install_node        || true
  install_claude_code || true
  install_obsidian    || true
  install_skills      || true
  install_git         || true

  # Final check — report what's still missing
  if ! $HAS_OBSIDIAN || ! $HAS_NODE || ! $HAS_CLAUDE_CODE || ! $HAS_GIT; then
    warn "\nSome tools could not be auto-installed. Check the manual install guides above."
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 3: Create Wiki
# ═══════════════════════════════════════════════════════════════════════════════

detect_clone_status() {
  CLONE_STATUS="need_clone"

  if [[ -f "install.sh" && -d "template/base" ]]; then
    CLONE_STATUS="in_template"
    return
  fi

  if [[ -f "CLAUDE.md" && -d "raw" && -d "wiki" ]]; then
    CLONE_STATUS="in_wiki"
    return
  fi
}

detect_dev_mode() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || return 1
  if [[ -d "$script_dir/template/base" ]]; then
    LOCAL_TEMPLATE="$script_dir/template"
    return 0
  fi
  return 1
}

download_template() {
  local tmpdir
  tmpdir=$(mktemp -d)
  TEMPLATE_TMPDIR="$tmpdir"

  local downloaded=false

  # Try git clone
  if command -v git &>/dev/null; then
    info "Downloading template via ${GREEN}git${RESET}..."
    if git clone --depth 1 "$TEMPLATE_REPO_URL" "$tmpdir/repo" 2>&1 | tail -1; then
      if [[ -d "$tmpdir/repo/template/base" ]]; then
        LOCAL_TEMPLATE="$tmpdir/repo/template"
        downloaded=true
      fi
    fi
  fi

  # Fallback to curl tarball
  if ! $downloaded; then
    info "Downloading template via ${GREEN}curl${RESET}..."
    local tarball_url="https://github.com/$TEMPLATE_REPO/archive/refs/heads/main.tar.gz"
    if curl -fsSL "$tarball_url" -o "$tmpdir/repo.tar.gz" 2>/dev/null; then
      tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" 2>/dev/null
      local extracted
      extracted=$(find "$tmpdir" -maxdepth 1 -type d -name 'llm-wiki-starter*' | head -1)
      if [[ -n "$extracted" && -d "$extracted/template/base" ]]; then
        LOCAL_TEMPLATE="$extracted/template"
        downloaded=true
      fi
    fi
  fi

  if ! $downloaded; then
    rm -rf "$tmpdir"
    TEMPLATE_TMPDIR=""
    fail "Failed to download template. Check your network connection."
  fi
}

prepare_wiki() {
  local target="$1"

  if [[ -d "$target" && -f "$target/CLAUDE.md" ]]; then
    warn "Directory ${CYAN}$target${RESET} already contains a wiki, skipping creation"
    return 0
  fi
  [[ -d "$target" ]] && fail "Directory ${CYAN}$target${RESET} already exists. Choose a different name or remove it."

  if [[ -z "$LOCAL_TEMPLATE" ]]; then
    download_template
  fi

  info "Creating wiki from template..."
  mkdir -p "$target"

  # Layer 1: shared base files (.gitignore, canvas/, root sortspec)
  cp -a "$LOCAL_TEMPLATE/base/." "$target/" 2>/dev/null || true

  # Layer 2: language overlay (AGENTS.md, CLAUDE.md, README.md, raw/, wiki/)
  cp -a "$LOCAL_TEMPLATE/$WIKI_LANG/." "$target/" 2>/dev/null || true

  # Ensure empty directories exist (git doesn't track them)
  local base_dirs=("wiki/assets/excalidraw" "canvas")
  local lang_dirs=()
  if [[ "$WIKI_LANG" == "zh" ]]; then
    lang_dirs=("raw/收件箱" "raw/assets" "wiki/概念" "wiki/资料摘要" "wiki/综合分析" "wiki/归档")
  else
    lang_dirs=("raw/inbox" "raw/assets" "wiki/concepts" "wiki/summaries" "wiki/synthesis" "wiki/archived")
  fi
  for d in "${base_dirs[@]}" "${lang_dirs[@]}"; do
    mkdir -p "$target/$d"
  done

  success "Wiki created: ${CYAN}$(rel_path "$target")${RESET}"
}

replace_placeholders() {
  local wiki_dir="$1" name="$2"
  local today
  today=$(date +%Y-%m-%d)

  local files_to_patch=("CLAUDE.md" "AGENTS.md" "README.md")

  if [[ "$WIKI_LANG" == "zh" ]]; then
    files_to_patch+=("wiki/知识库概览.md" "wiki/Wiki 目录.md" "wiki/操作日志.md")
  else
    files_to_patch+=("wiki/Overview.md" "wiki/Index.md" "wiki/Changelog.md")
  fi

  for f in "${files_to_patch[@]}"; do
    local fpath="$wiki_dir/$f"
    [[ -f "$fpath" ]] || continue
    if [[ "$OS" == "macos" ]]; then
      sed -i '' "s/<Wiki Name>/$name/g; s/<wiki-name>/$name/g; s/{{date}}/$today/g" "$fpath"
    else
      sed -i "s/<Wiki Name>/$name/g; s/<wiki-name>/$name/g; s/{{date}}/$today/g" "$fpath"
    fi
  done
}

# Spinner animation for download progress
_spinner() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while true; do
    printf "\r  ${CYAN}${chars:$i:1}${RESET} ${DIM}Downloading...${RESET}"
    i=$(( (i + 1) % 10 ))
    sleep 0.1
  done
}

download_plugin() {
  local repo="$1" plugin_id="$2" target_dir="$3"
  local plugin_dir="$target_dir/.obsidian/plugins/$plugin_id"
  local base_url="https://github.com/$repo/releases/latest/download"

  mkdir -p "$plugin_dir"

  # Show download indicator
  printf "  ${CYAN}↓${RESET} ${DIM}Downloading %s...${RESET}" "$plugin_id"

  local ok=true
  for file in main.js manifest.json; do
    if ! curl -fsSL --max-time 30 "$base_url/$file" -o "$plugin_dir/$file" 2>/dev/null; then
      ok=false; break
    fi
  done
  curl -fsSL --max-time 30 "$base_url/styles.css" -o "$plugin_dir/styles.css" 2>/dev/null || true

  # Clear download indicator and show result
  printf "\r%50s\r" ""  # Clear the line

  if $ok && [[ -s "$plugin_dir/manifest.json" ]]; then
    printf "    ${GREEN}✓${RESET} %s\n" "$plugin_id"
    return 0
  else
    rm -rf "$plugin_dir"
    printf "    ${YELLOW}⚠${RESET} %s ${DIM}download failed${RESET}\n" "$plugin_id"
    return 1
  fi
}

install_obsidian_plugins() {
  local wiki_dir="$1"
  local plugins_installed=()

  mkdir -p "$wiki_dir/.obsidian/plugins"
  mkdir -p "$wiki_dir/.obsidian/themes"

  # ─── Plugin Categories ─────────────────────────────────────────────────────
  # Core plugins: Required for llm-wiki functionality (data, templates, git, linting)
  # UX plugins:   Enhance Obsidian editing experience (toolbar, search, navigation, diagrams)
  # ────────────────────────────────────────────────────────────────────────────

  # Core plugins (llm-wiki core functionality)
  local core_plugins=(
    "blacksmithgu/obsidian-dataview|dataview"              # Query and display data from notes
    "SilentVoid13/Templater|templater-obsidian"            # Templates and automation
    "Vinzent03/obsidian-git|obsidian-git"                  # Git version control
    "platers/obsidian-linter|obsidian-linter"              # Markdown linting
    "pjeby/tag-wrangler|tag-wrangler"                      # Tag management
    "TfTHacker/obsidian42-strange-new-worlds|obsidian42-strange-new-worlds"  # Link context
    "mirnovov/obsidian-homepage|homepage"                  # Dashboard/homepage
    "SebastianMC/obsidian-custom-sort|custom-sort"         # Custom file sorting
  )

  # UX plugins (Obsidian editing experience enhancements)
  local ux_plugins=(
    "scambier/obsidian-omnisearch|omnisearch"              # Fuzzy search across vault
    "darlal/obsidian-switcher-plus|darlal-switcher-plus"   # Quick switcher with headings
    "kepano/obsidian-minimal-settings|obsidian-minimal-settings"  # Minimal theme settings
    "kepano/obsidian-hider|obsidian-hider"                 # Hide UI elements (cleaner interface)
    "PKM-er/obsidian-editing-toolbar|editing-toolbar"      # MS Word-like editing toolbar + F11 fullscreen
    "zsviczian/obsidian-excalidraw-plugin|obsidian-excalidraw-plugin"  # Hand-drawn style diagrams
    "guopenghui/obsidian-quiet-outline|obsidian-quiet-outline"  # Enhanced outline view
    "yonatan-reicher/obsidian-open-in-terminal|open-in-terminal"  # Open vault in terminal
  )

  # Skip obsidian-git if Git is not available
  if ! $HAS_GIT; then
    info "Git not available — skipping ${GREEN}obsidian-git${RESET} plugin"
    local filtered=()
    for entry in "${core_plugins[@]}"; do
      [[ "$entry" == *"|obsidian-git" ]] && continue
      filtered+=("$entry")
    done
    core_plugins=("${filtered[@]}")
  fi

  printf "\n${BOLD}Obsidian Setup:${RESET}\n"

  # Install core plugins (llm-wiki core)
  printf "\n  ${DIM}Core plugins (llm-wiki core):${RESET}\n"
  for entry in "${core_plugins[@]}"; do
    local repo="${entry%%|*}" id="${entry##*|}"
    if [[ -d "$wiki_dir/.obsidian/plugins/$id" ]]; then
      printf "    ${GREEN}✓${RESET} %s ${DIM}(exists)${RESET}\n" "$id"
      plugins_installed+=("$id")
      continue
    fi
    download_plugin "$repo" "$id" "$wiki_dir" && plugins_installed+=("$id")
  done

  # Install UX plugins (Obsidian experience)
  printf "\n  ${DIM}UX plugins (Obsidian experience):${RESET}\n"
  for entry in "${ux_plugins[@]}"; do
    local repo="${entry%%|*}" id="${entry##*|}"
    if [[ -d "$wiki_dir/.obsidian/plugins/$id" ]]; then
      printf "    ${GREEN}✓${RESET} %s ${DIM}(exists)${RESET}\n" "$id"
      plugins_installed+=("$id")
      continue
    fi
    download_plugin "$repo" "$id" "$wiki_dir" && plugins_installed+=("$id")
  done

  # Write community-plugins.json
  if [[ ${#plugins_installed[@]} -gt 0 ]]; then
    local json="["
    local first=true
    for id in "${plugins_installed[@]}"; do
      if $first; then first=false; else json+=","; fi
      json+="\"$id\""
    done
    json+="]"
    echo "$json" > "$wiki_dir/.obsidian/community-plugins.json"
    printf "\n  ${GREEN}✓${RESET} ${BOLD}%d${RESET} plugins configured\n" "${#plugins_installed[@]}"
  fi

  # Configure custom-sort plugin (must not be suspended)
  local cs_dir="$wiki_dir/.obsidian/plugins/custom-sort"
  if [[ -d "$cs_dir" && ! -f "$cs_dir/data.json" ]]; then
    cat > "$cs_dir/data.json" <<'CSJSON'
{"suspended":false,"statusBarEntryEnabled":true,"notificationsEnabled":true,"customSortContextSubmenu":true}
CSJSON
  fi

  # Install Minimal theme
  printf "\n  ${DIM}Theme:${RESET}\n"
  local theme_dir="$wiki_dir/.obsidian/themes/Minimal"
  local theme_url="https://github.com/kepano/obsidian-minimal/releases/latest/download"
  if [[ ! -d "$theme_dir" ]]; then
    mkdir -p "$theme_dir"
    printf "  ${CYAN}↓${RESET} ${DIM}Downloading Minimal theme...${RESET}"
    if curl -fsSL --max-time 30 "$theme_url/manifest.json" -o "$theme_dir/manifest.json" 2>/dev/null && \
       curl -fsSL --max-time 30 "$theme_url/theme.css" -o "$theme_dir/theme.css" 2>/dev/null; then
      printf "\r%50s\r" ""
      printf "    ${GREEN}✓${RESET} Minimal theme ${DIM}(clean, distraction-free)${RESET}\n"
    else
      printf "\r%50s\r" ""
      rm -rf "$theme_dir"
      printf "    ${YELLOW}⚠${RESET} Minimal theme ${DIM}(download failed, network timeout)${RESET}\n"
    fi
  else
    printf "    ${GREEN}✓${RESET} Minimal theme ${DIM}(exists)${RESET}\n"
  fi

  # Print Obsidian configuration summary
  printf "\n  ${DIM}Appearance:${RESET}\n"
  printf "    ${GREEN}•${RESET} Accent color: ${GREEN}#6b9b6b${RESET} ${DIM}(wiki green)${RESET}\n"
  printf "    ${GREEN}•${RESET} Base font size: 16px\n"

  printf "\n  ${DIM}Key shortcuts:${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+Shift+F${RESET}    ${DIM}→ Omnisearch (fuzzy search)${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+R${RESET}          ${DIM}→ Quick switcher (headings)${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+←/→${RESET}        ${DIM}→ Navigate back/forward${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+Shift+B${RESET}    ${DIM}→ Toggle left sidebar${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+Shift+L${RESET}    ${DIM}→ Toggle right sidebar${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+F11${RESET}        ${DIM}→ Workplace fullscreen${RESET}\n"
  printf "    ${GREEN}•${RESET} ${BOLD}Cmd+Shift+F11${RESET}  ${DIM}→ Editor fullscreen focus${RESET}\n"
  printf "\n"
}

setup_wiki() {
  detect_clone_status

  case "$CLONE_STATUS" in
    in_template)
      LOCAL_TEMPLATE="$(pwd)/template"
      info "Set up your new wiki:"
      WIKI_LANG=$(prompt_language)
      WIKI_NAME="${WIKI_NAME:-my-wiki}"
      WIKI_NAME=$(prompt_wiki_name "$WIKI_NAME")
      WIKI_TARGET="${WIKI_DIR:-${LLM_WIKI_DIR:-$(pwd)/$WIKI_NAME}}"
      info "Location: ${CYAN}$(rel_path "$WIKI_TARGET")${RESET}"
      prepare_wiki "$WIKI_TARGET"
      ;;
    in_wiki)
      info "Current directory is already an LLM Wiki"
      WIKI_TARGET="$(pwd)"
      WIKI_NAME="${WIKI_NAME:-$(basename "$(pwd)")}"
      ;;
    need_clone)
      detect_dev_mode || true
      info "Set up your new wiki:"
      WIKI_LANG=$(prompt_language)
      WIKI_NAME="${WIKI_NAME:-my-wiki}"
      WIKI_NAME=$(prompt_wiki_name "$WIKI_NAME")
      WIKI_TARGET="${WIKI_DIR:-${LLM_WIKI_DIR:-$WIKI_NAME}}"
      info "Location: ${CYAN}$(rel_path "$WIKI_TARGET")${RESET}"
      prepare_wiki "$WIKI_TARGET"
      ;;
  esac

  # Skip Obsidian plugins in ONLY_WIKI mode (handled separately in main)
  if ! $ONLY_WIKI; then
    install_obsidian_plugins "$WIKI_TARGET"
  fi
  replace_placeholders "$WIKI_TARGET" "$WIKI_NAME"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 4: Finalize
# ═══════════════════════════════════════════════════════════════════════════════

init_git_repo() {
  local wiki_dir="$1" name="$2"

  if ! command -v git &>/dev/null; then
    info "Git not available — skipping repository initialization"
    return 0
  fi

  if [[ -d "$wiki_dir/.git" ]]; then
    success "Git repository already exists"
    return 0
  fi

  git -C "$wiki_dir" init --quiet
  git -C "$wiki_dir" add -A
  git -C "$wiki_dir" commit --quiet -m "init: $name (via llm-wiki-starter v$VERSION)"
  success "Git repository initialized"
}

cleanup_installer() {
  local wiki_dir="$1"

  # Clean up downloaded template
  [[ -n "$TEMPLATE_TMPDIR" ]] && rm -rf "$TEMPLATE_TMPDIR" 2>/dev/null || true

  # Never delete from the source repo
  [[ -d "$wiki_dir/template" ]] && return 0

  rm -f "$wiki_dir/install.sh" 2>/dev/null || true

  local script_path="${BASH_SOURCE[0]:-$0}"
  if [[ "$script_path" == "/tmp/"* ]]; then
    rm -f "$script_path" 2>/dev/null || true
  fi
}

print_success() {
  local name="$1" target="$2"
  local abs_target
  abs_target="$(cd "$target" 2>/dev/null && pwd)" || abs_target="$target"

  printf "\n${BOLD}${SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  printf "${BOLD}${SUCCESS}  ✓${RESET} %s ${BOLD}${SUCCESS}is ready!${RESET}\n" "$name"
  printf "${SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  printf "\n${BOLD}Operations ${DIM}(inside Claude Code)${RESET}${BOLD}:${RESET}\n\n"
  printf "  ${MAGENTA}${BOLD}1. Ingest${RESET}  ${DIM}→${RESET}  ${BLUE}Ingest this article: https://example.com/article${RESET}\n"
  printf "             ${DIM}Add knowledge from URLs or files in${RESET} ${CYAN}raw/${RESET}\n"
  printf "  ${MAGENTA}${BOLD}2. Query${RESET}   ${DIM}→${RESET}  ${BLUE}What is the relationship between X and Y?${RESET}\n"
  printf "             ${DIM}Ask questions, get answers with citations${RESET}\n"
  printf "  ${MAGENTA}${BOLD}3. Lint${RESET}    ${DIM}→${RESET}  ${BLUE}Run a health check on the wiki${RESET}\n"
  printf "             ${DIM}Find orphans, dead links, stale pages${RESET}\n"

  printf "\n${BOLD}Quick start:${RESET}\n\n"
  local step_n=1
  if [[ "$abs_target" != "$(pwd)" ]]; then
    printf "  ${DIM}%d.${RESET} cd ${CYAN}%s${RESET}\n" "$step_n" "$(rel_path "$target")"
    step_n=$((step_n + 1))
  fi
  if [[ "$OS" == "macos" ]]; then
    printf "  ${DIM}%d.${RESET} open -a Obsidian .       ${DIM}# open as Obsidian vault${RESET}\n" "$step_n"
  elif [[ "$OS" == "windows" ]]; then
    printf "  ${DIM}%d.${RESET} obsidian .               ${DIM}# open as Obsidian vault (Git Bash)${RESET}\n" "$step_n"
    printf "     ${DIM}or: start obsidian %s  ${DIM}# Windows CMD/PowerShell${RESET}\n" "$abs_target"
  else
    printf "  ${DIM}%d.${RESET} obsidian .               ${DIM}# open as Obsidian vault${RESET}\n" "$step_n"
  fi
  step_n=$((step_n + 1))
  printf "  ${DIM}%d.${RESET} claude                   ${DIM}# start AI agent${RESET}\n" "$step_n"
  printf "\n"
}

# ─── CLI Args ─────────────────────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)            WIKI_NAME="$2"; shift 2 ;;
      --dir)             WIKI_DIR="$2"; shift 2 ;;
      --lang)
        case "$2" in
          zh|en) WIKI_LANG="$2" ;;
          *) fail "Invalid language: $2 (use 'zh' or 'en')" ;;
        esac
        shift 2
        ;;
      --non-interactive|--yes|-y) NON_INTERACTIVE=true; shift ;;
      --skip-install)    SKIP_INSTALL=true; shift ;;
      --only-tools)      ONLY_TOOLS=true; shift ;;
      --only-obsidian)   ONLY_OBSIDIAN=true; shift ;;
      --only-wiki)       ONLY_WIKI=true; shift ;;
      --help|-h)         usage; exit 0 ;;
      --version|-v)      echo "llm-wiki-starter v$VERSION"; exit 0 ;;
      *)                 warn "Unknown option: $1"; shift ;;
    esac
  done

  # Validate mutually exclusive mode flags
  local mode_count=0
  $ONLY_TOOLS && mode_count=$((mode_count + 1))
  $ONLY_OBSIDIAN && mode_count=$((mode_count + 1))
  $ONLY_WIKI && mode_count=$((mode_count + 1))
  if [[ $mode_count -gt 1 ]]; then
    fail "Cannot use multiple mode flags together (--only-tools, --only-obsidian, --only-wiki)"
  fi
}

usage() {
  cat <<'EOF'
llm-wiki-starter — Create an LLM Wiki knowledge base in one command

Usage:
  curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
  bash install.sh [OPTIONS]
  bash install.sh --only-tools [OPTIONS]
  bash install.sh --only-obsidian [--dir <vault>] [OPTIONS]
  bash install.sh --only-wiki [--name <name>] [OPTIONS]

Modes:
  Default              Install tools → Create wiki → Install Obsidian plugins
  --only-tools         Install all tools only (no wiki creation)
                       Use: Add tools to existing environment without creating wiki
  --only-obsidian      Install Obsidian software + plugins + themes + config
                       Use: Full Obsidian setup in existing vault (merge with existing config)
  --only-wiki          Create wiki from template only (skip tools installation)
                       Use: Fast wiki creation when tools already installed

Options:
  --name <name>        Wiki name (default: my-wiki)
  --dir <directory>    Target directory (default: ./<name> for wiki, . for --only-obsidian)
  --lang <zh|en>       Wiki language (default: en)
  --yes, -y            Skip all prompts, use defaults (non-interactive mode)
  --skip-install       Only create wiki structure, skip tool installation (deprecated: use --only-wiki)
  --help               Show this help
  --version            Show version

Environment:
  LLM_WIKI_DIR         Target directory (same as --dir)

Examples:
  # Full interactive install
  bash install.sh

  # Non-interactive full install
  bash install.sh --yes --name my-ai-wiki

  # Only install tools (for existing wiki)
  bash install.sh --only-tools

  # Full Obsidian setup in existing vault (software + plugins + config)
  bash install.sh --only-obsidian --dir ~/Documents/my-vault

  # Only create wiki (tools already installed)
  bash install.sh --only-wiki --name new-wiki

Configuration Merge (--only-obsidian):
  When target has existing Obsidian config, new settings are merged:
  - Obsidian software:   Install if not detected
  - Plugins & themes:    Download and install from GitHub releases
  - hotkeys.json:        Add new shortcuts, preserve user's existing shortcuts
  - app.json:            Override specified fields, preserve others
  - appearance.json:     Override specified fields, preserve others
  - community-plugins.json: Merge plugin lists, deduplicate
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# Config Merge Helpers
# ═══════════════════════════════════════════════════════════════════════════════
# Priority: jq (best, cross-platform) → Bash (fallback)
# ──────────────────────────────────────────────────────────────────────────────

# Merge JSON: template overrides target (deep merge)
merge_json() {
  local target_file="$1" template_file="$2"

  # jq: best, cross-platform consistent
  if command -v jq &>/dev/null; then
    jq -s '.[0] * .[1]' "$target_file" "$template_file" > "${target_file}.merged" 2>/dev/null
    mv "${target_file}.merged" "$target_file"
    return 0
  fi

  # Bash fallback: backup and use template
  warn "jq not available — backing up user config and using template"
  cp "$target_file" "${target_file}.bak"
  cp "$template_file" "$target_file"
}

# Merge hotkeys.json
merge_hotkeys() {
  local target_dir="$1" template_dir="$2"
  local target="$target_dir/.obsidian/hotkeys.json"
  local template="$template_dir/.obsidian/hotkeys.json"

  [[ ! -f "$target" ]] && { cp "$template" "$target"; return 0; }
  merge_json "$target" "$template"
}

# Merge community-plugins.json: combine and deduplicate
merge_plugins() {
  local target_dir="$1" new_plugins="$2"
  local target="$target_dir/.obsidian/community-plugins.json"

  [[ ! -f "$target" ]] && { echo "$new_plugins" > "$target"; return 0; }

  # jq: merge and dedupe
  if command -v jq &>/dev/null; then
    echo "$(cat "$target") $new_plugins" | jq -s 'add | unique' > "$target"
    return 0
  fi

  # Bash: simple dedupe
  local all=$(grep -oE '"[^"]+"' "$target" "$new_plugins" | tr -d '"' | sort -u | tr '\n' ' ')
  all=$(echo "$all" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  # Format as JSON array
  local result="["
  local first=true
  for id in $all; do
    if $first; then first=false; else result+=","; fi
    result+="\"$id\""
  done
  result+="]"
  echo "$result" > "$target"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  local url_line="By eleven-net-cn  ${TEMPLATE_REPO_URL}"
  local inner_w=73
  local border
  border=$(printf '%*s' "$inner_w" '' | tr ' ' '─')
  printf "\n${BOLD}${GREEN}┌${border}┐${RESET}\n"
  printf "${BOLD}${GREEN}│${RESET}  ${BOLD}${GREEN}LLM Wiki Starter${RESET} v%-$((inner_w - 20))s${BOLD}${GREEN}│${RESET}\n" "$VERSION"
  printf "${BOLD}${GREEN}│${RESET}  ${DIM}%-$((inner_w - 2))s${RESET}${BOLD}${GREEN}│${RESET}\n" "Knowledge base scaffolding for LLM Wiki"
  printf "${BOLD}${GREEN}│${RESET}  ${DIM}%-$((inner_w - 2))s${RESET}${BOLD}${GREEN}│${RESET}\n" "$url_line"
  printf "${BOLD}${GREEN}└${border}┘${RESET}\n\n"

  detect_os
  info "OS: ${CYAN}$OS${RESET}  |  Package manager: ${CYAN}${PKG_MGR:-none}${RESET}"

  # ── Mode: --only-tools (install tools only, no wiki) ──
  if $ONLY_TOOLS; then
    info "Mode: ${GREEN}--only-tools${RESET} (install tools only)"
    detect_installed
    print_detection_results

    if is_all_installed; then
      success "All tools already installed"
    else
      if $NON_INTERACTIVE || prompt_confirm "Install missing tools?" "Y"; then
        run_install
      else
        print_manual_guide
      fi
    fi
    return 0
  fi

  # ── Mode: --only-obsidian (install Obsidian + plugins + themes + config) ──
  if $ONLY_OBSIDIAN; then
    info "Mode: ${GREEN}--only-obsidian${RESET} (install Obsidian software and all configurations)"

    # Step 1: Detect and install Obsidian software if needed
    detect_installed
    if ! $HAS_OBSIDIAN; then
      info "Obsidian not installed — installing..."
      install_obsidian
    else
      success "Obsidian already installed"
    fi

    # Step 2: Install jq for JSON merge (recommended)
    if ! command -v jq &>/dev/null; then
      info "Installing jq for JSON merge..."
      install_jq || true  # Continue even if jq install fails (Bash fallback)
    fi

    # Step 3: Determine target directory
    WIKI_TARGET="${WIKI_DIR:-.}"
    if [[ ! -d "$WIKI_TARGET" ]]; then
      fail "Target directory does not exist: $WIKI_TARGET"
    fi

    # Step 4: Ensure .obsidian directory exists
    if [[ ! -d "$WIKI_TARGET/.obsidian" ]]; then
      info "Creating .obsidian directory..."
      mkdir -p "$WIKI_TARGET/.obsidian"
    fi

    # Step 4: Get template for config files
    detect_dev_mode || download_template

    # Step 5: Install plugins and theme
    install_obsidian_plugins "$WIKI_TARGET"

    # Step 6: Merge config files (preserve user's existing config)
    printf "\n${BOLD}Merging config files:${RESET}\n"

    # hotkeys.json
    if [[ -f "$WIKI_TARGET/.obsidian/hotkeys.json" ]]; then
      info "Merging ${CYAN}hotkeys.json${RESET} (existing config preserved)"
      merge_json "$WIKI_TARGET/.obsidian/hotkeys.json" "$LOCAL_TEMPLATE/base/.obsidian/hotkeys.json"
      printf "  ${GREEN}✓${RESET} hotkeys.json ${DIM}(merged)${RESET}\n"
    else
      cp "$LOCAL_TEMPLATE/base/.obsidian/hotkeys.json" "$WIKI_TARGET/.obsidian/"
      printf "  ${GREEN}✓${RESET} hotkeys.json ${DIM}(new file)${RESET}\n"
    fi

    # app.json
    if [[ -f "$WIKI_TARGET/.obsidian/app.json" ]] && [[ -f "$LOCAL_TEMPLATE/base/.obsidian/app.json" ]]; then
      info "Merging ${CYAN}app.json${RESET}"
      merge_json "$WIKI_TARGET/.obsidian/app.json" "$LOCAL_TEMPLATE/base/.obsidian/app.json"
      printf "  ${GREEN}✓${RESET} app.json ${DIM}(merged)${RESET}\n"
    elif [[ ! -f "$WIKI_TARGET/.obsidian/app.json" ]]; then
      cp "$LOCAL_TEMPLATE/base/.obsidian/app.json" "$WIKI_TARGET/.obsidian/"
      printf "  ${GREEN}✓${RESET} app.json ${DIM}(new file)${RESET}\n"
    fi

    # appearance.json
    if [[ -f "$LOCAL_TEMPLATE/base/.obsidian/appearance.json" ]]; then
      if [[ -f "$WIKI_TARGET/.obsidian/appearance.json" ]]; then
        info "Merging ${CYAN}appearance.json${RESET}"
        merge_json "$WIKI_TARGET/.obsidian/appearance.json" "$LOCAL_TEMPLATE/base/.obsidian/appearance.json"
        printf "  ${GREEN}✓${RESET} appearance.json ${DIM}(merged)${RESET}\n"
      else
        cp "$LOCAL_TEMPLATE/base/.obsidian/appearance.json" "$WIKI_TARGET/.obsidian/"
        printf "  ${GREEN}✓${RESET} appearance.json ${DIM}(new file)${RESET}\n"
      fi
    fi

    printf "\n${SUCCESS}✓${RESET} Obsidian setup complete!${RESET}\n"
    cleanup_installer "$WIKI_TARGET"
    return 0
  fi

  # ── Mode: --only-wiki (create wiki only, skip tools detection/install) ──
  if $ONLY_WIKI; then
    info "Mode: ${GREEN}--only-wiki${RESET} (create wiki template only)"

    # Skip tool detection/installation, start directly from wiki creation
    stepn "1" "3" "Creating wiki"
    setup_wiki

    stepn "2" "3" "Obsidian Setup"
    install_obsidian_plugins "$WIKI_TARGET"

    stepn "3" "3" "Finalizing"
    init_git_repo "$WIKI_TARGET" "$WIKI_NAME"
    cleanup_installer "$WIKI_TARGET"
    print_success "$WIKI_NAME" "$WIKI_TARGET"
    return 0
  fi

  # ── Default Mode: Full install ──
  detect_installed

  local total_steps=3
  local need_install=false
  local current_step=1

  if ! $SKIP_INSTALL && ! is_all_installed; then
    need_install=true
    total_steps=4
  fi

  # ── Phase 1: Show detection results ──
  stepn "$current_step" "$total_steps" "Detecting installed tools"
  print_detection_results
  current_step=$((current_step + 1))

  # ── Phase 2: Install (only if needed) ──
  if $SKIP_INSTALL; then
    info "Skipping tool installation ${DIM}(--skip-install)${RESET}"
  elif $need_install; then
    if prompt_confirm "Install missing items?" "Y"; then
      stepn "$current_step" "$total_steps" "Installing tools"
      run_install
      current_step=$((current_step + 1))
    else
      info "Skipped automatic installation"
      print_manual_guide
      current_step=$((current_step + 1))
    fi
  fi

  # ── Phase 3: Create Wiki ──
  stepn "$current_step" "$total_steps" "Creating wiki"
  setup_wiki
  current_step=$((current_step + 1))

  # ── Phase 4: Finalize ──
  stepn "$current_step" "$total_steps" "Finalizing"
  init_git_repo "$WIKI_TARGET" "$WIKI_NAME"
  cleanup_installer "$WIKI_TARGET"
  print_success "$WIKI_NAME" "$WIKI_TARGET"
}

parse_args "$@"
main

