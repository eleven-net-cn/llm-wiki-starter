#!/usr/bin/env bash
# llm-wiki-starter — 一行命令创建 LLM Wiki 知识库
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash
#   bash install.sh [--name <name>] [--dir <dir>] [--non-interactive] [--skip-suites]
#
# 职责：检测/clone 模板 → 安装套件 → 配置插件/Skills → 清理自身

set -euo pipefail

VERSION="2.0.0"
TEMPLATE_REPO="axtonliu/llm-wiki-starter"
TEMPLATE_REPO_URL="https://github.com/$TEMPLATE_REPO"

# ─── State ────────────────────────────────────────────────────────────────────

OS=""
PKG_MGR=""
LOCAL_TEMPLATE=""
NON_INTERACTIVE=false
SKIP_SUITES=false
WIKI_NAME=""
WIKI_DIR=""
WIKI_TARGET=""

# ─── Colors (auto-disable for non-TTY) ───────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

[[ ! -t 1 ]] && RED='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' RESET=''

info()    { printf "${CYAN}→${RESET} %s\n" "$1"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$1"; }
warn()    { printf "${YELLOW}⚠${RESET} %s\n" "$1"; }
fail()    { printf "${RED}✗ %s${RESET}\n" "$1" >&2; exit 1; }
step()    { printf "\n${BOLD}[%s] %s${RESET}\n" "$1" "$2"; }

# ─── Interactive Prompts (bash 3.2 compatible) ────────────────────────────────

prompt_input() {
  local question="$1" default="$2" result
  if $NON_INTERACTIVE; then echo "$default"; return; fi
  printf "%s [%s]: " "$question" "$default"
  read -r result
  echo "${result:-$default}"
}

prompt_confirm() {
  local question="$1" default="${2:-Y}" result lower
  if $NON_INTERACTIVE; then
    [[ "$default" == "Y" ]] && return 0 || return 1
  fi
  if [[ "$default" == "Y" ]]; then
    printf "%s [Y/n]: " "$question"
  else
    printf "%s [y/N]: " "$question"
  fi
  read -r result
  result="${result:-$default}"
  lower=$(echo "$result" | tr '[:upper:]' '[:lower:]')
  [[ "$lower" == "y" || "$lower" == "yes" ]]
}

prompt_select() {
  local question="$1" default="$2"
  shift 2
  local options=("$@")
  if $NON_INTERACTIVE; then echo "$default"; return; fi
  printf "%s\n" "$question"
  local i=1
  for opt in "${options[@]}"; do
    printf "  %d) %s\n" "$i" "$opt"
    i=$((i + 1))
  done
  printf "选择 [1-%d]: " "${#options[@]}"
  read -r result
  echo "${result:-$default}"
}

# ─── OS Detection ─────────────────────────────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Darwin*) OS="macos" ;;
    Linux*)  OS="linux" ;;
    *)       fail "不支持的系统: $(uname -s)" ;;
  esac

  if [[ "$OS" == "macos" ]]; then
    command -v brew &>/dev/null && PKG_MGR="brew"
  elif [[ "$OS" == "linux" ]]; then
    if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
    elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
    elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
    fi
  fi

  info "系统: $OS | 包管理: ${PKG_MGR:-未检测到}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 1: Ensure Git
# ═══════════════════════════════════════════════════════════════════════════════

ensure_git() {
  if command -v git &>/dev/null; then
    success "Git $(git --version | awk '{print $3}')"
    return 0
  fi

  warn "Git 未安装"

  if [[ "$OS" == "macos" ]]; then
    info "通过 Xcode Command Line Tools 安装 Git..."
    xcode-select --install 2>/dev/null || true
    if ! $NON_INTERACTIVE; then
      printf "  安装完成后按 Enter 继续..."
      read -r
    fi
  elif [[ -n "$PKG_MGR" ]]; then
    info "通过 $PKG_MGR 安装 Git..."
    case "$PKG_MGR" in
      apt)    sudo apt-get update -qq && sudo apt-get install -y -qq git ;;
      dnf)    sudo dnf install -y -q git ;;
      pacman) sudo pacman -S --noconfirm git ;;
    esac
  fi

  command -v git &>/dev/null || fail "Git 安装失败，请手动安装后重试"
  success "Git 已安装"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 2: Detect Clone Status & Prepare Wiki
# ═══════════════════════════════════════════════════════════════════════════════

