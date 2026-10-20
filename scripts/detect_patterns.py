#!/usr/bin/env python3
import os
import json
import sys
import re
import time

def scan_workspace(workspace_path):
    findings = {
        "cursor": {"detected": False, "files": []},
        "claude": {"detected": False, "files": []},
        "copilot": {"detected": False, "files": []},
        "codex": {"detected": False, "files": []},
        "gemini_cli": {"detected": False, "files": []}
    }

    if not os.path.isdir(workspace_path):
        return findings

    # 1. Scan for Cursor files
    cursor_rules = os.path.join(workspace_path, ".cursorrules")
    if os.path.isfile(cursor_rules):
        findings["cursor"]["detected"] = True
        findings["cursor"]["files"].append(cursor_rules)
    
    cursor_dir = os.path.join(workspace_path, ".cursor", "rules")
    if os.path.isdir(cursor_dir):
        for f in os.listdir(cursor_dir):
            if f.endswith(".mdc"):
                findings["cursor"]["detected"] = True
                findings["cursor"]["files"].append(os.path.join(cursor_dir, f))

    # 2. Scan for Copilot files
    copilot_rules = os.path.join(workspace_path, ".github", "copilot-instructions.md")
    if os.path.isfile(copilot_rules):
        findings["copilot"]["detected"] = True
        findings["copilot"]["files"].append(copilot_rules)
        
    copilot_dir = os.path.join(workspace_path, ".github", "instructions")
    if os.path.isdir(copilot_dir):
        for root, _, files in os.walk(copilot_dir):
            for f in files:
                if f.endswith(".instructions.md"):
                    findings["copilot"]["detected"] = True
                    findings["copilot"]["files"].append(os.path.join(root, f))

    # 3. Scan for Claude/MCP files
    mcp_config = os.path.join(workspace_path, ".mcp.json")
    if os.path.isfile(mcp_config):
        findings["claude"]["detected"] = True
        findings["claude"]["files"].append(mcp_config)

    # 4. Scan for Codex files
    for root, _, files in os.walk(workspace_path):
        # Prevent searching deep inside standard build/git targets
        if any(part in root.split(os.sep) for part in [".git", "node_modules", "build", "dist", ".agents", ".antigravitycli"]):
            continue
        for f in files:
            if f.endswith(".codexrules") or f == ".chatgpt-prompt" or f == ".chatgpt-instructions.md":
                findings["codex"]["detected"] = True
                findings["codex"]["files"].append(os.path.join(root, f))

    # 5. Scan for baseline Gemini CLI files
    gemini_md = os.path.join(workspace_path, "gemini.md")
    if os.path.isfile(gemini_md):
        findings["gemini_cli"]["detected"] = True
        findings["gemini_cli"]["files"].append(gemini_md)

    return findings

def get_cache_path():
    # Prefer global installed skill dir if it exists
    global_dir = os.path.expanduser("~/.gemini/skills/antigravity-polyglot")
    if os.path.isdir(global_dir):
        return os.path.join(global_dir, ".cache.json")
    workspace_dir = os.path.abspath("./.agents/skills/antigravity-polyglot")
    if os.path.isdir(workspace_dir):
        return os.path.join(workspace_dir, ".cache.json")
    cache_fallback = os.path.expanduser("~/.gemini/cache")
    os.makedirs(cache_fallback, exist_ok=True)
    return os.path.join(cache_fallback, "polyglot_cache.json")

def load_cache():
    cache_path = get_cache_path()
    try:
        if os.path.exists(cache_path):
            with open(cache_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    data.setdefault("skills", {})
                    data.setdefault("tools", {})
                    return data
    except Exception:
        pass
    return {"skills": {}, "tools": {}}

def save_cache(cache):
    cache_path = get_cache_path()
    try:
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        tmp_path = cache_path + f".tmp.{os.getpid()}"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2)
        os.replace(tmp_path, cache_path)
    except Exception:
        pass

