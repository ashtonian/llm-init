#!/usr/bin/env bash
set -euo pipefail

# LLM Init Setup Script
# Usage: bash llm-init/setup.sh <project-name>
#
# Copies the llm-init template into your project, replacing {{PROJECT_NAME}}
# with the provided project name.

GO_SCAFFOLD=0

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --go)
            GO_SCAFFOLD=1
            shift
            ;;
        --help|-h)
            echo "Usage: bash llm-init/setup.sh [--go] <project-name> [go-module-path]"
            echo ""
            echo "Flags:"
            echo "  --go             Scaffold Go project (Makefile, Dockerfile, CI, GoReleaser, linter)"
            echo ""
            echo "Arguments:"
            echo "  project-name     Used for database names, container names, etc."
            echo "  go-module-path   Go module import path (default: github.com/yourorg/project-name)"
            echo ""
            echo "Examples:"
            echo "  bash llm-init/setup.sh my-app github.com/myorg/my-app"
            echo "  bash llm-init/setup.sh --go my-app github.com/myorg/my-app"
            exit 0
            ;;
        -*)
            echo "ERROR: Unknown flag: $1"
            echo "Run with --help for usage."
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -lt 1 ]; then
    echo "Usage: bash llm-init/setup.sh [--go] <project-name> [go-module-path]"
    echo "Example: bash llm-init/setup.sh --go my-awesome-app github.com/myorg/my-awesome-app"
    echo ""
    echo "Flags:"
    echo "  --go             Scaffold Go project (Makefile, Dockerfile, CI, GoReleaser, linter)"
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
mkdir -p "${PROJECT_ROOT}/.claude/skills"
mkdir -p "${PROJECT_ROOT}/.claude/agents"
mkdir -p "${PROJECT_ROOT}/.claude/rules"
mkdir -p "${PROJECT_ROOT}/.codex"
mkdir -p "${PROJECT_ROOT}/.agents/skills"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/plans"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/completed"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/templates"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/scripts"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/archive"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/postgres"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/redis"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/data/nats"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/backlog"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/in_progress"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/completed"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/blocked"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/tasks/.locks"
mkdir -p "${PROJECT_ROOT}/docs/spec/.llm/logs"
mkdir -p "${PROJECT_ROOT}/docs/spec/biz"

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
    if ! sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" \
        -e "s/{{PROJECT_MODULE}}/${escaped_module}/g" \
        "${src}" > "${dest}"; then
        echo "  ERROR: Failed to process template: ${src}"
        rm -f "${dest}"
        return 1
    fi
    # Verify no unreplaced placeholders remain
    if grep -q '{{PROJECT_NAME}}' "${dest}" 2>/dev/null; then
        echo "  WARNING: Unreplaced {{PROJECT_NAME}} in ${dest}"
    fi
    echo "  CREATED: ${dest}"
}

# Copy root config files
echo ""
echo "Copying root configuration files..."
copy_template "${SCRIPT_DIR}/templates/.mcp.json" "${PROJECT_ROOT}/.mcp.json"
copy_template "${SCRIPT_DIR}/templates/CLAUDE.md" "${PROJECT_ROOT}/CLAUDE.md"
copy_template "${SCRIPT_DIR}/templates/AGENTS.md" "${PROJECT_ROOT}/AGENTS.md"

# Copy Codex CLI configuration
echo ""
echo "Copying Codex CLI configuration..."
copy_template "${SCRIPT_DIR}/templates/.codex/config.toml" "${PROJECT_ROOT}/.codex/config.toml"

# Copy Claude Code settings
echo ""
echo "Copying Claude Code settings..."
if [ ! -f "${PROJECT_ROOT}/.claude/settings.json" ]; then
    cp "${SCRIPT_DIR}/templates/.claude/settings.json" "${PROJECT_ROOT}/.claude/settings.json"
    echo "  CREATED: .claude/settings.json"
else
    echo "  SKIP (exists): .claude/settings.json"
fi

