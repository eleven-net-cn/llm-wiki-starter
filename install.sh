#!/usr/bin/env bash
# llm-wiki-starter — Create an LLM Wiki knowledge base in one command
# Author: eleven-net-cn
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
#   bash install.sh [--name <name>] [--dir <dir>] [--non-interactive] [--skip-install]
#
# Flow: Detect → Install Tools → Create Wiki → Finalize

set -euo pipefail

VERSION="1.0.0-beta.0"
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
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
RESET='\033[0m'

[[ ! -t 1 ]] && RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' DIM='' UNDERLINE='' RESET=''

info()    { printf "${CYAN}→${RESET} %b\n" "$1"; }
success() { printf "${GREEN}✓${RESET} %b\n" "$1"; }
warn()    { printf "${YELLOW}⚠${RESET} %b\n" "$1"; }
fail()    { printf "${RED}✗ %b${RESET}\n" "$1" >&2; exit 1; }
stepn()   { printf "\n${BOLD}${BLUE}[%s/%s]${RESET} ${BOLD}%b${RESET}\n" "$1" "$2" "$3"; }
rel_path() { local p="$1" cwd="$(pwd)"; echo "${p#$cwd/}"; }

# ─── Interactive Prompts (bash 3.2 compatible) ────────────────────────────────

prompt_input() {
  local question="$1" default="$2" result
  if $NON_INTERACTIVE; then echo "$default"; return; fi
  printf "  ${BOLD}%s${RESET} [${CYAN}%s${RESET}]: " "$question" "$default" >&2
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

prompt_language() {
  if [[ -n "$WIKI_LANG" ]]; then echo "$WIKI_LANG"; return; fi
  if $NON_INTERACTIVE; then echo "en"; return; fi

  printf "\n  ${BOLD}Wiki language / Wiki 语言:${RESET}\n" >&2
  printf "    ${CYAN}1${RESET}) English ${DIM}(default)${RESET}\n" >&2
  printf "    ${CYAN}2${RESET}) 中文\n" >&2
  printf "  ${BOLD}Choose${RESET} [${CYAN}1${RESET}]: " >&2
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
    Darwin*) OS="macos" ;;
    Linux*)  OS="linux" ;;
    *)       fail "Unsupported OS: $(uname -s)" ;;
  esac

  if [[ "$OS" == "macos" ]]; then
    command -v brew &>/dev/null && { PKG_MGR="brew"; HAS_BREW=true; }
  elif [[ "$OS" == "linux" ]]; then
    if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
    elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
    elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
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

  # Obsidian
  if $HAS_OBSIDIAN; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Obsidian"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}wiki editor${RESET}\n" "Obsidian"
  fi

  # Node.js
  if $HAS_NODE; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}%s${RESET}\n" "Node.js" "$VER_NODE"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}required for Claude Code${RESET}\n" "Node.js"
  fi

  # Claude Code
  if $HAS_CLAUDE_CODE; then
    printf "  ${GREEN}✓${RESET}  %-20s ${DIM}installed${RESET}\n" "Claude Code"
  else
    printf "  ${YELLOW}✗${RESET}  %-20s ${CYAN}recommended AI agent${RESET}\n" "Claude Code"
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
  printf "  ${BLUE}→${RESET}  %-20s ${DIM}auto-configured with wiki${RESET}\n" "Obsidian Plugins"

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
    printf "  %-20s ${WHITE}npm install -g @anthropic-ai/claude-code${RESET}\n" ""
  fi

  $HAS_OBSIDIAN_SKILLS || \
    printf "  %-20s ${DIM}${UNDERLINE}https://github.com/kepano/obsidian-skills${RESET}\n" "Obsidian Skills"

  $HAS_VISUAL_SKILLS || \
    printf "  %-20s ${DIM}${UNDERLINE}https://github.com/axtonliu/axton-obsidian-visual-skills${RESET}\n" "Visual Skills"

  $HAS_GIT || \
    printf "  %-20s ${DIM}${UNDERLINE}https://git-scm.com${RESET}\n" "Git"

  printf "\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 2: Install Tools
