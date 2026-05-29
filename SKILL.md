---
name: antigravity-polyglot
description: "Compatibility layer for AI agents (Cursor, Claude, Copilot, Codex) in the Antigravity orchestration system. Enables Antigravity to natively interpret, translate, and bridge foreign rules, tool calls, and subagent syntax. ALWAYS use this skill to check if currently activated skills or project files follow non-Gemini/non-Antigravity agent patterns."
---

# AntigravityPolyglot

This skill enables the Antigravity orchestration system to natively interpret, parse, and execute instructions and tool calls designed for other AI agents. It acts as a "Universal Adapter" for the AI engineering ecosystem.

## Workflow

When this skill is activated, Antigravity MUST perform the following checks:

### 1. Agent Logic Detection (Proactive Check)
For every activated skill in the current session (see `available_skills`), evaluate if it originates from or targets another agent:
- **Claude Code Pattern:** Look for `mcp__` prefixes in tools, TypeScript `tool()` definitions, or mentions of "Model Context Protocol". **See [references/claude-mappings.md](references/claude-mappings.md) for tool/subagent/command translation.**
- **GitHub Copilot Pattern:** Look for YAML frontmatter with `applyTo` or `.github/skills/` paths. **See [references/copilot-mappings.md](references/copilot-mappings.md) for multi-agent and tool translation.**
- **Cursor Pattern:** Look for `.cursorrules` or `.mdc` references in descriptions. **See [references/cursor-mappings.md](references/cursor-mappings.md) for rule and glob translation.**
- **Codex Pattern:** Look for system-prompt style instructions or JSON function schemas. **See [references/codex-mappings.md](references/codex-mappings.md) for prompt and action translation.**
- **Baseline Gemini CLI Pattern:** Look for standard lowercase `gemini.md` configurations. **See [references/gemini-mappings.md](references/gemini-mappings.md) for baseline tool and subagent routing.**
- **Foreign Tool Schema Pattern (Highest Priority):** Proactively scan the active tool definitions, JSON schemas, or Zod parameters inside all loaded skills during initialization. If any foreign tool schemas are detected, immediately map their parameter properties and register them into Antigravity's active tool list so they are fully visible to the orchestrator *before* any command or task execution begins.





### 2. Global Memory Persistence
If a "foreign agent pattern" is detected in a skill or the workspace, you MUST use the `save_memory` tool to persist this discovery:
- **Project Scope:** If the pattern is specific to the current repo (e.g., `.cursorrules`).
- **Global Scope:** If the pattern is tied to a specific global skill (e.g., a shared Claude MCP skill).
- **Fact Example:** `save_memory(scope="project", fact="This project uses Cursor rules; I must apply the mapping logic from references/cursor-mappings.md.")`

### 3. Rule Ingestion & Merging
Apply discovered rules to the current context using this priority:
`Gemini > Claude > Codex > Cursor`.

### 4. Command & Subagent Translation
- **Commands:** Map Claude CLI commands (e.g., `/compact`) using `scripts/claude_compat.sh`.
- **Subagents:** Map "spawn subagent" calls to Antigravity's native subagents (`self` or `research`) using `references/claude-mappings.md`.

### 5. Foreign Tool Schema Ingestion & Registration (Critical)
To prevent foreign skills from declaring "invisible" tools that the orchestrator fails to read or parse:
- Proactively scan the active tool definitions, JSON schemas, or Zod parameters inside all loaded skills. 
- If any foreign tool schemas are detected (e.g., standard Claude Code or Copilot tool schemas), you MUST dynamically translate their input parameters and register them as active, callable Antigravity tools.
- When an active skill or script attempts to invoke a foreign tool call, intercept it in real-time, translate the argument payloads (e.g., mapping `command` ➔ `CommandLine`, `file_path` ➔ `TargetFile`), and execute it using Antigravity's native high-performance tools (`run_command`, `view_file`, `write_to_file`, `replace_file_content`).

## Lifecycle Management & Uninstallation

Antigravity is aware of how to manage this skill's lifecycle.

### Uninstallation
If the user requests to uninstall this skill, you should:
1.  Explain that the skill can be uninstalled globally or from the workspace.
2.  Propose to run the uninstallation command for them.
3.  Execute the uninstallation via `run_command` using the `--uninstall-global` or `--uninstall-workspace` flags.

**Example uninstallation commands:**
- Global: `antigravity-polyglot --uninstall-global`
- Workspace: `antigravity-polyglot --uninstall-workspace`

Note: If the `antigravity-polyglot` binary is not in the path, use the local script: `./scripts/setup.sh --uninstall-workspace`.

## Reference Guides

- **Cursor Mappings:** See [references/cursor-mappings.md](references/cursor-mappings.md) for glob and imperative logic.
- **Claude Mappings:** See [references/claude-mappings.md](references/claude-mappings.md) for tool/subagent/command routing.
- **Copilot Mappings:** See [references/copilot-mappings.md](references/copilot-mappings.md) for multi-agent logic.
- **Codex Mappings:** See [references/codex-mappings.md](references/codex-mappings.md) for custom instruction adaptation.
- **Gemini Mappings:** See [references/gemini-mappings.md](references/gemini-mappings.md) for baseline Gemini CLI tool and subagent routing.

## Subfolder Workaround
If you need to access resources in a global skill's subfolder (which Gemini CLI cannot read natively), use the `scripts/local_context_sync.sh` to copy them to the local workspace context (`./.gemini/`).