# Copy skills
echo ""
echo "Copying skills..."
for skill in decompose new-task status launch plan review shelve requirements architecture-review adr security-review prd release api-design data-model performance-audit incident-response refactor migrate dependency-audit; do
    mkdir -p "${PROJECT_ROOT}/.claude/skills/${skill}"
    if [ ! -f "${PROJECT_ROOT}/.claude/skills/${skill}/SKILL.md" ]; then
        cp "${SCRIPT_DIR}/templates/.claude/skills/${skill}/SKILL.md" "${PROJECT_ROOT}/.claude/skills/${skill}/SKILL.md"
        echo "  CREATED: .claude/skills/${skill}/SKILL.md"
    else
        echo "  SKIP (exists): .claude/skills/${skill}/SKILL.md"
    fi
done

# Mirror skills to Codex CLI directory (.agents/skills/)
echo ""
echo "Mirroring skills for Codex CLI compatibility..."
for skill in decompose new-task status launch plan review shelve requirements architecture-review adr security-review prd release api-design data-model performance-audit incident-response refactor migrate dependency-audit; do
    mkdir -p "${PROJECT_ROOT}/.agents/skills/${skill}"
    if [ ! -f "${PROJECT_ROOT}/.agents/skills/${skill}/SKILL.md" ]; then
        cp "${SCRIPT_DIR}/templates/.claude/skills/${skill}/SKILL.md" "${PROJECT_ROOT}/.agents/skills/${skill}/SKILL.md"
        echo "  CREATED: .agents/skills/${skill}/SKILL.md"
    else
        echo "  SKIP (exists): .agents/skills/${skill}/SKILL.md"
    fi
done

# Copy agents
echo ""
echo "Copying agents..."
for agent in team-lead.md implementer.md reviewer.md security.md debugger.md tester.md frontend.md api-designer.md data-modeler.md architect.md benchmarker.md ux-researcher.md release-engineer.md devops.md requirements-analyst.md refactorer.md migration-specialist.md spec-writer.md; do
    if [ ! -f "${PROJECT_ROOT}/.claude/agents/${agent}" ]; then
        cp "${SCRIPT_DIR}/templates/.claude/agents/${agent}" "${PROJECT_ROOT}/.claude/agents/${agent}"
        echo "  CREATED: .claude/agents/${agent}"
    else
        echo "  SKIP (exists): .claude/agents/${agent}"
    fi
done

# Copy rules (these have placeholders)
echo ""
echo "Copying rules..."
copy_template "${SCRIPT_DIR}/templates/.claude/rules/agent-guide.md" "${PROJECT_ROOT}/.claude/rules/agent-guide.md"
for rule in spec-first.md go-patterns.md typescript-patterns.md performance.md testing.md security.md observability.md multi-tenancy.md infrastructure.md api-design.md auth-patterns.md data-patterns.md frontend-architecture.md ux-standards.md error-handling.md code-quality.md git-workflow.md; do
    if [ ! -f "${PROJECT_ROOT}/.claude/rules/${rule}" ]; then
        cp "${SCRIPT_DIR}/templates/.claude/rules/${rule}" "${PROJECT_ROOT}/.claude/rules/${rule}"
        echo "  CREATED: .claude/rules/${rule}"
    else
        echo "  SKIP (exists): .claude/rules/${rule}"
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

# Copy LLM coordination files
echo ""
echo "Copying LLM coordination files..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/PROGRESS.md" "${PROJECT_ROOT}/docs/spec/.llm/PROGRESS.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/INFRASTRUCTURE.md" "${PROJECT_ROOT}/docs/spec/.llm/INFRASTRUCTURE.md"
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
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/codegen.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/codegen.plan.llm"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/requirements.plan.llm" "${PROJECT_ROOT}/docs/spec/.llm/templates/requirements.plan.llm"

# Copy task template and example
echo ""
echo "Copying task template..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/task.template.md" "${PROJECT_ROOT}/docs/spec/.llm/templates/task.template.md"
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/templates/example-task.md" "${PROJECT_ROOT}/docs/spec/.llm/templates/example-task.md"

