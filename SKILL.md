---
name: antigravity-polyglot
description: "Zero-overhead compatibility adapter for AI agents (Cursor, Claude, Copilot, Codex). Deterministically scans active environments and delegates translation to a context-isolated polyglot subagent, keeping your main context window 100% clean."
---

# AntigravityPolyglot (Lean Launcher)

This skill acts as a lightweight, high-speed **Zero-Overhead Interface Interceptor** for the Antigravity orchestration system. It deterministically catches foreign rules/tools at session boot and coordinates with the context-isolated `@antigravity-polyglot` subagent to yield compact instruction cards, saving up to 80% of session token bloat.

## Workflow

When this skill is activated, Antigravity MUST execute the following caching and discovery pipeline:

### 0. Memory Cache Check (Highest Priority)
Before running any script or scanning file structures, inspect your active session and recalled memory for the **active skill currently being executed**:
- If a persistent fact regarding this specific skill's signature already exists (e.g., `fact="Skill 'azure-pr' is Gemini-native; no translation needed"` or `fact="Skill 'custom-mcp' is a foreign Claude MCP skill; translate using references/claude-mappings.md"`), **BYPASS the scanning entirely**. 
- Immediately apply the cached mapping/isolation settings.

### 1. Agent Logic Detection (Cache Miss Flow)
If NO scan record exists in your memory for the active skill, analyze the skill's tool definitions, JSON/Zod schemas, or package parameters:
- Look for non-Antigravity signatures (e.g., Claude MCP tool patterns, Cursor rules, or Copilot structures).
- If foreign patterns are detected, immediately proceed to **Step 2** to delegate to the polyglot subagent.
- If the skill is 100% native (conforming perfectly to Antigravity tool schemas), proceed directly to **Step 3** to flag it as clean in memory.

### 2. Isolated Subagent Delegation (Interception)
If a foreign skill is detected, DO NOT load its heavy mapping tables or parameter schemas into your main context. Instead:
- Spin up the specialized **`@antigravity-polyglot`** subagent in the background to translate the skill's tool calls and rules.
- The subagent will parse the schemas, match them strictly to your active working targets, and return a **highly condensed 'Active Constraint Card'** (under 150 tokens) to the main orchestrator.
- Ingest only this tiny Constraint Card into your session, keeping your main context window clean.

### 3. Global Memory Persistence (Cache Write)
After resolving the active skill's compatibility status in Step 1 or Step 2, immediately write the findings to memory to cache them globally for all subsequent runs of **that specific skill**:
- **For Foreign Skills:** `save_memory(scope="global", fact="Skill '[SkillName]' is a foreign [Platform] skill; translate its tool calls using references/[platform]-mappings.md.")`
- **For Native Skills:** `save_memory(scope="global", fact="Skill '[SkillName]' is Gemini-native; no translation needed.")`


---

## Lifecycle Management & Uninstallation

Antigravity is aware of how to manage this skill's lifecycle.

### Uninstallation
If the user requests to uninstall this skill, you should:
1. Explain that the skill can be uninstalled globally or from the workspace.
2. Propose to run the uninstallation command.
3. Execute the uninstallation via `run_command` using the `--uninstall-global` or `--uninstall-workspace` flags.

**Example uninstallation commands:**
- Global: `antigravity-polyglot --uninstall-global`
- Workspace: `antigravity-polyglot --uninstall-workspace`

Note: If the `antigravity-polyglot` binary is not in the path, use the local script: `./scripts/setup.sh --uninstall-workspace`.

---

## Subfolder Workaround
If you need to access resources in a global skill's subfolder (which Antigravity cannot read natively), use the `scripts/local_context_sync.sh` to copy them to the local workspace context (`./.agents/`).