# Returns via CLONE_STATUS:
#   "in_template"   — inside template repo (has install.sh + template/)
#   "in_wiki"       — inside an existing wiki (has CLAUDE.md + raw/ + wiki/)
#   "need_clone"    — need to clone/copy template
detect_clone_status() {
  CLONE_STATUS="need_clone"

  # Inside the template repo itself (has template/ dir and install.sh)
  if [[ -f "install.sh" && -d "template" && -f "template/CLAUDE.md" ]]; then
    CLONE_STATUS="in_template"
    return
  fi

  # Inside an already-initialized wiki
  if [[ -f "CLAUDE.md" && -d "raw" && -d "wiki" ]]; then
    CLONE_STATUS="in_wiki"
    return
  fi
}

detect_dev_mode() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || return 1
  if [[ -d "$script_dir/template" && -f "$script_dir/template/CLAUDE.md" ]]; then
    LOCAL_TEMPLATE="$script_dir/template"
    return 0
  fi
  return 1
}

prepare_wiki() {
  local target="$1"

  if [[ -d "$target" && -f "$target/CLAUDE.md" ]]; then
    warn "目录 $target 已存在且包含 Wiki，跳过创建"
    return 0
  fi
  [[ -d "$target" ]] && fail "目录 $target 已存在，请指定其他名称或删除后重试"

  if [[ -n "$LOCAL_TEMPLATE" ]]; then
    info "复制本地模板（开发模式）..."
    cp -r "$LOCAL_TEMPLATE" "$target"
  else
    info "从 GitHub 下载模板..."
    local tmpdir
    tmpdir=$(mktemp -d)
    if git clone --depth 1 "$TEMPLATE_REPO_URL" "$tmpdir/repo" 2>&1 | tail -1; then
      if [[ -d "$tmpdir/repo/template" ]]; then
        cp -r "$tmpdir/repo/template" "$target"
      else
        rm -rf "$tmpdir"
        fail "模板结构异常，请检查仓库"
      fi
    else
      rm -rf "$tmpdir"
      fail "下载失败，请检查网络连接"
    fi
    rm -rf "$tmpdir"
  fi

  success "Wiki 结构已创建: $target"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 3: Install Required Suites
# ═══════════════════════════════════════════════════════════════════════════════

ensure_brew() {
  [[ "$OS" != "macos" ]] && return 0
  command -v brew &>/dev/null && return 0

  warn "Homebrew 未安装"
  if prompt_confirm "安装 Homebrew（macOS 包管理器）？" "Y"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)" || true
    PKG_MGR="brew"
    success "Homebrew 已安装"
  else
    warn "跳过 Homebrew — 部分套件需手动安装"
  fi
}

ensure_node() {
  if command -v node &>/dev/null; then
    success "Node.js $(node --version)"
    return 0
  fi

  warn "Node.js 未安装（Claude Code 需要）"
  if prompt_confirm "安装 Node.js？" "Y"; then
    case "$PKG_MGR" in
      brew)   brew install node ;;
      apt)    sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm ;;
      dnf)    sudo dnf install -y -q nodejs npm ;;
      pacman) sudo pacman -S --noconfirm nodejs npm ;;
      *)      warn "无法自动安装 Node.js，请手动安装"; return 1 ;;
    esac
    success "Node.js 已安装"
  else
    warn "跳过 Node.js"
    return 1
  fi
}

install_claude_code() {
  if command -v claude &>/dev/null; then
    success "Claude Code ✓"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    warn "npm 不可用，跳过 Claude Code"
    printf "  手动安装: ${DIM}npm install -g @anthropic-ai/claude-code${RESET}\n"
    return 1
  fi

  if prompt_confirm "安装 Claude Code（LLM Wiki 的 AI Agent）？" "Y"; then
    info "安装 Claude Code..."
    npm install -g @anthropic-ai/claude-code 2>&1 | tail -3
    if command -v claude &>/dev/null; then
      success "Claude Code 已安装"
    else
      warn "安装完成，可能需要重开终端生效"
    fi
  else
    warn "跳过 Claude Code"
    printf "  手动安装: ${DIM}npm install -g @anthropic-ai/claude-code${RESET}\n"
  fi
}

