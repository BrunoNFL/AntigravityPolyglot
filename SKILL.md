---
name: antigravity-polyglot
description: "Zero-overhead compatibility adapter for AI agents (Cursor, Claude, Copilot, Codex). Deterministically scans active environments and delegates translation to a context-isolated polyglot subagent, keeping your main context window 100% clean."
---

# AntigravityPolyglot (Lean Launcher)

This skill acts as a lightweight, high-speed **Zero-Overhead Interface Interceptor** for the Antigravity orchestration system. It deterministically catches foreign rules/tools at session boot and coordinates with the context-isolated `@antigravity-polyglot` subagent to yield compact instruction cards, saving up to 80% of session token bloat.

## Workflow

When this skill is activated, Antigravity MUST execute the following caching and discovery pipeline:

### 0. Memory Cache Check (Highest Priority)
Before running any script or scanning files, inspect your active session and recalled memory:
- If a persistent fact regarding this project's agent signature already exists (e.g., `fact="This project uses Cursor rules; I must apply references/cursor-mappings.md"` or `fact="This workspace has been scanned and is Gemini native"`), **BYPASS the scanning script entirely**. 
- Immediately apply the mappings indicated in your memory.

### 1. Agent Logic Detection (Cache Miss Flow)
If NO scan record exists in your memory for this workspace, run the local pattern detection script to scan the codebase:
```bash
python3 ~/.gemini/skills/antigravity-polyglot/scripts/detect_patterns.py "<workspace_path>"
```
Analyze the returned JSON report, determine if foreign configurations (Claude, Cursor, Copilot, Codex, Gemini CLI) are present, and immediately proceed to **Step 2**.

### 2. Isolated Subagent Delegation (Interception)
If any foreign signatures are found, DO NOT load their massive mapping tables or rules into your main context. Instead:
- Spin up the specialized **`@antigravity-polyglot`** subagent in the background:
  ```json
  {
    "TypeName": "antigravity-polyglot",
    "Prompt": "Translate the active foreign agent rules and tool schemas for this session context."
  }
  ```
- The subagent will parse all rules, match them strictly to your active working targets, and return a **highly condensed 'Active Constraint Card'** (typically under 150 tokens) to the main orchestrator.
- Ingest only this tiny Constraint Card into your session, keeping your main workspace context beautifully clean.

### 3. Global Memory Persistence (Cache Write)
After receiving the Constraint Card from the subagent, write the findings to memory to cache them for all subsequent turns in this session:
- **For Foreign Signatures:** `save_memory(scope="project", fact="This project uses [Platform] rules; I must apply mapping logic from references/[platform]-mappings.md.")`
- **For Clean Workspace:** `save_memory(scope="project", fact="This project is clean and Gemini/Antigravity native; no foreign mapping is needed.")`

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