# Copy parallel agent harness files
echo ""
echo "Copying strategy and agent guide..."
copy_template "${SCRIPT_DIR}/templates/docs/spec/.llm/STRATEGY.md" "${PROJECT_ROOT}/docs/spec/.llm/STRATEGY.md"

# Copy scripts (no placeholders -- use cp + chmod)
echo ""
echo "Copying utility scripts..."
for script in run-team.sh status.sh reset.sh archive.sh; do
    if [ ! -f "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}" ]; then
        cp "${SCRIPT_DIR}/templates/docs/spec/.llm/scripts/${script}" "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}"
        chmod +x "${PROJECT_ROOT}/docs/spec/.llm/scripts/${script}"
        echo "  CREATED: docs/spec/.llm/scripts/${script}"
    else
        echo "  SKIP (exists): docs/spec/.llm/scripts/${script}"
    fi
done

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
touch "${PROJECT_ROOT}/docs/spec/.llm/archive/.gitkeep"

# Go project scaffolding (optional)
if [ "$GO_SCAFFOLD" -eq 1 ]; then
    echo ""
    echo "Scaffolding Go project..."
    mkdir -p "${PROJECT_ROOT}/cmd/${PROJECT_NAME}"
    mkdir -p "${PROJECT_ROOT}/.github/workflows"

    mkdir -p "${PROJECT_ROOT}/internal/greeter"

    copy_template "${SCRIPT_DIR}/templates/go/cmd/PROJECT_NAME/main.go" "${PROJECT_ROOT}/cmd/${PROJECT_NAME}/main.go"
    copy_template "${SCRIPT_DIR}/templates/go/cmd/PROJECT_NAME/main_test.go" "${PROJECT_ROOT}/cmd/${PROJECT_NAME}/main_test.go"
    copy_template "${SCRIPT_DIR}/templates/go/internal/greeter/doc.go" "${PROJECT_ROOT}/internal/greeter/doc.go"
    copy_template "${SCRIPT_DIR}/templates/go/internal/greeter/model.go" "${PROJECT_ROOT}/internal/greeter/model.go"
    copy_template "${SCRIPT_DIR}/templates/go/internal/greeter/repository.go" "${PROJECT_ROOT}/internal/greeter/repository.go"
    copy_template "${SCRIPT_DIR}/templates/go/internal/greeter/service.go" "${PROJECT_ROOT}/internal/greeter/service.go"
    copy_template "${SCRIPT_DIR}/templates/go/internal/greeter/service_test.go" "${PROJECT_ROOT}/internal/greeter/service_test.go"
    copy_template "${SCRIPT_DIR}/templates/go/Makefile" "${PROJECT_ROOT}/Makefile"
    copy_template "${SCRIPT_DIR}/templates/go/Dockerfile" "${PROJECT_ROOT}/Dockerfile"
    copy_template "${SCRIPT_DIR}/templates/go/.goreleaser.yml" "${PROJECT_ROOT}/.goreleaser.yml"
    copy_template "${SCRIPT_DIR}/templates/go/.golangci.yml" "${PROJECT_ROOT}/.golangci.yml"
    copy_template "${SCRIPT_DIR}/templates/go/.github/workflows/ci.yml" "${PROJECT_ROOT}/.github/workflows/ci.yml"
    copy_template "${SCRIPT_DIR}/templates/go/.github/workflows/release.yml" "${PROJECT_ROOT}/.github/workflows/release.yml"
    copy_template "${SCRIPT_DIR}/templates/go/README.md" "${PROJECT_ROOT}/README.md"

    # renovate.json has no placeholders -- use cp
    if [ ! -f "${PROJECT_ROOT}/renovate.json" ]; then
        cp "${SCRIPT_DIR}/templates/go/renovate.json" "${PROJECT_ROOT}/renovate.json"
        echo "  CREATED: renovate.json"
    else
        echo "  SKIP (exists): renovate.json"
    fi

    # Initialize go.mod and go.sum
    if [ ! -f "${PROJECT_ROOT}/go.mod" ]; then
        echo ""
        echo "Initializing Go module..."
        if (cd "${PROJECT_ROOT}" && go mod init "${PROJECT_MODULE}" 2>/dev/null); then
            echo "  CREATED: go.mod (${PROJECT_MODULE})"
            # Create go.sum so Dockerfile COPY doesn't fail
            (cd "${PROJECT_ROOT}" && go mod tidy 2>/dev/null) || true
            if [ -f "${PROJECT_ROOT}/go.sum" ]; then
                echo "  CREATED: go.sum"
            fi
        else
            echo "  WARNING: 'go mod init' failed (Go not installed?). Run manually:"
            echo "    cd ${PROJECT_ROOT} && go mod init ${PROJECT_MODULE} && go mod tidy"
        fi
    else
        echo "  SKIP (exists): go.mod"
    fi