install_obsidian() {
  # macOS check
  if [[ "$OS" == "macos" && -d "/Applications/Obsidian.app" ]]; then
    success "Obsidian ✓"
    return 0
  fi
  # Linux check
  if [[ "$OS" == "linux" ]] && command -v obsidian &>/dev/null; then
    success "Obsidian ✓"
    return 0
  fi

  warn "Obsidian 未安装"
  if prompt_confirm "安装 Obsidian（推荐的 Wiki 编辑器）？" "Y"; then
    case "$OS" in
      macos)
        if [[ "$PKG_MGR" == "brew" ]]; then
          brew install --cask obsidian
          success "Obsidian 已安装"
        else
          warn "请从 https://obsidian.md 手动下载安装"
        fi
        ;;
      linux)
        if command -v snap &>/dev/null; then
          sudo snap install obsidian --classic
          success "Obsidian 已安装"
        else
          warn "请从 https://obsidian.md 手动下载安装"
        fi
        ;;
    esac
  else
    warn "跳过 Obsidian"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 4: Obsidian Plugins
# ═══════════════════════════════════════════════════════════════════════════════

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
  # styles.css is optional
  curl -fsSL "$base_url/styles.css" -o "$plugin_dir/styles.css" 2>/dev/null || true

  if $ok && [[ -s "$plugin_dir/manifest.json" ]]; then
    printf "  ${GREEN}✓${RESET} %s\n" "$plugin_id"
    return 0
  else
    rm -rf "$plugin_dir"
    printf "  ${YELLOW}⚠${RESET} %s 下载失败\n" "$plugin_id"
    return 1
  fi
}

