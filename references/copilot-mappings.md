# GitHub Copilot Rule Mappings

## Configuration Files
The AntigravityPolyglot looks for:
- `.github/copilot-instructions.md`: Global repository-wide standards.
- `.github/instructions/*.instructions.md`: Path-specific rules with YAML frontmatter.
- `.github/skills/*/SKILL.md`: Modular workflows and capabilities.

## Multi-Agent Logic
If `AGENTS.md` is found in the workspace, Antigravity should treat its instructions as primary (after Antigravity native rules) for all agents.

## Translation Logic
Antigravity should map Copilot's `applyTo` glob patterns to its own conditional instruction set.

## Tool Mapping Table
Copilot's skill tool calls (e.g., from `SKILL.md` or `@github-copilot` interactions) should be mapped to Antigravity native tools:

| Copilot Tool Name | Antigravity Native Tool | Mapping Notes |
|-------------------|-------------------------|---------------|
| `run_shell` / `sh`| `run_command`           | Ensure `command` argument is correctly mapped to `CommandLine`. |
| `read_file`       | `view_file`             | Direct mapping to `AbsolutePath`. |
| `write_file`      | `write_to_file`         | Direct mapping to `TargetFile` and `CodeContent`. |
| `search_codebase` | `grep_search`           | Map the search pattern and context. |
| `ask_user`        | `ask_question`          | Map the question to a structured `ask_question` call. |
| `list_files`      | `list_dir`              | Map to `list_dir`. |
| `edit_file`       | `replace_file_content`  | Map to `replace_file_content` (surgical contiguous) or `multi_replace_file_content` (non-contiguous). |

## Intelligent Subagent Routing
When a Copilot skill or instruction attempts to delegate to another agent (e.g., `@workspace`, `@terminal`, or a sub-skill), Antigravity should route it to its own subagent set.

| Copilot Agent / Intent | Antigravity Native Subagent |
|-------------------------|-----------------------------|
| `@workspace` / Analysis | `research` (Native read-only investigator) |
| `@terminal` / Execution | `self` (Standard workspace agent context) |
| Feature Implementation  | `self` (Standard workspace agent context) |
| UI/UX / Design          | `ui-designer` (Dynamic designer subagent) |

### Skills Translation
- Copilot's `tools: []` property should be mapped to the most equivalent Antigravity tools (e.g., `run_command`, `view_file`, `write_to_file`).
- YAML frontmatter metadata from Copilot `SKILL.md` files should be ingested into Antigravity's skill-discovery mechanism.

## Priority
`Antigravity > Copilot`.