fi

echo ""
echo "=========================================="
echo "LLM infrastructure setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review .claude/settings.json permissions and adjust as needed"
echo "  2. Review and customize .claude/rules/agent-guide.md for your project"
echo "  3. Review .mcp.json and adjust MCP servers as needed"
echo "  4. Start infrastructure: docker compose -f docs/spec/.llm/docker-compose.yml up -d"
echo "  5. Delete the llm-init/ folder: rm -rf llm-init/"
echo ""
echo "Structure created:"
echo "  .claude/skills/     20 skills (slash commands)"
echo "  .claude/agents/     18 agents (team-lead + 17 specialists)"
echo "  .claude/rules/      18 rules (agent-guide + 17 pattern guides)"
echo ""
echo "Skills (type in Claude Code):"
echo "  Task management:"
echo "  - /prd <desc>              Interactive PRD -> sized task files"
echo "  - /decompose <desc>        Break a request into parallel tasks"
echo "  - /new-task <desc>         Create a single task file"
echo "  - /status                  Task queue dashboard"
echo "  - /launch                  Pre-flight checks + launch team lead agent"
echo "  - /plan <desc>             Select and create a plan template"
echo "  - /review                  Run quality gates"
echo "  - /shelve                  Checkpoint current work"
echo ""
echo "  Software lifecycle:"
echo "  - /requirements            Iterative requirement gathering -> spec"
echo "  - /architecture-review     Assess decisions and tradeoffs"
echo "  - /adr                     Create Architecture Decision Record"
echo "  - /security-review         Security assessment"
echo "  - /release                 Release checklist and changelog"
echo "  - /api-design              Design API contracts with OpenAPI specs"
echo "  - /data-model              Design database schemas and migrations"
echo "  - /performance-audit       Profile and optimize performance"
echo "  - /incident-response       Structured incident investigation"
echo "  - /refactor                Analyze codebase and plan refactoring"
echo "  - /migrate                 Plan and execute database migrations"
echo "  - /dependency-audit        Audit dependencies for vulnerabilities"
echo ""
echo "Team execution:"
echo "  - Edit STRATEGY.md:        docs/spec/.llm/STRATEGY.md"
echo "  - Edit agent guide:        .claude/rules/agent-guide.md"
echo "  - Create tasks:            docs/spec/.llm/tasks/backlog/"
echo "  - Launch team:             bash docs/spec/.llm/scripts/run-team.sh"
echo "  - Check status:            bash docs/spec/.llm/scripts/status.sh"
echo ""
echo "Codex CLI compatibility:"
echo "  - AGENTS.md:              Codex CLI entry point"
echo "  - .codex/config.toml:     Codex CLI configuration"
echo "  - .agents/skills/:        Mirrored skills (identical SKILL.md format)"
echo "  Note: aws-documentation MCP server requires uvx (pip install uv)"
echo ""
echo "Claude Code is pre-configured to run autonomously within this project."
echo "See .claude/settings.json for the permission rules."
echo ""