install_obsidian_plugins() {
  local wiki_dir="$1"
  local plugins_installed=()

  mkdir -p "$wiki_dir/.obsidian/plugins"

  # ── 必装插件 ──
  local required_plugins=(
    "blacksmithgu/obsidian-dataview|dataview"
    "SilentVoid13/Templater|templater-obsidian"
    "Vinzent03/obsidian-git|obsidian-git"
    "platers/obsidian-linter|obsidian-linter"
  )

  info "安装必装插件..."
  for entry in "${required_plugins[@]}"; do
    local repo="${entry%%|*}" id="${entry##*|}"
    if [[ -d "$wiki_dir/.obsidian/plugins/$id" ]]; then
      printf "  ${GREEN}✓${RESET} %s 已存在\n" "$id"
      plugins_installed+=("$id")
      continue
    fi
    download_plugin "$repo" "$id" "$wiki_dir" && plugins_installed+=("$id")
  done

  # ── 推荐插件 ──
  if prompt_confirm "安装推荐插件（Tag Wrangler / Strange New Worlds / Homepage）？" "Y"; then
    info "安装推荐插件..."
    local recommended_plugins=(
      "pjeby/tag-wrangler|tag-wrangler"
      "TfTHacker/obsidian42-strange-new-worlds|obsidian42-strange-new-worlds"
      "mirnovov/obsidian-homepage|homepage"
    )
    for entry in "${recommended_plugins[@]}"; do
      local repo="${entry%%|*}" id="${entry##*|}"
      if [[ -d "$wiki_dir/.obsidian/plugins/$id" ]]; then
        printf "  ${GREEN}✓${RESET} %s 已存在\n" "$id"
        plugins_installed+=("$id")
        continue
      fi
      download_plugin "$repo" "$id" "$wiki_dir" && plugins_installed+=("$id")
    done
  fi

  # ── Write community-plugins.json ──
  if [[ ${#plugins_installed[@]} -gt 0 ]]; then
    local json="["
    local first=true
    for id in "${plugins_installed[@]}"; do
      if $first; then first=false; else json+=","; fi
      json+="\"$id\""
    done
    json+="]"
    echo "$json" > "$wiki_dir/.obsidian/community-plugins.json"
    success "${#plugins_installed[@]} 个插件已配置"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 5: Claude Code Skills
# ═══════════════════════════════════════════════════════════════════════════════

install_skill_repo() {
  local repo_url="$1" repo_name="$2" skills_dir="$3"
  local tmpdir
  tmpdir=$(mktemp -d)
  info "安装 $repo_name..."
  if git clone --depth 1 "$repo_url" "$tmpdir/repo" 2>&1 | tail -1; then
    if [[ -d "$tmpdir/repo/skills" ]]; then
      cp -r "$tmpdir/repo/skills"/* "$skills_dir/"
    elif [[ -d "$tmpdir/repo" ]]; then
      # Some repos put skills at root level
      local copied=false
      for d in "$tmpdir/repo"/*/; do
        if [[ -f "$d/SKILL.md" || -f "$d/skill.md" ]]; then
          cp -r "$d" "$skills_dir/"
          copied=true
        fi
      done
      if ! $copied; then
        warn "$repo_name 结构不匹配，跳过"
        rm -rf "$tmpdir"
        return 1
      fi
    fi
    rm -rf "$tmpdir"
    success "$repo_name 已安装 → $skills_dir/"
  else
    rm -rf "$tmpdir"
    warn "$repo_name 安装失败"
    return 1
  fi
}

install_skills() {
  local skills_dir="$HOME/.claude/skills"
  mkdir -p "$skills_dir"

  # ── kepano/obsidian-skills ──
  local has_obsidian_skills=false
  if [[ -d "$skills_dir/obsidian-markdown" || -d "$skills_dir/obsidian-cli" ]]; then
    has_obsidian_skills=true
    success "kepano/obsidian-skills 已安装"
  fi

  # ── axtonliu/axton-obsidian-visual-skills ──
  local has_visual_skills=false
  if [[ -d "$skills_dir/excalidraw-diagram" || -d "$skills_dir/obsidian-canvas-creator" ]]; then
    has_visual_skills=true
    success "axtonliu/visual-skills 已安装"
  fi

  if $has_obsidian_skills && $has_visual_skills; then
    return 0
  fi

  if $NON_INTERACTIVE; then
    # Non-interactive: install all missing
    if ! $has_obsidian_skills; then
      install_skill_repo "https://github.com/kepano/obsidian-skills" "kepano/obsidian-skills" "$skills_dir"
    fi
    if ! $has_visual_skills; then
      install_skill_repo "https://github.com/axtonliu/axton-obsidian-visual-skills" "axtonliu/visual-skills" "$skills_dir"
    fi
    return 0
  fi

  local choice
  choice=$(prompt_select "安装 Claude Code Skills？（让 Agent 学会 Obsidian 操作和可视化）" "1" \
    "全部安装（推荐）" \
    "仅 kepano/obsidian-skills（Obsidian 核心能力）" \
    "仅 axtonliu/visual-skills（Excalidraw / Mermaid / Canvas）" \
    "跳过")

  case "$choice" in
    1)
      $has_obsidian_skills || install_skill_repo "https://github.com/kepano/obsidian-skills" "kepano/obsidian-skills" "$skills_dir"
      $has_visual_skills   || install_skill_repo "https://github.com/axtonliu/axton-obsidian-visual-skills" "axtonliu/visual-skills" "$skills_dir"
      ;;
    2)
      $has_obsidian_skills || install_skill_repo "https://github.com/kepano/obsidian-skills" "kepano/obsidian-skills" "$skills_dir"
      ;;
    3)
      $has_visual_skills   || install_skill_repo "https://github.com/axtonliu/axton-obsidian-visual-skills" "axtonliu/visual-skills" "$skills_dir"
      ;;
    4) info "跳过 Skills 安装" ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 6: Git Init & Cleanup
# ═══════════════════════════════════════════════════════════════════════════════

init_wiki_git() {
  local wiki_dir="$1" name="$2"

  cd "$wiki_dir"

  # Replace README placeholder
  if [[ -f "README.md" ]] && grep -q "<Wiki 名称>" "README.md" 2>/dev/null; then
    if [[ "$OS" == "macos" ]]; then
      sed -i '' "s/<Wiki 名称>/$name/g" README.md
    else
      sed -i "s/<Wiki 名称>/$name/g" README.md
    fi
  fi

  if [[ -d ".git" ]]; then
    success "Git 仓库已存在"
    return 0
  fi

  git init --quiet
  git add -A
  git commit --quiet -m "init: $name (via llm-wiki-starter v$VERSION)"
  success "Git 仓库已初始化"
}

cleanup_installer() {
  local wiki_dir="$1"
  # Remove install.sh from wiki dir (if copied from template repo)
  rm -f "$wiki_dir/install.sh" 2>/dev/null || true

  # If running from /tmp (curl | bash mode), clean up
  local script_path="${BASH_SOURCE[0]:-$0}"
  if [[ "$script_path" == "/tmp/"* ]]; then
    rm -f "$script_path" 2>/dev/null || true
  fi
}

# ─── CLI Args ─────────────────────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)            WIKI_NAME="$2"; shift 2 ;;
      --dir)             WIKI_DIR="$2"; shift 2 ;;
      --non-interactive) NON_INTERACTIVE=true; shift ;;
      --skip-suites)     SKIP_SUITES=true; shift ;;
      --help|-h)         usage; exit 0 ;;
      --version|-v)      echo "llm-wiki-starter v$VERSION"; exit 0 ;;
      *)                 warn "未知参数: $1"; shift ;;
    esac
  done
}

