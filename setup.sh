#!/usr/bin/env bash
set -euo pipefail

# LLM Init Setup Script
# Usage: bash llm-init/setup.sh <project-name>
#
# Copies the llm-init template into your project, replacing {{PROJECT_NAME}}
# with the provided project name.

if [ $# -lt 1 ]; then
    echo "Usage: bash llm-init/setup.sh <project-name> [go-module-path]"
    echo "Example: bash llm-init/setup.sh my-awesome-app github.com/myorg/my-awesome-app"
    echo ""
    echo "Arguments:"
    echo "  project-name     Used for database names, container names, etc."
    echo "  go-module-path   Go module import path (default: github.com/yourorg/project-name)"
    exit 1
fi

PROJECT_NAME="$1"

# Validate project name (safe for database names, container names, sed substitutions)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: project-name must contain only letters, numbers, hyphens, and underscores"
    echo "  Got: '$PROJECT_NAME'"
    exit 1
fi

PROJECT_MODULE="${2:-github.com/yourorg/${PROJECT_NAME}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

echo "Setting up LLM infrastructure for: ${PROJECT_NAME}"
echo "Go module path: ${PROJECT_MODULE}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/plans"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/completed"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/templates"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/scripts"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/postgres"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/redis"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/nats"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/backlog"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/in_progress"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/completed"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/blocked"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/.locks"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/logs"
mkdir -p "${PROJECT_ROOT}/docs/spec/framework"
mkdir -p "${PROJECT_ROOT}/docs/spec/biz"
mkdir -p "${PROJECT_ROOT}/.claude/commands"

# Function to copy and replace placeholders
copy_template() {
    local src="$1"
    local dest="$2"
    if [ -f "${dest}" ]; then
        echo "  SKIP (exists): ${dest}"
        return
    fi
    # Escape forward slashes in MODULE for sed
    local escaped_module
    escaped_module=$(echo "${PROJECT_MODULE}" | sed 's/\//\\\//g')
    sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        -e "s/{{PROJECT_MODULE}}/${escaped_module}/g" \
        "${src}" > "${dest}"
    echo "  CREATED: ${dest}"
}

# Copy root config files
echo ""
echo "Copying root configuration files..."
copy_template "${SCRIPT_DIR}/templates/.mcp.json" "${PROJECT_ROOT}/.mcp.json"
copy_template "${SCRIPT_DIR}/templates/CLAUDE.md" "${PROJECT_ROOT}/CLAUDE.md"

# Copy Claude Code settings
echo ""
echo "Copying Claude Code settings..."
if [ ! -f "${PROJECT_ROOT}/.claude/settings.json" ]; then
    cp "${SCRIPT_DIR}/templates/.claude/settings.json" "${PROJECT_ROOT}/.claude/settings.json"
    echo "  CREATED: .claude/settings.json"
else
    echo "  SKIP (exists): .claude/settings.json"
fi

# Copy custom slash commands
echo ""
echo "Copying custom slash commands..."
for cmd in decompose.md new-task.md status.md launch.md plan.md review.md shelve.md; do
    if [ ! -f "${PROJECT_ROOT}/.claude/commands/${cmd}" ]; then
        cp "${SCRIPT_DIR}/templates/.claude/commands/${cmd}" "${PROJECT_ROOT}/.claude/commands/${cmd}"
        echo "  CREATED: .claude/commands/${cmd}"
    else
        echo "  SKIP (exists): .claude/commands/${cmd}"
    fi
done

# Set up .gitignore
echo ""
echo "Setting up .gitignore..."
if [ -f "${PROJECT_ROOT}/.gitignore" ]; then
    if grep -q ".claude/settings.local.json" "${PROJECT_ROOT}/.gitignore" 2>/dev/null; then
        echo "  SKIP: .gitignore already has llm exclusions"
    else
        echo "" >> "${PROJECT_ROOT}/.gitignore"
        cat "${SCRIPT_DIR}/templates/.gitignore" >> "${PROJECT_ROOT}/.gitignore"
        echo "  UPDATED: .gitignore (appended llm-init entries)"
    fi
else
    cp "${SCRIPT_DIR}/templates/.gitignore" "${PROJECT_ROOT}/.gitignore"
    echo "  CREATED: .gitignore"
fi

# Copy docs/spec files
echo ""
echo "Copying spec files..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/LLM.md" "${PROJECT_ROOT}/docs/spec/LLM.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/LLM-STYLE-GUIDE.md" "${PROJECT_ROOT}/docs/spec/LLM-STYLE-GUIDE.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/SPEC-WRITING-GUIDE.md" "${PROJECT_ROOT}/docs/spec/SPEC-WRITING-GUIDE.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/llms.txt" "${PROJECT_ROOT}/docs/spec/llms.txt"
copy_template "${SCRIPT_DIR}/templates/docs/spec/README.md" "${PROJECT_ROOT}/docs/spec/README.md"

# Copy .llm files
echo ""
echo "Copying LLM coordination files..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/README.md" "${PROJECT_ROOT}/docs/spec/.llm/README.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/PROGRESS.md" "${PROJECT_ROOT}/docs/spec/.llm/PROGRESS.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/MCP-RECOMMENDATIONS.md" "${PROJECT_ROOT}/docs/spec/.llm/MCP-RECOMMENDATIONS.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/INFRASTRUCTURE.md" "${PROJECT_ROOT}/docs/spec/.llm/INFRASTRUCTURE.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/SKILLS.md" "${PROJECT_ROOT}/docs/spec/.llm/SKILLS.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/docker-compose.yml" "${PROJECT_ROOT}/docs/spec/.llm/docker-compose.yml"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/nats.conf" "${PROJECT_ROOT}/docs/spec/.llm/nats.conf"

# Copy plan templates
echo ""
echo "Copying plan templates..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/plan.template.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/plan.template.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/idea.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/idea.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/fullstack.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/fullstack.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/feature.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/feature.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/bugfix.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/bugfix.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/review.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/review.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/self-review.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/self-review.plan.llm"

# Copy task template
echo ""
echo "Copying task template..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/task.template.md" "${PROJECT_ROOT}/docs/spec/.llm/templates/task.template.md"

# Copy parallel agent harness files
echo ""
echo "Copying parallel agent harness files..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/STRATEGY.md" "${PROJECT_ROOT}/docs/spec/.llm/STRATEGY.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/AGENT_GUIDE.md" "${PROJECT_ROOT}/docs/spec/.llm/AGENT_GUIDE.md"

# Copy scripts (no placeholders — use cp + chmod)
echo ""
echo "Copying utility scripts..."
if [ ! -f "${PROJECT_ROOT}/docs/spec/.llm/scripts/move_nav_to_top.py" ]; then
    cp "${SCRIPT_DIR}/templates/docs/spec/.llm/scripts/move_nav_to_top.py" "${PROJECT_ROOT}/docs/spec/.llm/scripts/move_nav_to_top.py"
    chmod +x "${PROJECT_ROOT}/docs/spec/.llm/scripts/move_nav_to_top.py"
    echo "  CREATED: docs/spec/.llm/scripts/move_nav_to_top.py"
else
    echo "  SKIP (exists): docs/spec/.llm/scripts/move_nav_to_top.py"
fi

echo ""
echo "Copying parallel agent scripts..."
for script in run-agent.sh run-parallel.sh run-single-task.sh run-interactive.sh status.sh reset.sh; do
    if [ ! -f "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}" ]; then
        cp "${SCRIPT_DIR}/templates/docs/spec/.llm/scripts/${script}" "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}"
        chmod +x "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}"
        echo "  CREATED: docs/spec/.llm/scripts/${script}"
    else
        echo "  SKIP (exists): docs/spec/.llm/scripts/${script}"
    fi
done

# Copy framework files
echo ""
echo "Copying framework specs..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/README.md" "${PROJECT_ROOT}/docs/spec/framework/README.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/go-generation-guide.md" "${PROJECT_ROOT}/docs/spec/framework/go-generation-guide.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/typescript-ui-guide.md" "${PROJECT_ROOT}/docs/spec/framework/typescript-ui-guide.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/performance-guide.md" "${PROJECT_ROOT}/docs/spec/framework/performance-guide.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/testing-guide.md" "${PROJECT_ROOT}/docs/spec/framework/testing-guide.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/framework/llms.txt" "${PROJECT_ROOT}/docs/spec/framework/llms.txt"

# Copy business spec files
echo ""
echo "Copying business spec files..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/biz/README.md" "${PROJECT_ROOT}/docs/spec/biz/README.md"

# Add .gitkeep files
touch "${PROJECT_ROOT}/docs/spec/.llm/plans/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/completed/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/tasks/backlog/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/tasks/in_progress/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/tasks/completed/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/tasks/blocked/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/tasks/.locks/.gitkeep"
touch "${PROJECT_ROOT}/docs/spec/.llm/logs/.gitkeep"

echo ""
echo "=========================================="
echo "LLM infrastructure setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review .claude/settings.json permissions and adjust as needed"
echo "  2. Review and customize docs/spec/LLM.md for your project"
echo "  3. Review .mcp.json and adjust MCP servers as needed"
echo "  4. Start infrastructure: docker compose -f docs/spec/.llm/docker-compose.yml up -d"
echo "  5. Create spec files following docs/spec/SPEC-WRITING-GUIDE.md"
echo "  6. Delete the llm-init/ folder: rm -rf llm-init/"
echo ""
echo "Included guides:"
echo "  - Go code patterns:     docs/spec/framework/go-generation-guide.md"
echo "  - TypeScript/UI guide:  docs/spec/framework/typescript-ui-guide.md"
echo "  - Performance guide:    docs/spec/framework/performance-guide.md"
echo "  - Business features:    docs/spec/biz/README.md"
echo "  - Spec writing guide:   docs/spec/SPEC-WRITING-GUIDE.md"
echo ""
echo "Custom commands (type in Claude Code):"
echo "  - /decompose <desc>   Break a request into parallel tasks"
echo "  - /new-task <desc>    Create a single task file"
echo "  - /status             Task queue dashboard"
echo "  - /launch [N]         Pre-flight checks + launch agents"
echo "  - /plan <desc>        Select and create a plan template"
echo "  - /review             Run quality gates"
echo "  - /shelve             Checkpoint current work"
echo "  - Full reference:     docs/spec/.llm/SKILLS.md"
echo ""
echo "Parallel agent execution:"
echo "  - Edit STRATEGY.md:     docs/spec/.llm/STRATEGY.md"
echo "  - Edit AGENT_GUIDE.md:  docs/spec/.llm/AGENT_GUIDE.md"
echo "  - Create tasks:         docs/spec/.llm/tasks/backlog/"
echo "  - Task template:        docs/spec/.llm/templates/task.template.md"
echo "  - Launch agents:        bash docs/spec/.llm/scripts/run-parallel.sh 3"
echo "  - Check status:         bash docs/spec/.llm/scripts/status.sh"
echo ""
echo "Claude Code is pre-configured to run autonomously within this project."
echo "See .claude/settings.json for the permission rules."
echo ""
