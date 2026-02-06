Run quality gates and review current work.

## Instructions

1. Read `docs/spec/.llm/AGENT_GUIDE.md` for project-specific quality gate commands.
2. Read `docs/spec/.llm/PROGRESS.md` for known patterns and conventions.
3. **Run quality gates** from AGENT_GUIDE.md (build, test, lint, type-check as applicable).
4. **Check conventions**:
   - Code follows framework guides (`docs/spec/framework/`)
   - New files have appropriate structure and documentation
   - No hardcoded credentials, secrets, or environment-specific values
   - Error handling follows project patterns
5. **Check cross-references** (if docs were modified):
   - Navigation indexes in LLM.md and llms.txt are up to date
   - New files are referenced in appropriate README.md files
   - Related Documentation sections have backlinks
6. **Report results** in a structured format:
   - Quality gates: pass/fail with details
   - Convention issues: list with file and line
   - Cross-reference issues: missing or broken links
   - Recommendations: what to fix and how

$ARGUMENTS
