#!/bin/bash
set -euo pipefail

#
# install.sh — Install LCLS AI skills for Claude Code or OpenCode
#
# Usage:
#   ./install.sh --target DIR skill-name [skill-name ...]
#   ./install.sh --target DIR --all
#   ./install.sh --list
#
# Examples:
#   ./install.sh --target ~/.claude/skills ask-s3df
#   ./install.sh --target "$OPENCODE_CONFIG_DIR/skills" ask-s3df ask-olcf
#   ./install.sh --target ~/.claude/skills --all

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="$SCRIPT_DIR/registry.json"

# --- Helpers ---

die() { echo "Error: $1" >&2; exit 1; }

check_jq() {
    if ! command -v jq &>/dev/null; then
        die "jq is required. Install it: https://jqlang.github.io/jq/download/"
    fi
}

list_skills() {
    check_jq
    echo "Available skills:"
    echo ""
    jq -r '.skills | to_entries[] | "  \(.key)\t\(.value.description)"' "$REGISTRY" | column -t -s $'\t'
    echo ""
    echo "Usage: $(basename "$0") --target DIR skill-name [skill-name ...]"
}

install_skill() {
    local skill_name="$1"
    local target_dir="$2"
    local skill_dir="$target_dir/$skill_name"

    local repo
    repo=$(jq -r ".skills[\"$skill_name\"].repo // empty" "$REGISTRY")
    if [ -z "$repo" ]; then
        die "Unknown skill: $skill_name. Run with --list to see available skills."
    fi

    # Install dependencies first
    local deps
    deps=$(jq -r ".skills[\"$skill_name\"].requires[]? // empty" "$REGISTRY")
    for dep in $deps; do
        case "$dep" in
            uv)
                if ! command -v uv &>/dev/null; then
                    echo "  WARNING: uv not found. Install: https://docs.astral.sh/uv/"
                fi
                ;;
            tree-sitter-db)
                echo "  NOTE: $skill_name requires tree-sitter-db. See its README for setup."
                ;;
            docs-search)
                if [ ! -d "$target_dir/docs-search" ]; then
                    echo "  Installing dependency: docs-search..."
                    install_skill "docs-search" "$target_dir"
                fi
                ;;
        esac
    done

    # Clone or update
    if [ -d "$skill_dir/.git" ]; then
        echo "  Updating $skill_name..."
        git -C "$skill_dir" pull --ff-only
    elif [ -d "$skill_dir" ]; then
        echo "  $skill_name exists but is not a git repo. Skipping."
        return
    else
        echo "  Installing $skill_name..."
        git clone "$repo" "$skill_dir"
    fi

    # Offer to run setup
    local has_setup
    has_setup=$(jq -r ".skills[\"$skill_name\"].has_setup" "$REGISTRY")
    if [[ "$has_setup" == "true" && -f "$skill_dir/setup.sh" ]]; then
        echo ""
        read -p "  Run setup for $skill_name? (clones data, builds index) [y/N] " yn
        if [[ "$yn" =~ ^[Yy] ]]; then
            bash "$skill_dir/setup.sh"
        else
            echo "  Skipping setup. Run later: bash $skill_dir/setup.sh"
        fi
    fi

    echo "  Done: $skill_name"
}

# --- Main ---

TARGET_DIR=""
SKILLS=()
ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET_DIR="$2"; shift 2 ;;
        --all) ALL=true; shift ;;
        --list|-l) list_skills; exit 0 ;;
        -h|--help)
            echo "Usage: $(basename "$0") --target DIR [--all] [skill-name ...]"
            echo ""
            echo "Options:"
            echo "  --target DIR   Install to DIR (required)"
            echo "  --all          Install all skills"
            echo "  --list, -l     List available skills"
            echo "  -h, --help     Show this help"
            exit 0 ;;
        -*) die "Unknown option: $1" ;;
        *) SKILLS+=("$1"); shift ;;
    esac
done

check_jq

# Require --target
if [ -z "$TARGET_DIR" ]; then
    die "--target DIR is required. Example: $(basename "$0") --target ~/.claude/skills ask-s3df"
fi

mkdir -p "$TARGET_DIR"
echo "Installing to: $TARGET_DIR"
echo ""

# Collect skill names
if $ALL; then
    mapfile -t SKILLS < <(jq -r '.skills | keys[]' "$REGISTRY")
fi

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "No skills specified. Use --all or provide skill names."
    echo ""
    list_skills
    exit 1
fi

# Install each skill
for skill in "${SKILLS[@]}"; do
    install_skill "$skill" "$TARGET_DIR"
    echo ""
done

echo "All done. Skills installed to: $TARGET_DIR"
