#!/bin/bash

# Antigravity AntigravityPolyglot: Interactive Lifecycle Manager
# This script provides a modern, interactive TUI for managing AntigravityPolyglot.

# --- Colors & UI Elements ---
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
DIM='\033[2m'
NC='\033[0m' # No Color
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# ASCII Art Logo (Clean & Complete)
LOGO="${CYAN}
   ___          _   _                      _ _         ____       _             _       _
  / _ \   _ __ | |_(_) __ _ _ __ __ ___   (_) |_ _   _|  _ \  ___ | | ___   ___ | | ___ | |_
 / /_\ \ | '_ \| __| |/ _\` | '__/ _\` \ \ / / | __| | | | |_) |/ _ \| |/ _ \ / _ \| |/ _ \| __|
/ /   \ \| | | | |_| | (_| | | | (_| |\ V /| | |_| |_| |  __/| (_) | | (_) | (_) | | (_) | |_
\/     \/\_| |_|\__|_|\__, |_|  \__,_| \_/ |_|\__|\__, |_|    \___/|_|\___/ \___/|_|\___/ \__|
                      |___/                      |___/
${NC}"

BANNER="$LOGO
${DIM}          The multilingual bridge for AI agents.${NC}
─────────────────────────────────────────────────────────────
"

GLOBAL_GEMINI_MD="$HOME/.gemini/GEMINI.md"
[ ! -f "$GLOBAL_GEMINI_MD" ] && [ -f "$HOME/.gemini/gemini.md" ] && GLOBAL_GEMINI_MD="$HOME/.gemini/gemini.md"

WORKSPACE_GEMINI_MD="./GEMINI.md"
[ ! -f "$WORKSPACE_GEMINI_MD" ] && [ -f "./gemini.md" ] && WORKSPACE_GEMINI_MD="./gemini.md"

BIN_DEST="/usr/local/bin/antigravity-polyglot"
INTEGRATION_MARKER="## AntigravityPolyglot Integration"
INTEGRATION_PROMPT="- Proactively check every activated skill and user request for foreign agent signatures (Claude MCP mcp__, Codex JSON tools, Cursor .cursorrules, or unknown tool calls). If any non-Gemini/non-Antigravity agent patterns are detected, you MUST immediately delegate to the 'antigravity-polyglot' subagent to translate schemas and rules, keeping your active context clean."

# --- Helper Logic ---

# Resolve the actual script directory, following symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_REAL_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

print_summary() {
    local title=$1
    local final_msg=$2
    shift 2
    local items=("$@")
    
    echo -e "\n${BOLD}$title Summary:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    for item in "${items[@]}"; do
        echo -e "  $item"
    done
    echo "─────────────────────────────────────────────────────────────"
    echo -e "\n${GREEN}${BOLD}$final_msg${NC}"
}

exit_prompt() {
    echo -e "\n${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}Press any key to exit AntigravityPolyglot Manager...${NC}"
    read -n 1 -s
    echo ""
    exit 0
}

write_subagent_files() {
    local dest_dir=$1
    mkdir -p "$dest_dir"
    
    # Clean copy from the package's resolved agents template folder
    local src_dir="$SCRIPT_REAL_DIR/../agents/antigravity-polyglot"
    
    if [ -d "$src_dir" ]; then
        cp "$src_dir/agent.json" "$dest_dir/agent.json"
        cp "$src_dir/antigravity-polyglot.md" "$dest_dir/antigravity-polyglot.md"
    else
        echo -e "${RED}❌ Error: Subagent template directory not found at $src_dir${NC}"
        return 1
    fi
}

# --- Core Logic Functions ---

do_install() {
    SCOPE=$1
    local summary=()
    
    # Locate the .skill file relative to the resolved script directory
    SKILL_FILE="$SCRIPT_REAL_DIR/../dist/antigravity-polyglot.skill"
    
    if [ ! -f "$SKILL_FILE" ]; then
        # Fallback for development/manual runs
        SKILL_FILE="./dist/antigravity-polyglot.skill"
    fi
    
    if [ ! -f "$SKILL_FILE" ]; then
        echo -e "${RED}❌ Error: .skill file not found at $SKILL_FILE${NC}"
        return 1
    fi

    echo -e "${CYAN}🚀 Initializing installation ($SCOPE)...${NC}"
    
    # 1. Install Skill
    if echo "y" | gemini skills install "$SKILL_FILE" --scope "$SCOPE" > /dev/null 2>&1; then
        summary+=("${GREEN}✅ Skill Package Installed${NC}")
    else
        summary+=("${RED}❌ Skill Package Failed${NC}")
    fi
    
    # 2. Add Integration
    FILE="$WORKSPACE_GEMINI_MD"
    [ "$SCOPE" == "user" ] && FILE="$GLOBAL_GEMINI_MD"
    [ ! -f "$FILE" ] && touch "$FILE"
    
    if ! grep -q "$INTEGRATION_MARKER" "$FILE"; then
        echo -e "\n$INTEGRATION_MARKER\n$INTEGRATION_PROMPT" >> "$FILE"
        summary+=("${GREEN}✅ Linguistic Integration Injected${NC}")
    else
        summary+=("${YELLOW}➖ Integration already exists (Skipped)${NC}")
    fi
    
    # 3. Dynamic Hook & Subagent Registration
    if [ "$SCOPE" == "user" ]; then
        # Option B: Global CLI Hook registration
        if [ ! -f "$BIN_DEST" ]; then
            if [ -w "/usr/local/bin" ]; then
                ln -sf "$(realpath "$0")" "$BIN_DEST"
                summary+=("${GREEN}✅ CLI Binary Linked to PATH${NC}")
            else
                summary+=("${YELLOW}💡 Manual link needed: sudo ln -sf $(realpath "$0") $BIN_DEST${NC}")
            fi
        else
            summary+=("${YELLOW}➖ CLI Binary already linked (Skipped)${NC}")
        fi
        
        # Scaffold global subagent by copying templates
        if write_subagent_files "$HOME/.gemini/agents/antigravity-polyglot"; then
            summary+=("${GREEN}✅ Global Subagent Registered in ~/.gemini/agents/${NC}")
        else
            summary+=("${RED}❌ Global Subagent Files Failed to Copy${NC}")
        fi
        
        # Register global pre-execution hook
        if gemini hooks register --event pre-execution --command "python3 $HOME/.gemini/skills/antigravity-polyglot/scripts/detect_patterns.py \"\$PWD\"" > /dev/null 2>&1; then
            summary+=("${GREEN}✅ Global Pre-Execution Hook Registered${NC}")
        else
            summary+=("${YELLOW}➖ Global Hook registration not supported (Skipped)${NC}")
        fi
    else
        # Option C: Local Workspace Shell Hook Interceptor & Workspace Subagent
        LOCAL_HOOK_DIR="./.agents/hooks"
        LOCAL_HOOK_FILE="$LOCAL_HOOK_DIR/pre-exec.sh"
        mkdir -p "$LOCAL_HOOK_DIR"
        
        # Write workspace-scoped hook
        cat << 'EOF' > "$LOCAL_HOOK_FILE"
#!/bin/bash
# AntigravityPolyglot: Workspace Pre-Execution Hook
# Deterministically scans the active workspace for foreign agent rules before any tool run.
if [ -f "$HOME/.gemini/skills/antigravity-polyglot/scripts/detect_patterns.py" ]; then
    python3 "$HOME/.gemini/skills/antigravity-polyglot/scripts/detect_patterns.py" "$PWD"
fi
EOF
        chmod +x "$LOCAL_HOOK_FILE"
        summary+=("${GREEN}✅ Workspace Pre-Execution Hook Written to .agents/hooks/${NC}")
        
        # Scaffold workspace subagent by copying templates
        if write_subagent_files "./.agents/agents/antigravity-polyglot"; then
            summary+=("${GREEN}✅ Workspace Subagent Registered in .agents/agents/${NC}")
        else
            summary+=("${RED}❌ Workspace Subagent Files Failed to Copy${NC}")
        fi
    fi

    clear
    echo -e "$BANNER"
    print_summary "Installation" "✨ All set! Antigravity now speaks every AI language." "${summary[@]}"
    echo -e "\n${BOLD}Please reload your Antigravity session to enable the polyglot capabilities.${NC}"
    exit_prompt
}

do_uninstall() {
    SCOPE=$1
    local summary=()
    local IS_BREW=false
    echo -e "${CYAN}🧹 Initializing uninstallation ($SCOPE)...${NC}"

    # 1. Detect Homebrew
    if brew list antigravity-polyglot &>/dev/null; then
        IS_BREW=true
    fi

    # 2. Uninstall Skill
    if echo "y" | gemini skills uninstall antigravity-polyglot --scope "$SCOPE" > /dev/null 2>&1; then
        summary+=("${GREEN}✅ Skill Package Removed${NC}")
    else
        summary+=("${YELLOW}➖ Skill not found (Skipped)${NC}")
    fi
    
    # 3. Remove Integration
    FILE="$WORKSPACE_GEMINI_MD"
    [ "$SCOPE" == "user" ] || [ "$SCOPE" == "global" ] && FILE="$GLOBAL_GEMINI_MD"
    if [ -f "$FILE" ]; then
        sed "/$INTEGRATION_MARKER/,/$INTEGRATION_PROMPT/d" "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
        summary+=("${GREEN}✅ Linguistic Integration Removed${NC}")
    fi
    
    # 4. Remove Binary & Hooks & Subagents
    if [ "$SCOPE" == "user" ] || [ "$SCOPE" == "global" ]; then
        if [ -f "$BIN_DEST" ]; then
            if [ "$IS_BREW" = false ]; then
                if [ -w "$BIN_DEST" ]; then
                    rm "$BIN_DEST"
                    summary+=("${GREEN}✅ CLI Binary Unlinked${NC}")
                fi
            else
                summary+=("${DIM}➖ Binary managed by Homebrew (Deferred)${NC}")
            fi
        fi
        
        # Remove global subagent
        if [ -d "$HOME/.gemini/agents/antigravity-polyglot" ]; then
            rm -rf "$HOME/.gemini/agents/antigravity-polyglot"
            summary+=("${GREEN}✅ Global Subagent Files Removed${NC}")
        fi
        
        # Unregister global pre-execution hook
        if gemini hooks unregister --event pre-execution > /dev/null 2>&1; then
            summary+=("${GREEN}✅ Global Pre-Execution Hook Unregistered${NC}")
        fi
    else
        # Remove workspace hook
        LOCAL_HOOK_FILE="./.agents/hooks/pre-exec.sh"
        if [ -f "$LOCAL_HOOK_FILE" ]; then
            rm "$LOCAL_HOOK_FILE"
            summary+=("${GREEN}✅ Workspace Pre-Execution Hook Removed${NC}")
        fi
        
        # Remove local hook directory if empty
        if [ -d "./.agents/hooks" ] && [ -z "$(ls -A ./.agents/hooks 2>/dev/null)" ]; then
            rmdir "./.agents/hooks"
        fi
        
        # Remove workspace subagent
        if [ -d "./.agents/agents/antigravity-polyglot" ]; then
            rm -rf "./.agents/agents/antigravity-polyglot"
            summary+=("${GREEN}✅ Workspace Subagent Files Removed${NC}")
        fi
    fi

    clear
    echo -e "$BANNER"
    print_summary "Uninstallation" "🗑️ AntigravityPolyglot has been successfully cleaned up." "${summary[@]}"
    
    if [ "$IS_BREW" = true ]; then
        echo -e "\n${CYAN}Homebrew installation detected. Triggering Homebrew uninstallation...${NC}"
        
        if brew uninstall antigravity-polyglot; then
            echo -e "${GREEN}✅ Homebrew uninstallation succeeded.${NC}"
            
            REMAINING=$(brew formulae --tap BrunoNFL/taps 2>/dev/null | wc -l | xargs)
            if [ "$REMAINING" -eq 0 ]; then
                echo -e "${DIM}No other formulae found in BrunoNFL/taps. Untapping...${NC}"
                brew untap BrunoNFL/taps > /dev/null 2>&1
                echo -e "${GREEN}✅ Untapped BrunoNFL/taps.${NC}"
            fi
        else
            echo -e "${RED}❌ Homebrew uninstallation failed.${NC}"
        fi
        exit 0
    fi
    
    exit_prompt
}

# --- Interactive Menu Engine ---

select_option() {
    local title=$1
    shift
    local options=("$@")
    local current=0
    local count=${#options[@]}

    echo -ne "$HIDE_CURSOR"
    
    while true; do
        clear
        echo -e "$BANNER"
        echo -e "${BOLD}$title${NC}"
        echo ""
        
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current" ]; then
                echo -e "  ${CYAN}▶ ${BOLD}${options[$i]}${NC}"
            else
                echo -e "    ${DIM}${options[$i]}${NC}"
            fi
        done
        
        echo -e "\n${DIM}─────────────────────────────────────────────────────────────${NC}"
        echo -e "${DIM}Use [↑/↓] to navigate, [Enter] to select${NC}"
        
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key == "[A" ]]; then # Up
                ((current--))
                [ "$current" -lt 0 ] && current=$((count - 1))
            elif [[ $key == "[B" ]]; then # Down
                ((current++))
                [ "$current" -ge "$count" ] && current=0
            fi
        elif [[ $key == "" ]]; then # Enter
            SELECTED_INDEX=$current
            echo -ne "$SHOW_CURSOR"
            return
        fi
    done
}

# --- Main Entry Point ---

if [ "$1" != "" ]; then
    case "$1" in
        "--install-global") do_install "user" ;;
        "--uninstall-global") do_uninstall "user" ;;
        "--install-workspace") do_install "workspace" ;;
        "--uninstall-workspace") do_uninstall "workspace" ;;
        *) echo "Usage: antigravity-polyglot [--install-global|--uninstall-global|--install-workspace|--uninstall-workspace]" ;;
    esac
    exit 0
fi

while true; do
    select_option "What would you like to do?" "Install AntigravityPolyglot" "Uninstall AntigravityPolyglot" "Exit"
    
    case "$SELECTED_INDEX" in
        0) # Install
            select_option "Choose Installation Scope:" "Global (User-level, everywhere)" "Workspace (Current directory only)" "Back"
            case "$SELECTED_INDEX" in
                0) do_install "user" ;;
                1) do_install "workspace" ;;
            esac
            ;;
        1) # Uninstall Detection
            IS_GLOBAL=false; IS_WORKSPACE=false
            gemini skills list 2>/dev/null | grep -q "antigravity-polyglot" && [ -f "$GLOBAL_GEMINI_MD" ] && grep -q "$INTEGRATION_MARKER" "$GLOBAL_GEMINI_MD" && IS_GLOBAL=true
            [ -f "$WORKSPACE_GEMINI_MD" ] && grep -q "$INTEGRATION_MARKER" "$WORKSPACE_GEMINI_MD" && IS_WORKSPACE=true
            
            if [ "$IS_GLOBAL" = true ] && [ "$IS_WORKSPACE" = true ]; then
                select_option "Multiple installations found:" "Uninstall Global" "Uninstall Workspace" "Both" "Back"
                case "$SELECTED_INDEX" in
                    0) do_uninstall "user" ;;
                    1) do_uninstall "workspace" ;;
                    2) do_uninstall "user"; do_uninstall "workspace" ;;
                esac
            elif [ "$IS_GLOBAL" = true ]; then do_uninstall "user"
            elif [ "$IS_WORKSPACE" = true ]; then do_uninstall "workspace"
            else
                clear; echo -e "$BANNER"; echo -e "${YELLOW}⚠️  No installation found in Global or Workspace scope.${NC}"; exit_prompt
            fi
            ;;
        2) exit 0 ;;
    esac
done