# ═══════════════════════════════════════════════════════════════════════════════

ensure_brew() {
  [[ "$OS" != "macos" ]] && return 0
  $HAS_BREW && return 0

  info "Installing ${WHITE}Homebrew${RESET}..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)" || true
  PKG_MGR="brew"
  HAS_BREW=true
  success "Homebrew installed"
}

install_obsidian() {
  $HAS_OBSIDIAN && return 0

  info "Installing ${WHITE}Obsidian${RESET}..."
  case "$OS" in
    macos)
      if $HAS_BREW || command -v brew &>/dev/null; then
        brew install --cask obsidian
        HAS_OBSIDIAN=true
        success "Obsidian installed"
      else
        warn "Cannot auto-install without Homebrew. Download: ${UNDERLINE}https://obsidian.md${RESET}"
      fi
      ;;
    linux)
      if command -v snap &>/dev/null; then
        sudo snap install obsidian --classic
        HAS_OBSIDIAN=true
        success "Obsidian installed"
      else
        warn "Cannot auto-install. Download: ${UNDERLINE}https://obsidian.md${RESET}"
      fi
      ;;
  esac
}

install_node() {
  $HAS_NODE && return 0

  info "Installing ${WHITE}Node.js${RESET}..."
  case "$PKG_MGR" in
    brew)   brew install node ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm ;;
    dnf)    sudo dnf install -y -q nodejs npm ;;
    pacman) sudo pacman -S --noconfirm nodejs npm ;;
    *)      warn "Cannot auto-install. Download: ${UNDERLINE}https://nodejs.org${RESET}"; return 1 ;;
  esac
  HAS_NODE=true
  success "Node.js installed"
}

install_claude_code() {
  $HAS_CLAUDE_CODE && return 0

  if ! command -v npm &>/dev/null; then
    warn "npm not available, skipping Claude Code"
    return 1
  fi

  info "Installing ${WHITE}Claude Code${RESET}..."
  npm install -g @anthropic-ai/claude-code 2>&1 | tail -3
  if command -v claude &>/dev/null; then
    HAS_CLAUDE_CODE=true
    success "Claude Code installed"
  else
    warn "Install finished — you may need to restart your terminal"
  fi
}

install_git() {
  $HAS_GIT && return 0

  info "Installing ${WHITE}Git${RESET}..."
  case "$OS" in
    macos)
      xcode-select --install 2>/dev/null || true
      if ! $NON_INTERACTIVE; then
        printf "  Press Enter after Xcode CLI Tools installation completes..."
        read -r < /dev/tty
      fi
      ;;
    linux)
      case "$PKG_MGR" in
        apt)    sudo apt-get update -qq && sudo apt-get install -y -qq git ;;
        dnf)    sudo dnf install -y -q git ;;
        pacman) sudo pacman -S --noconfirm git ;;
        *)      warn "Cannot auto-install. Download: ${UNDERLINE}https://git-scm.com${RESET}"; return 1 ;;
      esac
      ;;
  esac

  if command -v git &>/dev/null; then
    HAS_GIT=true
    success "Git installed"
  else
    warn "Git installation may require restarting your terminal"
  fi
}

install_skills() {
  if ! command -v npx &>/dev/null; then
    warn "npx not available, skipping Skills installation"
    return 1
  fi

  if ! $HAS_OBSIDIAN_SKILLS; then
    info "Installing ${WHITE}kepano/obsidian-skills${RESET}..."
    if npx -y skills add kepano/obsidian-skills -g -y 2>&1 | tail -3; then
      success "kepano/obsidian-skills installed"
    else
      warn "kepano/obsidian-skills install failed"
    fi
  fi

  if ! $HAS_VISUAL_SKILLS; then
    info "Installing ${WHITE}axtonliu/axton-obsidian-visual-skills${RESET}..."
    if npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y 2>&1 | tail -3; then
      success "axtonliu/visual-skills installed"
    else
      warn "axtonliu/visual-skills install failed"
    fi
  fi
}