usage() {
  cat <<'EOF'
llm-wiki-starter — 一行命令创建 LLM Wiki 知识库

Usage:
  curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash
  bash install.sh [OPTIONS]

Options:
  --name <名称>        Wiki 名称（默认: my-wiki）
  --dir <目录>         目标目录（默认: ./<名称>）
  --non-interactive    跳过所有交互，使用默认值
  --skip-suites        跳过套件安装（仅创建 Wiki 结构）
  --help               显示帮助
  --version            显示版本

环境变量:
  LLM_WIKI_DIR         目标目录（等价于 --dir）

示例:
  # 交互式安装
  bash install.sh

  # 静默安装
  bash install.sh --non-interactive --name my-ai-wiki

  # 开发测试（跳过套件）
  bash install.sh --name test-wiki --dir /tmp/test-wiki --skip-suites
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  printf "\n${BOLD}┌──────────────────────────────────────────────────┐${RESET}\n"
  printf "${BOLD}│  LLM Wiki Starter v%-29s│${RESET}\n" "$VERSION"
  printf "${BOLD}│  基于 Karpathy LLM Wiki 模式的知识库脚手架       │${RESET}\n"
  printf "${BOLD}└──────────────────────────────────────────────────┘${RESET}\n\n"

  detect_os

  # ── 1. Git ──
  step "1/6" "检测 Git"
  ensure_git

  # ── 2. Wiki 结构 ──
  step "2/6" "准备 Wiki 结构"
  detect_clone_status

  case "$CLONE_STATUS" in
    in_template)
      info "已在模板仓库内，就地初始化"
      WIKI_NAME="${WIKI_NAME:-$(basename "$(pwd)")}"
      WIKI_NAME=$(prompt_input "知识库名称" "$WIKI_NAME")
      WIKI_TARGET="$(pwd)"
      ;;
    in_wiki)
      info "当前目录已是 LLM Wiki，跳过模板创建"
      WIKI_TARGET="$(pwd)"
      WIKI_NAME="${WIKI_NAME:-$(basename "$(pwd)")}"
      ;;
    need_clone)
      detect_dev_mode || true
      WIKI_NAME="${WIKI_NAME:-my-wiki}"
      WIKI_NAME=$(prompt_input "知识库名称" "$WIKI_NAME")
      WIKI_TARGET="${WIKI_DIR:-${LLM_WIKI_DIR:-$WIKI_NAME}}"
      prepare_wiki "$WIKI_TARGET"
      ;;
  esac

  if $SKIP_SUITES; then
    step "3-5" "跳过套件安装 (--skip-suites)"
  else
    # ── 3. 必备套件 ──
    step "3/6" "安装必备套件"
    [[ "$OS" == "macos" ]] && ensure_brew
    ensure_node || true
    install_claude_code
    install_obsidian

    # ── 4. Obsidian 插件 ──
    step "4/6" "Obsidian 插件"
    if prompt_confirm "自动安装 Obsidian 插件？" "Y"; then
      install_obsidian_plugins "$WIKI_TARGET"
    else
      warn "跳过插件安装"
      printf "  必装: Dataview, Templater, Obsidian Git, Linter\n"
      printf "  推荐: Tag Wrangler, Strange New Worlds, Homepage\n"
    fi

    # ── 5. Skills ──
    step "5/6" "Claude Code Skills"
    install_skills
  fi

  # ── 6. Git Init & Cleanup ──
  step "6/6" "初始化 Git 仓库"
  init_wiki_git "$WIKI_TARGET" "$WIKI_NAME"
  cleanup_installer "$WIKI_TARGET"

  # ── Done ──
  printf "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  printf "${BOLD}${GREEN}  ✓ %s 知识库就绪！${RESET}\n" "$WIKI_NAME"
  printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  printf "\n${BOLD}下一步:${RESET}\n"
  local abs_target
  abs_target="$(cd "$WIKI_TARGET" 2>/dev/null && pwd)" || abs_target="$WIKI_TARGET"
  if [[ "$abs_target" != "$(pwd)" ]]; then
    printf "  1. cd %s\n" "$WIKI_TARGET"
    printf "  2. open -a Obsidian .\n"
    printf "  3. claude\n"
  else
    printf "  1. open -a Obsidian .\n"
    printf "  2. claude\n"
  fi
  printf "  然后: ${DIM}帮我 ingest 这篇文章: <URL>${RESET}\n\n"
}

parse_args "$@"
main
