# Claude Rule & Command Mappings

## Configuration Files
The AntigravityPolyglot looks for:
- `.mcp.json`: Standard MCP server configurations.
- `*.ts` or `*.js` files using the `tool()` function from `@anthropic-ai/claude-code`.

## Claude CLI Command Emulation
The adapter maps Claude CLI commands to Antigravity actions using `scripts/claude_compat.sh`.

### Mapped Commands:
- `/compact`: Antigravity should run a context cleanup or recommend a summary of the current session.
- `/cost`: Antigravity explains cost tracking via the native CLI.
- `/help`: Antigravity displays its native help but acknowledges the use of the Claude command.

## Intelligent Subagent Routing
When an instruction or tool call attempts to "spawn a Claude subagent", Antigravity should route it to its own subagent set.

### Routing Logic Table:
| Claude Subagent Task | Antigravity Native Subagent |
|----------------------|-----------------------------|
| "Analysis", "Investigation", "Root-cause" | `research` (Native read-only investigator) |
| "Refactoring", "Feature Implementation" | `self` (Standard workspace agent context) |
| "UI/UX", "Visuals", "Design" | `ui-designer` (Dynamic designer subagent) |
| "General Questions", "Summarization" | `self` (Standard workspace agent context) |

## Tool Mapping Table
When encountering Claude Code tool definitions or calls, Antigravity MUST map them to the following native tools:

| Claude Tool / SDK Function | Antigravity Native Tool | Mapping Notes |
|----------------------------|-------------------------|---------------|
| `AskUserQuestion`          | `ask_question`          | Map the prompt/question to `ask_question` with structured prompt parameters. |
| `Bash` / `RunCommand`      | `run_command`           | Ensure command is executed with appropriate `WaitMsBeforeAsync` settings. |
| `ReadFile` / `Read`        | `view_file`             | Map `path` to `AbsolutePath`. Supports line ranges. |
| `WriteFile` / `Write`      | `write_to_file`         | Map `path` to `TargetFile` and `content` to `CodeContent`. Supports artifact tags. |
| `SearchFiles` / `Grep`     | `grep_search`           | Map the search pattern and path accordingly. |
| `ListFiles` / `ls`         | `list_dir`              | Map the directory path to `DirectoryPath`. |
| `FileEdit` / `Replace`     | `replace_file_content`  | Map `old_string` and `new_string` for surgical single-chunk edits, or `multi_replace_file_content`. |

### Special Case: `AskUserQuestion`
Claude's `AskUserQuestion` typically takes a simple string. Antigravity's `ask_question` is highly structured and UI-driven.
- **Mapping Strategy:** Create a single question in the `questions` array.
- **Type:** Use text input, multi-choice, or binary confirmation.

## Tool Schema Mapping
- Claude Code's `tool()` uses Zod for input schemas.
- Antigravity should attempt to infer the tool's JSON Schema from the Zod structure when mapping to its own native tool definitions.

## Priority
`Antigravity > Claude`.