run_install() {
  [[ "$OS" == "macos" ]] && ! $HAS_BREW && ensure_brew

  install_obsidian
  install_node || true
  install_claude_code
  install_skills
  install_git
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
    info "Downloading template via ${WHITE}git${RESET}..."
    if git clone --depth 1 "$TEMPLATE_REPO_URL" "$tmpdir/repo" 2>&1 | tail -1; then
      if [[ -d "$tmpdir/repo/template/base" ]]; then
        LOCAL_TEMPLATE="$tmpdir/repo/template"
        downloaded=true
      fi
    fi
  fi

  # Fallback to curl tarball
  if ! $downloaded; then
    info "Downloading template via ${WHITE}curl${RESET}..."
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

download_plugin() {
  local repo="$1" plugin_id="$2" target_dir="$3"
  local plugin_dir="$target_dir/.obsidian/plugins/$plugin_id"
  local base_url="https://github.com/$repo/releases/latest/download"

  mkdir -p "$plugin_dir"

  local ok=true
  for file in main.js manifest.json; do
    if ! curl -fsSL "$base_url/$file" -o "$plugin_dir/$file" 2>/dev/null; then
      ok=false; break
    fi
  done
  curl -fsSL "$base_url/styles.css" -o "$plugin_dir/styles.css" 2>/dev/null || true

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

  local all_plugins=(
    "blacksmithgu/obsidian-dataview|dataview"
    "SilentVoid13/Templater|templater-obsidian"
    "Vinzent03/obsidian-git|obsidian-git"
    "platers/obsidian-linter|obsidian-linter"
    "pjeby/tag-wrangler|tag-wrangler"
    "TfTHacker/obsidian42-strange-new-worlds|obsidian42-strange-new-worlds"
    "mirnovov/obsidian-homepage|homepage"
    "SebastianMC/obsidian-custom-sort|custom-sort"
  )

  # Skip obsidian-git if Git is not available
  if ! $HAS_GIT; then
    info "Git not available — skipping ${WHITE}obsidian-git${RESET} plugin"
    local filtered=()
    for entry in "${all_plugins[@]}"; do
      [[ "$entry" == *"|obsidian-git" ]] && continue
      filtered+=("$entry")
    done
    all_plugins=("${filtered[@]}")
  fi

  info "Installing Obsidian plugins..."
  for entry in "${all_plugins[@]}"; do
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
    success "${#plugins_installed[@]} plugins configured"
  fi

  # Configure custom-sort plugin (must not be suspended)
  local cs_dir="$wiki_dir/.obsidian/plugins/custom-sort"
  if [[ -d "$cs_dir" && ! -f "$cs_dir/data.json" ]]; then
    cat > "$cs_dir/data.json" <<'CSJSON'
{"suspended":false,"statusBarEntryEnabled":true,"notificationsEnabled":true,"customSortContextSubmenu":true}
CSJSON
  fi
}

setup_wiki() {
  detect_clone_status

  case "$CLONE_STATUS" in
    in_template)
      LOCAL_TEMPLATE="$(pwd)/template"
      info "Set up your new wiki:"
      WIKI_LANG=$(prompt_language)
      WIKI_NAME="${WIKI_NAME:-my-wiki}"
      WIKI_NAME=$(prompt_input "Wiki name" "$WIKI_NAME")
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
      WIKI_NAME=$(prompt_input "Wiki name" "$WIKI_NAME")
      WIKI_TARGET="${WIKI_DIR:-${LLM_WIKI_DIR:-$WIKI_NAME}}"
      info "Location: ${CYAN}$(rel_path "$WIKI_TARGET")${RESET}"
      prepare_wiki "$WIKI_TARGET"
      ;;
  esac

  install_obsidian_plugins "$WIKI_TARGET"
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

  printf "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  printf "${BOLD}${GREEN}  ✓ %s is ready!${RESET}\n" "$name"
  printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  printf "\n${BOLD}Operations ${DIM}(inside Claude Code)${RESET}${BOLD}:${RESET}\n\n"
  printf "  ${MAGENTA}${BOLD}1. Ingest${RESET}  ${DIM}→${RESET}  ${WHITE}Ingest this article: https://example.com/article${RESET}\n"
  printf "             ${DIM}Add knowledge from URLs or files in${RESET} ${CYAN}raw/${RESET}\n"
  printf "  ${MAGENTA}${BOLD}2. Query${RESET}   ${DIM}→${RESET}  ${WHITE}What is the relationship between X and Y?${RESET}\n"
  printf "             ${DIM}Ask questions, get answers with citations${RESET}\n"
  printf "  ${MAGENTA}${BOLD}3. Lint${RESET}    ${DIM}→${RESET}  ${WHITE}Run a health check on the wiki${RESET}\n"
  printf "             ${DIM}Find orphans, dead links, stale pages${RESET}\n"

  printf "\n${BOLD}Quick start:${RESET}\n\n"
  local step_n=1
  if [[ "$abs_target" != "$(pwd)" ]]; then
    printf "  ${DIM}%d.${RESET} ${WHITE}cd %s${RESET}\n" "$step_n" "$(rel_path "$target")"
    step_n=$((step_n + 1))
  fi
  if [[ "$OS" == "macos" ]]; then
    printf "  ${DIM}%d.${RESET} ${WHITE}open -a Obsidian .${RESET}       ${DIM}# open as Obsidian vault${RESET}\n" "$step_n"
  else
    printf "  ${DIM}%d.${RESET} ${WHITE}obsidian .${RESET}               ${DIM}# open as Obsidian vault${RESET}\n" "$step_n"
  fi
  step_n=$((step_n + 1))
  printf "  ${DIM}%d.${RESET} ${WHITE}claude${RESET}                   ${DIM}# start AI agent${RESET}\n" "$step_n"
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
      --non-interactive) NON_INTERACTIVE=true; shift ;;
      --skip-install)    SKIP_INSTALL=true; shift ;;
      --help|-h)         usage; exit 0 ;;
      --version|-v)      echo "llm-wiki-starter v$VERSION"; exit 0 ;;
      *)                 warn "Unknown option: $1"; shift ;;
    esac
  done
}

