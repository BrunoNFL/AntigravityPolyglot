# ChatGPT Codex & GPTs Mappings

## Configuration Files
Since Codex instructions aren't standardized, the adapter looks for:
- `*.codexrules`: Specific project standards.
- `.chatgpt-prompt` or `.chatgpt-instructions.md`: Custom prompts stored as files.

## Custom Instruction Mapping
Antigravity should treat these as "Project Rules" and apply them to the system context.

## Tool Mapping Table
When encountering a ChatGPT / Codex JSON tool definition (e.g., as defined in a GPT's "Actions"), map to Antigravity tools:

| Codex / GPT Action Name | Antigravity Native Tool | Mapping Strategy |
|-------------------------|-------------------------|------------------|
| `run_terminal`          | `run_command`           | Ensure the script/command is executed in the workspace using `CommandLine`. |
| `edit_file` / `replace` | `replace_file_content`  | Map search/replace logic to `replace_file_content` or `multi_replace_file_content`. |
| `create_file`           | `write_to_file`         | Map the data to `CodeContent` and path to `TargetFile`. |
| `get_context` / `read`  | `view_file`             | Map `path` to `AbsolutePath`. |
| `grep` / `search`       | `grep_search`           | Map search criteria to `grep_search`. |
| `ask_question`          | `ask_question`          | Map the prompt to a structured `ask_question` call. |

## Intelligent Subagent Routing
When a Codex prompt or JSON function call attempts to delegate a task to a "sub-agent" or "secondary model", Antigravity should route it to its native subagent set.

### Routing Logic Table:
| Codex Delegation Intent | Antigravity Native Subagent |
|-------------------------|-----------------------------|
| "Analyze Codebase"      | `research` (Native read-only investigator) |
| "Refactor / Implement"  | `self` (Standard workspace agent context) |
| "Design UI"             | `ui-designer` (Dynamic designer subagent) |
| "General Research"      | `research` (Native read-only investigator) |

### Function Calling Translation
- If a ChatGPT JSON "Functions" or "Tools" schema is found, Antigravity should attempt to translate it into a native tool call or use an MCP integration if the tool is an external service.
- If the tool is local, Antigravity should use `run_command` to emulate the function's logic.

## Priority
`Antigravity > Codex`.

