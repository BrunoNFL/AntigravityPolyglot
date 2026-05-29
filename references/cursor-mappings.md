# Cursor Rule Mappings

## Configuration Files
The AntigravityPolyglot looks for the following Cursor files:
- `.cursorrules`: Root-level project instructions.
- `.cursor/rules/*.mdc`: Modular rules applying to specific file patterns.

## Translation Logic
Antigravity should map Cursor's markdown-based rules directly into its "project_context".

### Glob Patterns in `.cursor/rules/*.mdc`
- When parsing a `.mdc` file with YAML frontmatter, Antigravity must use the `globs` property to apply those rules only when working within files matching the pattern.
- If multiple `.mdc` files match a file, their rules should be concatenated.

### Imperative Mapping
- Cursor often uses "Always use..." or "Never use..." phrasing. These should be treated as high-priority "MUST" constraints by Antigravity within the scope of that project.

## Tool Mapping Table
Cursor's internal tool calls (often found in `.cursorrules` instructions) should be mapped to Antigravity native tools:

| Cursor Intent / Tool | Antigravity Native Tool | Mapping Notes |
|----------------------|-------------------------|---------------|
| `Edit File` / `Patch`| `replace_file_content`  | Map to `replace_file_content` (surgical contiguous) or `multi_replace_file_content` (multiple edits). |
| `Create File`        | `write_to_file`         | Map to `write_to_file`. |
| `Run Terminal`       | `run_command`           | Ensure the command is executed with appropriate `WaitMsBeforeAsync` settings. |
| `Search Codebase`    | `grep_search`           | Map the search pattern and context. |
| `Read Context`       | `view_file`             | Map to `view_file` with line range if specified. |
| `List Files`         | `list_dir`              | Map to `list_dir`. |
| `Ask User`           | `ask_question`          | Map the question to a structured `ask_question` call. |

### Priority
`Antigravity > Cursor`. If a Cursor rule contradicts a native Antigravity project rule, Antigravity wins.

