/**
 * Skill Environments Extension
 *
 * Adds a level of abstraction above project-level skills: named environments
 * of skills that span multiple projects (e.g. "academic" for all academic
 * writing work, "pocock-books" for Matt Pocock's rule books).
 *
 * Environments live in ~/.pi/skill-environments/<name>/, each containing
 * normal skill directories (SKILL.md). They are OUTSIDE pi's auto-discovery
 * paths, so an environment is inert until activated for a given project.
 *
 * Activation (all sources merge, deduped):
 *   1. PI_SKILL_ENVIRONMENTS env var   — comma-separated names (ad hoc, per
 *                                      invocation)
 *   2. .pi-environments file           — walked up from cwd to filesystem
 *                                      root (stop at git root), one name per
 *                                      line, '#' comments allowed
 *                                      (persistent, per-project)
 *
 * Precedence is safe: user/project skills load before environment skills and
 * pi keeps the first skill found on name collisions, so environments never
 * override your own skills.
 *
 * Command:
 *   /skill-environment              — dropdown picker; each option shows a
 *                                     one-sentence description (from
 *                                     <env>/description.txt, or derived from
 *                                     the skills it contains); the chosen
 *                                     environment is written to
 *                                     .pi-environments and the active
 *                                     environment shows in the footer
 *   /skill-environment <name>       — activate <name> directly
 *
 * The footer always shows the currently active environment(s).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

const ENVIRONMENTS_DIR = join(homedir(), ".pi", "skill-environments");
const ENVIRONMENTS_FILE = ".pi-environments";
const STATUS_KEY = "skill-env";

function listAvailableEnvironments(): string[] {
	if (!existsSync(ENVIRONMENTS_DIR)) return [];
	return readdirSync(ENVIRONMENTS_DIR, { withFileTypes: true })
		.filter((e) => e.isDirectory() && !e.name.startsWith("."))
		.map((e) => e.name)
		.sort();
}

/** One-sentence blurb from <env>/description.txt (first non-comment line). */
function readEnvDescription(dir: string): string | null {
	for (const file of ["description.txt", "description.md", "DESCRIPTION"]) {
		const path = join(dir, file);
		if (!existsSync(path)) continue;
		const line = readFileSync(path, "utf8")
			.split("\n")
			.map((l) => l.trim())
			.find((l) => l.length > 0 && !l.startsWith("#"));
		if (line) return line.length > 120 ? `${line.slice(0, 117)}...` : line;
	}
	return null;
}

/** Fallback summary derived from the skills inside an environment. */
function deriveEnvSummary(dir: string): string {
	const skills = existsSync(dir)
		? readdirSync(dir, { withFileTypes: true })
				.filter((e) => e.isDirectory() && existsSync(join(dir, e.name, "SKILL.md")))
				.map((e) => e.name)
		: [];
	if (skills.length === 0) return "(no skills)";
	const shown = skills.slice(0, 3).join(", ");
	return `${skills.length} skills: ${shown}${skills.length > 3 ? `, +${skills.length - 3} more` : ""}`;
}

function describeEnvironment(name: string): string {
	return readEnvDescription(join(ENVIRONMENTS_DIR, name)) ?? deriveEnvSummary(join(ENVIRONMENTS_DIR, name));
}

function parseEnvironmentsFile(path: string): string[] {
	try {
		return readFileSync(path, "utf8")
			.split("\n")
			.map((l) => l.trim())
			.filter((l) => l.length > 0 && !l.startsWith("#"));
	} catch {
		return [];
	}
}

/** Find .pi-environments files walking up from cwd (stop after the git root). */
function findProjectEnvironmentsFiles(cwd: string): string[] {
	const found: string[] = [];
	let dir = resolve(cwd);
	let passedGitRoot = false;
	while (true) {
		const candidate = join(dir, ENVIRONMENTS_FILE);
		if (existsSync(candidate)) found.push(candidate);
		if (passedGitRoot || dir === dirname(dir)) break;
		if (existsSync(join(dir, ".git"))) passedGitRoot = true;
		dir = dirname(dir);
		if (passedGitRoot) break;
	}
	return found;
}