usage() {
  cat <<'EOF'
llm-wiki-starter — Create an LLM Wiki knowledge base in one command

Usage:
  curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
  bash install.sh [OPTIONS]

Options:
  --name <name>        Wiki name (default: my-wiki)
  --dir <directory>    Target directory (default: ./<name>)
  --lang <zh|en>       Wiki language (default: zh)
  --non-interactive    Skip all prompts, use defaults
  --skip-install       Only create wiki structure, skip tool installation
  --help               Show this help
  --version            Show version

Environment:
  LLM_WIKI_DIR         Target directory (same as --dir)

Examples:
  # Interactive install
  bash install.sh

  # Non-interactive install
  bash install.sh --non-interactive --name my-ai-wiki

  # Structure only (no tools)
  bash install.sh --name test-wiki --dir /tmp/test-wiki --skip-install
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  printf "\n${BOLD}┌──────────────────────────────────────────────────┐${RESET}\n"
  printf "${BOLD}│  ${BLUE}LLM Wiki Starter${RESET}${BOLD} v%-30s│${RESET}\n" "$VERSION"
  printf "${BOLD}│  ${DIM}Knowledge base scaffolding for LLM Wiki${RESET}${BOLD}         │${RESET}\n"
  printf "${BOLD}└──────────────────────────────────────────────────┘${RESET}\n\n"

  detect_os
  info "OS: ${WHITE}$OS${RESET}  |  Package manager: ${WHITE}${PKG_MGR:-none}${RESET}"

  # ── Detect first, then determine step count ──
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
