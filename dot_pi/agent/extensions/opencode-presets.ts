import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext, InputEvent, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";

const FULL_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls"] as const;
const READ_ONLY_TOOLS = ["read", "grep", "find", "ls"] as const;
const NO_WRITE_TOOLS = ["read", "bash", "edit", "grep", "find", "ls"] as const;

type PresetName = "ask" | "build" | "code-reviewer" | "debug" | "explore" | "plan";

type PresetProfile = {
  provider: string;
  model: string;
  toolMode: "full" | "read-only" | "no-write";
  confirmEdit: boolean;
};

const PRESETS: Record<PresetName, PresetProfile> = {
  ask: {
    provider: "google",
    model: "gemini-3.1-flash-lite-preview",
    toolMode: "read-only",
    confirmEdit: false,
  },
  build: {
    provider: "google",
    model: "gemini-3-flash-preview",
    toolMode: "full",
    confirmEdit: false,
  },
  "code-reviewer": {
    provider: "github-copilot",
    model: "gpt-5.4-mini",
    toolMode: "no-write",
    confirmEdit: true,
  },
  debug: {
    provider: "openrouter",
    model: "xiaomi/mimo-v2-flash",
    toolMode: "no-write",
    confirmEdit: true,
  },
  explore: {
    provider: "google",
    model: "gemini-3.1-flash-lite-preview",
    toolMode: "full",
    confirmEdit: false,
  },
  plan: {
    provider: "github-copilot",
    model: "gpt-5.4-mini",
    toolMode: "read-only",
    confirmEdit: false,
  },
};

const PRIMARY_PRESET_CYCLE: PresetName[] = ["plan", "build", "ask"];

const SLASH_COMMAND_TO_PRESET: Record<string, PresetName> = {
  ask: "ask",
  build: "build",
  "code-reviewer": "code-reviewer",
  debug: "debug",
  explore: "explore",
  plan: "plan",
};

const SUBAGENT_TAG_TO_PRESET: Record<string, PresetName> = {
  "@code-reviewer": "code-reviewer",
  "@debug": "debug",
  "@explore": "explore",
};

function parsePresetFromSlash(text: string): PresetName | undefined {
  const trimmed = text.trim();
  if (!trimmed.startsWith("/")) return undefined;
  const command = trimmed.slice(1).split(/\s+/)[0] ?? "";
  return SLASH_COMMAND_TO_PRESET[command];
}

function parseTaggedSubagent(
  text: string,
): { preset?: PresetName; transformedText?: string; tagToken?: string } {
  const tagRegex = /(^|\s)(@(code-reviewer|debug|explore))(?=\s|$)/g;
  let match: RegExpExecArray | null;
  let firstTag: string | undefined;

  while ((match = tagRegex.exec(text)) !== null) {
    if (!firstTag) firstTag = match[2];
  }

  if (!firstTag) return {};

  const preset = SUBAGENT_TAG_TO_PRESET[firstTag];
  const transformedText = text.replace(tagRegex, " ").replace(/\s{2,}/g, " ").trim();
  return { preset, transformedText, tagToken: firstTag };
}

function filterToAvailable(toolNames: readonly string[], allTools: string[]): string[] {
  const available = new Set(allTools);
  return toolNames.filter((t) => available.has(t));
}

function toolsForMode(mode: PresetProfile["toolMode"]): readonly string[] {
  if (mode === "read-only") return READ_ONLY_TOOLS;
  if (mode === "no-write") return NO_WRITE_TOOLS;
  return FULL_TOOLS;
}

async function applyPreset(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  presetName: PresetName,
  notifySource?: string,
): Promise<void> {
  const profile = PRESETS[presetName];

  const allToolNames = pi.getAllTools().map((t) => t.name);
  const targetTools = filterToAvailable(toolsForMode(profile.toolMode), allToolNames);
  if (targetTools.length > 0) {
    pi.setActiveTools(targetTools);
  }

  const model = ctx.modelRegistry.find(profile.provider, profile.model);
  if (!model) {
    if (ctx.hasUI) {
      ctx.ui.notify(
        `Preset ${presetName}: model ${profile.provider}/${profile.model} not found; keeping current model.`,
        "warning",
      );
    }
    return;
  }

  const switched = await pi.setModel(model);
  if (!switched) {
    if (ctx.hasUI) {
      ctx.ui.notify(
        `Preset ${presetName}: auth unavailable for ${profile.provider}/${profile.model}; keeping current model.`,
        "warning",
      );
    }
    return;
  }

  if (ctx.hasUI && notifySource) {
    ctx.ui.notify(`Preset ${presetName} active (${notifySource})`, "info");
  }
}