function resolveActiveEnvironments(cwd: string): { active: string[]; unknown: string[] } {
	const requested = new Set<string>();

	// 1. Env var (ad hoc).
	const env = process.env.PI_SKILL_ENVIRONMENTS;
	if (env) {
		for (const name of env.split(/[,:]/).map((s) => s.trim()).filter(Boolean)) {
			requested.add(name);
		}
	}

	// 2. Persistent per-project files.
	for (const file of findProjectEnvironmentsFiles(cwd)) {
		for (const name of parseEnvironmentsFile(file)) requested.add(name);
	}

	const available = new Set(listAvailableEnvironments());
	const active: string[] = [];
	const unknown: string[] = [];
	for (const name of requested) {
		if (available.has(name)) active.push(name);
		else unknown.push(name);
	}
	return { active, unknown };
}

function setProjectEnvironment(cwd: string, names: string[]): string {
	const file = join(resolve(cwd), ENVIRONMENTS_FILE);
	const body =
		names.length === 0
			? "# Active skill environments for this project (one per line)\n"
			: `${names.join("\n")}\n`;
	writeFileSync(file, body, "utf8");
	return file;
}

function updateFooterStatus(ctx: { hasUI: boolean; ui: { setStatus(key: string, text: string): void } }, active: string[]): void {
	if (!ctx.hasUI) return;
	ctx.ui.setStatus(
		STATUS_KEY,
		active.length > 0 ? `env: ${active.join("+")}` : "env: none",
	);
}

export default function skillEnvironmentsExtension(pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		const { active } = resolveActiveEnvironments(ctx.cwd);
		updateFooterStatus(ctx, active);
	});

	// Contribute activated environments as extra skill paths.
	pi.on("resources_discover", async (event, ctx) => {
		mkdirSync(ENVIRONMENTS_DIR, { recursive: true });
		const { active, unknown } = resolveActiveEnvironments(event.cwd);
		if (unknown.length > 0 && ctx.hasUI) {
			ctx.ui.notify(
				`skill-environments: unknown environment(s) ignored: ${unknown.join(", ")}. Available: ${listAvailableEnvironments().join(", ") || "(none)"}`,
				"warning",
			);
		}
		updateFooterStatus(ctx, active);
		return { skillPaths: active.map((name) => join(ENVIRONMENTS_DIR, name)) };
	});

	pi.registerCommand("skill-environment", {
		description: "Pick the skill environment for this project (dropdown)",
		handler: async (args, ctx) => {
			const available = listAvailableEnvironments();
			const { active } = resolveActiveEnvironments(ctx.cwd);

			// Direct activation: /skill-environment academic
			const arg = args.trim();
			if (arg) {
				const names = arg.split(/[,:]\s*/).map((s) => s.trim()).filter(Boolean);
				const bad = names.filter((n) => !available.includes(n));
				if (bad.length > 0) {
					ctx.ui.notify(`Unknown environment(s): ${bad.join(", ")}. Available: ${available.join(", ") || "(none)"}`, "error");
					return;
				}
				const file = setProjectEnvironment(ctx.cwd, names);
				ctx.ui.notify(`Environment set to ${names.join(", ")} in ${file}. Reloading...`, "info");
				await ctx.reload();
				return;
			}

			if (!ctx.hasUI) {
				ctx.ui.notify(
					`Available:\n${available.map((n) => `  ${n} — ${describeEnvironment(n)}`).join("\n") || "  (none)"}\nActive here: ${active.join(", ") || "(none)"}. Use /skill-environment <name>.`,
					"info",
				);
				return;
			}

			// Dropdown picker: each option carries a one-sentence description.
			const OFF = "(none — deactivate all)";
			const items = available.map((name) => ({ name, description: describeEnvironment(name) }));
			const choices = [
				...items.map((it) =>
					`${active.includes(it.name) ? "✔ " : ""}${it.name} — ${it.description}${active.includes(it.name) ? "  (active)" : ""}`,
				),
				OFF,
			];
			const choice = await ctx.ui.select("Skill environment for this project", choices);
			if (!choice) return;

			if (choice === OFF) {
				const file = setProjectEnvironment(ctx.cwd, []);
				ctx.ui.notify(`Environments deactivated (${file}). Reloading...`, "info");
				await ctx.reload();
				return;
			}

			const picked = items[choices.indexOf(choice)];
			if (!picked) return;
			const file = setProjectEnvironment(ctx.cwd, [picked.name]);
			ctx.ui.notify(`Environment set to "${picked.name}" in ${file}. Reloading...`, "info");
			await ctx.reload();
		},
	});
}
