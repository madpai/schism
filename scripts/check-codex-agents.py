#!/usr/bin/env python3
"""Validate SCHISM's native Codex setup. This is a checker, not a dispatcher."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import tempfile
import threading
import time
import tomllib

ROOT = Path(__file__).resolve().parents[1]
ROLES = {
    "schism_architecture": ("gpt-6-astra", "high"),
    "schism_gameplay": ("gpt-6.1-sol", "medium"),
    "schism_economy_persistence": ("gpt-6-astra", "high"),
    "schism_exploration": ("gpt-6-luna", "medium"),
    "schism_world_content": ("gpt-6-sol", "medium"),
    "schism_android": ("gpt-6.1-sol", "high"),
    "schism_qa": ("gpt-6-sol", "high"),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_setup():
    config = tomllib.loads((ROOT / ".codex/config.toml").read_text())
    require(config.get("model") == "gpt-6.1-sol", "Unexpected lead model")
    require(config.get("model_reasoning_effort") == "high", "Unexpected lead effort")
    require(config.get("agents", {}).get("enabled") is True, "Agents are disabled")
    require(config["agents"].get("max_concurrent_threads_per_session") == 3,
            "Expected three child slots")
    agents = {}
    for path in sorted((ROOT / ".codex/agents").glob("*.toml")):
        agent = tomllib.loads(path.read_text())
        for key in ("name", "description", "developer_instructions", "model", "model_reasoning_effort"):
            require(isinstance(agent.get(key), str) and agent[key].strip(), f"{path.name}: missing {key}")
        name = agent["name"]
        require(name not in agents, f"Duplicate agent {name}")
        require(path.stem == name, f"{path.name}: filename/name mismatch")
        require(name in ROLES, f"Unexpected role {name}")
        require((agent["model"], agent["model_reasoning_effort"]) == ROLES[name],
                f"{name}: model/effort differs from documented routing")
        require("AGENTS.md" in agent["developer_instructions"], f"{name}: missing project instruction reference")
        agents[name] = agent
    require(set(agents) == set(ROLES), "Missing specialist files")
    require(agents["schism_exploration"].get("sandbox_mode") == "read-only", "Explorer must default read-only")
    instructions = (ROOT / "AGENTS.md").read_text()
    require("explicitly requests automatic native subagent delegation" in instructions,
            "Future sessions lack explicit delegation authorization")
    require(all(name in instructions for name in agents), "AGENTS.md routing table is incomplete")
    return config, agents


def validate_catalog(config, agents, catalog):
    models = catalog.get("data", catalog.get("models", [])) if isinstance(catalog, dict) else catalog
    by_name = {m.get("model", m.get("slug")): m for m in models}
    assignments = {"lead": config, **agents}
    assignments["default_subagent"] = {
        "model": config["agents"]["default_subagent_model"],
        "model_reasoning_effort": config["agents"]["default_subagent_reasoning_effort"],
    }
    for role, agent in assignments.items():
        model, effort = agent["model"], agent["model_reasoning_effort"]
        require(model in by_name, f"{role}: {model} absent from account catalog")
        entry = by_name[model]
        require(not entry.get("hidden", False) and entry.get("visibility", "list") != "hide",
                f"{role}: {model} is hidden from the picker")
        levels = entry.get("supportedReasoningEfforts", entry.get("supported_reasoning_levels", []))
        supported = {e.get("reasoningEffort", e.get("effort")) for e in levels}
        require(effort in supported, f"{role}: {model} does not advertise {effort} reasoning")
    return {m: sorted({e.get("reasoningEffort", e.get("effort")) for e in by_name[m].get(
        "supportedReasoningEfforts", by_name[m].get("supported_reasoning_levels", []))})
        for m in sorted({a["model"] for a in assignments.values()})}


class NativeInspection:
    """Short-lived stdio client for config/catalog inspection; never starts a turn."""

    def __enter__(self):
        self.stderr = tempfile.TemporaryFile(mode="w+t")
        self.process = subprocess.Popen(["codex", "--strict-config", "app-server", "--stdio"],
                                        cwd=ROOT, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=self.stderr, text=True, bufsize=1)
        self.messages = queue.Queue()
        self.request_id = 0

        def read():
            try:
                for line in self.process.stdout:
                    self.messages.put(json.loads(line))
            except (ValueError, OSError) as exc:
                self.messages.put(RuntimeError(f"Invalid native app-server output: {exc}"))
            finally:
                self.messages.put(None)

        self.reader = threading.Thread(target=read, daemon=True)
        self.reader.start()
        return self

    def __exit__(self, *_):
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self.process.stdin.close()
        self.reader.join(timeout=2)
        self.process.stdout.close()
        self.stderr.close()

    def rpc(self, method, params):
        self.request_id += 1
        request_id = self.request_id
        self.process.stdin.write(json.dumps({"id": request_id, "method": method, "params": params}) + "\n")
        self.process.stdin.flush()
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            try:
                message = self.messages.get(timeout=max(0.01, deadline - time.monotonic()))
            except queue.Empty as exc:
                raise TimeoutError(f"Native {method} did not respond within 60 seconds") from exc
            if isinstance(message, Exception):
                raise message
            if message is None:
                self.stderr.seek(0)
                error = self.stderr.read()
                hint = " Read-only filesystem: run with permission to initialize Codex's local cache." if "Read-only file system" in error else " Check Codex doctor and project trust."
                raise RuntimeError("Native app-server exited." + hint)
            if message.get("id") == request_id:
                require("error" not in message, f"Native {method} failed: {message.get('error')}")
                return message["result"]
        raise TimeoutError(method)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, help="Account models_cache.json or native model/list JSON")
    parser.add_argument("--native", action="store_true", help="Check native config layering, account catalog and a fresh idle session")
    parser.add_argument("--output", type=Path, help="Write a sanitized validation receipt")
    args = parser.parse_args()
    config, agents = read_setup()
    report = {"checked_at": datetime.now(timezone.utc).isoformat(),
              "specialists": {n: {"model": a["model"], "effort": a["model_reasoning_effort"]}
                              for n, a in agents.items()}, "native_checked": False}
    if args.native:
        with NativeInspection() as native:
            native.rpc("initialize", {"clientInfo": {"name": "schism_agent_check", "version": "1"},
                                      "capabilities": {"experimentalApi": True}})
            native.process.stdin.write('{"method":"initialized"}\n')
            native.process.stdin.flush()
            effective = native.rpc("config/read", {"cwd": str(ROOT), "includeLayers": True})
            for key in ("model", "model_reasoning_effort"):
                require(effective["config"].get(key) == config[key],
                        f"Native {key} differs from project config; check trust and overrides")
            loaded_agents = effective["config"].get("agents", {})
            for key, value in config["agents"].items():
                require(loaded_agents.get(key) == value,
                        f"Native agents.{key} differs from project config; check trust and overrides")
            report["native_agent_defaults"] = {key: loaded_agents[key] for key in config["agents"]}
            models, cursor = [], None
            while True:
                page = native.rpc("model/list", {"includeHidden": False, "limit": 100, "cursor": cursor})
                models.extend(page["data"])
                cursor = page.get("nextCursor")
                if not cursor:
                    break
            report["supported_models"] = validate_catalog(config, agents, {"data": models})
            # No model override: proves defaults and instructions load in a new session.
            session = native.rpc("thread/start", {"cwd": str(ROOT), "ephemeral": True,
                                                  "approvalPolicy": "never", "sandbox": "read-only",
                                                  "allowProviderModelFallback": False,
                                                  "config": {"mcp_servers": {
                                                      name: {"enabled": False} for name in
                                                      effective["config"].get("mcp_servers", {})}}})
            require(session["model"] == config["model"], "Fresh session chose a different lead model")
            require(session["reasoningEffort"] == config["model_reasoning_effort"], "Fresh session effort differs")
            require(str(ROOT / "AGENTS.md") in session["instructionSources"], "Fresh session omitted AGENTS.md")
            report.update(native_checked=True, codex_version=subprocess.check_output(
                ["codex", "--version"], text=True).strip(), fresh_session={
                    k: session[k] for k in ("model", "reasoningEffort", "instructionSources")})
    else:
        catalog_path = args.catalog or Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex"))) / "models_cache.json"
        catalog = json.loads(catalog_path.read_text())
        report["supported_models"] = validate_catalog(config, agents, catalog)
        report["catalog_fetched_at"] = catalog.get("fetched_at") if isinstance(catalog, dict) else None
        report["catalog_note"] = "Cached account catalog; use --native for current native loading/catalog validation."
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, RuntimeError, TimeoutError, queue.Empty, subprocess.SubprocessError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
