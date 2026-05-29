#!/usr/bin/env python3
import os
import json
import sys

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

def main():
    if len(sys.argv) < 2:
        print("Usage: detect_patterns.py <workspace_path> [output_json_path]", file=sys.stderr)
        sys.exit(1)

    workspace_path = sys.argv[1]
    findings = scan_workspace(workspace_path)
    
    # Check if any foreign agent signatures are detected
    has_signatures = any(data["detected"] for data in findings.values())
    findings["has_signatures"] = has_signatures

    output_content = json.dumps(findings, indent=2)
    
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
        try:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(output_content)
            print(f"Successfully wrote pattern detection report to {output_path}")
        except Exception as e:
            print(f"Error writing report to {output_path}: {e}", file=sys.stderr)
    else:
        print(output_content)

if __name__ == "__main__":
    main()