def evaluate_skill_directory(skill_dir, skill_name):
    """
    Evaluates whether a skill directory contains foreign agent patterns
    (e.g., Claude MCP tool patterns, Cursor rules, Copilot instructions, or Codex rules).
    """
    if not skill_dir or not os.path.isdir(skill_dir):
        return "native", "antigravity"

    findings = scan_workspace(skill_dir)
    for platform in ["cursor", "claude", "copilot", "codex"]:
        if findings[platform]["detected"]:
            return "foreign", platform

    skill_md = os.path.join(skill_dir, "SKILL.md")
    if os.path.isfile(skill_md):
        try:
            with open(skill_md, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                if "mcp__" in content or "use_mcp_tool" in content:
                    return "foreign", "claude_mcp"
                if ".cursorrules" in content or ".mdc" in content:
                    return "foreign", "cursor"
                if "copilot-instructions" in content:
                    return "foreign", "copilot"
        except Exception:
            pass

    return "native", "antigravity"

def evaluate_tool_name(tool_name):
    """
    Evaluates a tool name for foreign platform signatures.
    """
    if not tool_name:
        return "native", "antigravity"

    if tool_name.startswith("mcp__"):
        return "foreign", "claude_mcp"

    claude_code_tools = {"Bash", "FileEdit", "FileWrite", "GlobTool", "GrepTool", "NotebookEdit", "KillProcess"}
    if tool_name in claude_code_tools:
        return "foreign", "claude_code"

    cursor_tools = {"runTerminalCommand", "viewDiff", "reapply"}
    if tool_name in cursor_tools:
        return "foreign", "cursor"

    return "native", "antigravity"

def evaluate_tool_call(tool_call):
    """
    Evaluates a tool call during PreToolUse:
    1. Checks if a skill pattern is being invoked or accessed.
    2. Checks the persistent cache:
       - Cache Hit: returns cached status.
       - Cache Miss: evaluates the pattern, registers it into cache for next time.
    3. Always returns a valid Antigravity PreToolHookResult: {"decision": "allow", ...}
    """
    if not isinstance(tool_call, dict):
        return {"decision": "allow"}

    tool_name = tool_call.get("name", "")
    tool_args = tool_call.get("args", {})
    if not isinstance(tool_args, dict):
        tool_args = {}

    cache = load_cache()
    updated = False
    reason = None

    # 1. Detect if tool invocation accesses or references a skill
    skill_name = None
    skill_dir = None
    for arg_key in ["Path", "path", "TargetFile", "file_path", "target_file"]:
        path_val = tool_args.get(arg_key, "")
        if isinstance(path_val, str) and "skills" in path_val:
            m = re.search(r'skills/([^/]+)', path_val)
            if m:
                skill_name = m.group(1)
                idx = path_val.find("skills/" + skill_name)
                skill_dir = path_val[:idx + len("skills/" + skill_name)]
                break

    if skill_name:
        cached_skill = cache["skills"].get(skill_name)
        if cached_skill:
            # Cache HIT
            status = cached_skill.get("status", "native")
            platform = cached_skill.get("platform", "antigravity")
            reason = f"[AntigravityPolyglot] Cache Hit: Skill '{skill_name}' is {status} ({platform})."
        else:
            # Cache MISS -> Evaluate
            if not skill_dir or not os.path.isdir(skill_dir):
                for base in [os.path.expanduser("~/.gemini/skills"), os.path.abspath("./.agents/skills")]:
                    candidate = os.path.join(base, skill_name)
                    if os.path.isdir(candidate):
                        skill_dir = candidate
                        break

            status, platform = evaluate_skill_directory(skill_dir, skill_name)
            cache["skills"][skill_name] = {
                "status": status,
                "platform": platform,
                "timestamp": int(time.time())
            }
            updated = True
            reason = f"[AntigravityPolyglot] Cache Miss: Skill '{skill_name}' evaluated as {status} ({platform}) and cached."

    # 2. Direct tool evaluation (foreign tool interception)
    elif tool_name:
        cached_tool = cache["tools"].get(tool_name)
        if cached_tool:
            # Cache HIT
            status = cached_tool.get("status", "native")
            platform = cached_tool.get("platform", "antigravity")
            if status == "foreign":
                reason = f"[AntigravityPolyglot] Cache Hit: Tool '{tool_name}' is foreign ({platform})."
        else:
            # Cache MISS -> Evaluate
            status, platform = evaluate_tool_name(tool_name)
            cache["tools"][tool_name] = {
                "status": status,
                "platform": platform,
                "timestamp": int(time.time())
            }
            updated = True
            if status == "foreign":
                reason = f"[AntigravityPolyglot] Cache Miss: Tool '{tool_name}' evaluated as foreign ({platform}) and cached."

    if updated:
        save_cache(cache)

    result = {"decision": "allow"}
    if reason:
        result["reason"] = reason
    return result

def handle_hook_execution(stdin_payload, raw_args):
    """
    Handles Antigravity lifecycle hook execution conforming strictly to the
    Antigravity hooks contract (protojson schema).
    """
    try:
        # 1. PreToolUse hook contract: must return {"decision": "allow", ...}
        if stdin_payload and "toolCall" in stdin_payload:
            result = evaluate_tool_call(stdin_payload.get("toolCall"))
            print(json.dumps(result))
            return 0

        # 2. PostToolUse hook contract: must return {}
        if stdin_payload and "stepIdx" in stdin_payload and "error" in stdin_payload:
            print(json.dumps({}))
            return 0

        # 3. SessionStart / PreInvocation hook contract: must return {"injectSteps": [...]}
        workspace_paths = []
        if stdin_payload and isinstance(stdin_payload, dict):
            workspace_paths = stdin_payload.get("workspacePaths", [])

        # Fallback to positional args if workspacePaths was not provided or empty
        if not workspace_paths:
            for arg in raw_args:
                if arg != "--hook" and os.path.isdir(arg):
                    workspace_paths.append(arg)
                    break

        if not workspace_paths:
            workspace_paths = [os.getcwd()]

        foreign_detected = {}
        for wp in workspace_paths:
            findings = scan_workspace(wp)
            for platform in ["cursor", "claude", "copilot", "codex"]:
                if findings[platform]["detected"]:
                    if platform not in foreign_detected:
                        foreign_detected[platform] = []
                    foreign_detected[platform].extend(findings[platform]["files"])

        if foreign_detected:
            summary_parts = []
            for platform, files in foreign_detected.items():
                basenames = sorted(list({os.path.basename(f) for f in files}))
                summary_parts.append(f"{platform.capitalize()} ({', '.join(basenames)})")

            message_text = (
                "[AntigravityPolyglot] Foreign agent configuration detected in workspace: "
                + "; ".join(summary_parts)
                + ". Invoke the 'antigravity-polyglot' subagent to translate these rules and schemas into an Active Constraint Card."
            )

            response = {
                "injectSteps": [
                    {
                        "systemMessage": {
                            "systemMessage": message_text
                        }
                    }
                ]
            }
        else:
            response = {
                "injectSteps": []
            }

        print(json.dumps(response))
        return 0

    except Exception:
        # Fail-safe: ensure Antigravity never crashes or blocks prompt execution
        if stdin_payload and "toolCall" in stdin_payload:
            print(json.dumps({"decision": "allow"}))
        else:
            print(json.dumps({"injectSteps": []}))
        return 0

def main():
    raw_args = sys.argv[1:]

    # Check for help
    if "-h" in raw_args or "--help" in raw_args:
        print("Usage:")
        print("  detect_patterns.py <workspace_path> [output_json_path]   # Standalone scan")
        print("  detect_patterns.py --hook                                # Antigravity hook mode")
        sys.exit(0)

    # Detect if invoked as an Antigravity hook
    is_hook_flag = "--hook" in raw_args

    stdin_payload = None
    if not sys.stdin.isatty():
        try:
            content = sys.stdin.read().strip()
            if content:
                parsed = json.loads(content)
                if isinstance(parsed, dict):
                    stdin_payload = parsed
        except Exception:
            pass

    hook_indicators = ["conversationId", "workspacePaths", "toolCall", "invocationNum", "executionNum"]
    is_antigravity_hook = is_hook_flag or (
        stdin_payload is not None and any(k in stdin_payload for k in hook_indicators)
    )

    if is_antigravity_hook:
        sys.exit(handle_hook_execution(stdin_payload, raw_args))

    # Otherwise, execute standalone CLI scan
    if len(raw_args) < 1:
        print("Usage: detect_patterns.py <workspace_path> [output_json_path]", file=sys.stderr)
        sys.exit(1)

    workspace_path = raw_args[0]
    findings = scan_workspace(workspace_path)
    findings["has_signatures"] = any(data["detected"] for data in findings.values())
    output_content = json.dumps(findings, indent=2)

    if len(raw_args) >= 2:
        output_path = raw_args[1]
        try:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(output_content)
            print(f"Successfully wrote pattern detection report to {output_path}")
        except Exception as e:
            print(f"Error writing report to {output_path}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(output_content)

if __name__ == "__main__":
    main()
