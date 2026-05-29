# Gemini CLI Tool & Subagent Mappings

## Configuration Files
The AntigravityPolyglot looks for baseline Gemini CLI files:
- `gemini.md`: Global or workspace level orchestration rules.
- `.geminirc`: CLI runtime configuration settings.

## Intelligent Subagent Routing
When a skill or prompt attempts to delegate to standard Gemini CLI subagents, Antigravity maps them to its own specialized high-performance subagents:

| Baseline Gemini CLI Subagent | Antigravity Native Subagent | Description |
|------------------------------|-----------------------------|-------------|
| `generalist`                 | `self`                      | Full contextual clone of the parent orchestrator. |
| `codebase_investigator`      | `research`                  | Read-only specialized file-system explorer and web researcher. |
| `ui-designer`                | `ui-designer`               | Custom defined design system subagent. |

## Tool Mapping Table
When encountering tools designed for baseline Gemini CLI, Antigravity MUST map them to the following native tools:

| Gemini CLI Native Tool | Antigravity Native Tool | Mapping Notes |
|------------------------|-------------------------|---------------|
| `read_file`            | `view_file`             | Map `file_path` to `AbsolutePath`. Supports line ranges. |
| `write_file`           | `write_to_file`         | Map `file_path` to `TargetFile` and `content` to `CodeContent`. |
| `edit_file` / `replace`| `replace_file_content`  | Map old/new strings to `replace_file_content` (contiguous) or `multi_replace_file_content` (non-contiguous). |
| `list_directory`       | `list_dir`              | Map `dir_path` to `DirectoryPath`. |
| `grep_search`          | `grep_search`           | Direct match. |
| `run_shell_command`    | `run_command`           | Map the execution command to `CommandLine` with proper wait duration. |
| `ask_user`             | `ask_question`          | Map the raw prompt to a structured question inside the `questions` array. |

## Priority
`Antigravity > Gemini CLI`. Antigravity's advanced, safe, and asynchronous implementations always take precedence over standard synchronous execution.