export default function opencodePresets(pi: ExtensionAPI): void {
  let pendingPreset: PresetName | undefined;
  let activePreset: PresetName | undefined;
  let selectedPrimaryPreset: PresetName | undefined;

  pi.registerShortcut(Key.shift("tab"), {
    description: "Cycle primary presets: plan -> build -> ask",
    handler: async (ctx: ExtensionContext) => {
      const currentIndex = selectedPrimaryPreset
        ? PRIMARY_PRESET_CYCLE.indexOf(selectedPrimaryPreset)
        : -1;
      const nextIndex = (currentIndex + 1) % PRIMARY_PRESET_CYCLE.length;
      selectedPrimaryPreset = PRIMARY_PRESET_CYCLE[nextIndex];
      pendingPreset = selectedPrimaryPreset;
      await applyPreset(pi, ctx, selectedPrimaryPreset, "Shift+Tab");
      ctx.ui.setStatus("opencode-preset", `primary=${selectedPrimaryPreset}`);
    },
  });

  pi.on("input", async (event: InputEvent, ctx: ExtensionContext) => {
    const text = event.text;

    const slashPreset = parsePresetFromSlash(text);
    if (slashPreset) {
      pendingPreset = slashPreset;
      return { action: "continue" };
    }

    const tagged = parseTaggedSubagent(text);
    if (tagged.preset) {
      pendingPreset = tagged.preset;
      if ((tagged.transformedText ?? "").length === 0) {
        if (ctx.hasUI) {
          ctx.ui.notify(`Sub-agent preset ${tagged.preset} selected via ${tagged.tagToken}`, "info");
        }
        return { action: "handled" };
      }
      return {
        action: "transform",
        text: tagged.transformedText ?? text,
        images: event.images,
      };
    }

    if (selectedPrimaryPreset) {
      const trimmed = text.trim();
      // Do not force a preset on non-agent slash commands.
      if (!trimmed.startsWith("/")) {
        pendingPreset = selectedPrimaryPreset;
      }
    }

    return { action: "continue" };
  });

  pi.on("before_agent_start", async (_event, ctx: ExtensionContext) => {
    if (!pendingPreset) return;
    const presetToApply = pendingPreset;
    activePreset = presetToApply;
    pendingPreset = undefined;
    await applyPreset(pi, ctx, presetToApply);
  });

  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!activePreset) return;
    const profile = PRESETS[activePreset];

    if (profile.toolMode === "no-write" && event.toolName === "write") {
      return { block: true, reason: `Preset ${activePreset} blocks write tool` };
    }

    if (profile.toolMode === "read-only" && ["write", "edit", "bash"].includes(event.toolName)) {
      return { block: true, reason: `Preset ${activePreset} is read-only` };
    }

    if (profile.confirmEdit && event.toolName === "edit") {
      if (!ctx.hasUI) {
        return { block: true, reason: `Preset ${activePreset} requires interactive edit confirmation` };
      }
      const ok = await ctx.ui.confirm(`Confirm edit (${activePreset})`, "Allow this edit tool call?");
      if (!ok) {
        return { block: true, reason: `Edit denied by user for preset ${activePreset}` };
      }
    }
  });

  pi.registerCommand("primary", {
    description: "Show or set primary preset cycle mode (plan/build/ask)",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const arg = args.trim();
      if (!arg) {
        const current = selectedPrimaryPreset ?? "none";
        ctx.ui.notify(`Primary preset: ${current}`, "info");
        return;
      }

      if (arg === "off") {
        selectedPrimaryPreset = undefined;
        ctx.ui.setStatus("opencode-preset", undefined);
        ctx.ui.notify("Primary preset disabled", "info");
        return;
      }

      if (!["plan", "build", "ask"].includes(arg)) {
        ctx.ui.notify("Usage: /primary [plan|build|ask|off]", "warning");
        return;
      }

      selectedPrimaryPreset = arg as PresetName;
      pendingPreset = selectedPrimaryPreset;
      await applyPreset(pi, ctx, selectedPrimaryPreset, "/primary");
      ctx.ui.setStatus("opencode-preset", `primary=${selectedPrimaryPreset}`);
    },
  });

  pi.on("agent_end", async () => {
    activePreset = undefined;
  });
}
