"""Offline unit + subprocess tests for panel.py. No network, no OPENROUTER_API_KEY needed.

Run:  python3 -m unittest discover -s skills/ask-the-panel/tests
  or: cd skills/ask-the-panel && python3 -m unittest discover -s tests
"""

import os
import random
import string
import subprocess
import sys
import tempfile
import unittest

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PANEL_PY = os.path.join(SKILL_DIR, "panel.py")

# Import panel.py via path manipulation (it has no package / __init__.py).
sys.path.insert(0, SKILL_DIR)
import panel  # noqa: E402


def run_panel(args, env=None):
    """Run panel.py as a subprocess (isolates argparse SystemExit / real CLI behavior)."""
    full_env = {"PATH": os.environ.get("PATH", "")}
    if env:
        full_env.update(env)
    proc = subprocess.run(
        [sys.executable, PANEL_PY] + args,
        capture_output=True, text=True, env=full_env, timeout=30)
    return proc


class TestCLIValidation(unittest.TestCase):
    def test_list_exits_zero(self):
        proc = run_panel(["--list"])
        self.assertEqual(proc.returncode, 0)
        self.assertIn("DEFAULT_PANEL", proc.stdout)

    def test_missing_key_exits_two(self):
        proc = run_panel(["--question", "hi"])
        self.assertEqual(proc.returncode, 2)
        self.assertIn("OPENROUTER_API_KEY", proc.stderr)

    def test_unknown_alias_exits_two(self):
        proc = run_panel(["--question", "hi", "--models", "bogus"],
                          env={"OPENROUTER_API_KEY": "x"})
        self.assertEqual(proc.returncode, 2)
        self.assertIn("unknown model alias", proc.stderr)

    def test_empty_models_exits_two(self):
        proc = run_panel(["--question", "hi", "--models", ","],
                          env={"OPENROUTER_API_KEY": "x"})
        self.assertEqual(proc.returncode, 2)
        self.assertIn("no models selected", proc.stderr)

    def test_missing_content_exits_two(self):
        proc = run_panel([], env={"OPENROUTER_API_KEY": "x"})
        self.assertEqual(proc.returncode, 2)
        self.assertIn("provide content", proc.stderr)

    def test_nonexistent_file_exits_two(self):
        proc = run_panel(["--file", "/nonexistent-path-xyz", "--question", "hi"],
                          env={"OPENROUTER_API_KEY": "x"})
        self.assertEqual(proc.returncode, 2)
        self.assertIn("cannot read --file", proc.stderr)

    def test_non_utf8_file_exits_two_no_traceback(self):
        fd, path = tempfile.mkstemp()
        try:
            with os.fdopen(fd, "wb") as fh:
                fh.write(b"\xff\xfe not valid utf-8")
            proc = run_panel(["--file", path, "--question", "hi"],
                              env={"OPENROUTER_API_KEY": "x"})
            self.assertEqual(proc.returncode, 2)
            self.assertIn("cannot read --file", proc.stderr)
            self.assertNotIn("Traceback", proc.stderr)
        finally:
            os.unlink(path)

    def test_retries_zero_exits_two(self):
        proc = run_panel(["--retries", "0", "--question", "hi"])
        self.assertEqual(proc.returncode, 2)
        self.assertIn("--retries", proc.stderr)

    def test_max_tokens_zero_exits_two(self):
        proc = run_panel(["--max-tokens", "0", "--question", "hi"])
        self.assertEqual(proc.returncode, 2)
        self.assertIn("--max-tokens", proc.stderr)

    def test_temperature_out_of_range_exits_two(self):
        proc = run_panel(["--temperature", "3", "--question", "hi"])
        self.assertEqual(proc.returncode, 2)
        self.assertIn("--temperature", proc.stderr)

    def test_council_with_adjudicate_exits_two(self):
        proc = run_panel(["--question", "hi", "--council", "--mode", "adjudicate"],
                          env={"OPENROUTER_API_KEY": "x"})
        self.assertEqual(proc.returncode, 2)
        self.assertIn("incompatible with --mode adjudicate", proc.stderr)


class TestOutPath(unittest.TestCase):
    def test_two_default_paths_are_distinct(self):
        fd1, path1 = panel.make_out_path()
        os.close(fd1)
        fd2, path2 = panel.make_out_path()
        os.close(fd2)
        try:
            self.assertNotEqual(path1, path2)
        finally:
            os.unlink(path1)
            os.unlink(path2)

    def test_out_path_is_private(self):
        fd, path = panel.make_out_path()
        os.close(fd)
        try:
            mode = os.stat(path).st_mode & 0o777
            self.assertEqual(mode, 0o600)
        finally:
            os.unlink(path)


class TestBuildCouncilPrompt(unittest.TestCase):
    def setUp(self):
        self.round1 = [
            ("deepseek", "deepseek's reply text"),
            ("gemini", "gemini's reply text"),
            ("gpt", "gpt's reply text"),
        ]

    def test_every_reply_appears_exactly_once(self):
        rng = random.Random(1)
        prompt, mapping = panel.build_council_prompt("Is this sound?", self.round1, rng)
        for alias, text in self.round1:
            self.assertEqual(prompt.count(text), 1)

    def test_letters_are_a_permutation(self):
        rng = random.Random(2)
        _, mapping = panel.build_council_prompt("q", self.round1, rng)
        expected_letters = set(string.ascii_uppercase[:len(self.round1)])
        self.assertEqual(set(mapping.keys()), expected_letters)
        self.assertEqual(sorted(mapping.values()), sorted(a for a, _ in self.round1))

    def test_mapping_matches_prompt_content(self):
        rng = random.Random(3)
        prompt, mapping = panel.build_council_prompt("q", self.round1, rng)
        texts_by_alias = dict(self.round1)
        for letter, alias in mapping.items():
            # The prompt must place that alias's actual text right after "Response <letter>:".
            marker = f"Response {letter}:\n{texts_by_alias[alias]}"
            self.assertIn(marker, prompt)

    def test_judges_own_reply_included(self):
        # The judge isn't a parameter of the pure function — the caller passes round1
        # replies including the judge's own; verify it survives into prompt + mapping.
        rng = random.Random(4)
        prompt, mapping = panel.build_council_prompt("q", self.round1, rng)
        self.assertIn("gemini", mapping.values())
        self.assertIn("gemini's reply text", prompt)

    def test_two_judges_get_independent_orders(self):
        rng = random.Random(42)
        _, mapping_a = panel.build_council_prompt("q", self.round1, rng)
        _, mapping_b = panel.build_council_prompt("q", self.round1, rng)
        # Same seed source but two successive shuffls should (overwhelmingly likely)
        # produce different letter->alias assignments.
        self.assertNotEqual(mapping_a, mapping_b)

    def test_artifact_appears_in_every_judges_prompt(self):
        # Round 2 must carry the full task content (question + artifact), not just the
        # bare question — a judge can't assess "most serious error or omission" without
        # seeing the artifact under critique. main() passes build_user_content's output.
        artifact = "UNIQUE-ARTIFACT-BODY: the plan proposes X then Y."
        question = "Is this sound?"
        task_content = panel.build_user_content(artifact, question)
        rng = random.Random(7)
        for _judge in ("deepseek", "gemini", "gpt"):
            prompt, _ = panel.build_council_prompt(task_content, self.round1, rng)
            self.assertIn(artifact, prompt)
            self.assertIn(question, prompt)


class TestParseChoice(unittest.TestCase):
    def test_error_inside_200(self):
        data = {"error": {"message": "model overloaded", "code": 503}}
        with self.assertRaises(ValueError) as cm:
            panel.parse_choice(data)
        self.assertIn("OpenRouter error", str(cm.exception))
        self.assertIn("model overloaded", str(cm.exception))

    def test_error_inside_200_non_dict_error(self):
        data = {"error": "something broke"}
        with self.assertRaises(ValueError) as cm:
            panel.parse_choice(data)
        self.assertIn("OpenRouter error", str(cm.exception))

    def test_normal_choice(self):
        data = {"choices": [{"message": {"content": "hello"}, "finish_reason": "stop"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 2}}
        text, finish, usage, flag = panel.parse_choice(data)
        self.assertEqual(text, "hello")
        self.assertEqual(finish, "stop")
        self.assertIsNone(flag)

    def test_reasoning_fallback(self):
        data = {"choices": [{"message": {"content": "", "reasoning": "thinking..."},
                             "finish_reason": "stop"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5}}
        text, finish, usage, flag = panel.parse_choice(data)
        self.assertEqual(text, "thinking...")
        self.assertEqual(flag, "reasoning")

    def test_empty_content_tokens_billed(self):
        data = {"choices": [{"message": {"content": ""}, "finish_reason": "length"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5}}
        text, finish, usage, flag = panel.parse_choice(data)
        self.assertEqual(text, "")
        self.assertEqual(flag, "empty")

    def test_missing_choices_raises(self):
        with self.assertRaises(ValueError):
            panel.parse_choice({"unexpected": "shape"})


class TestCostLabel(unittest.TestCase):
    def test_all_exact_is_billed(self):
        results = [{"cost_exact": True}, {"cost_exact": True}]
        self.assertEqual(panel.cost_label(results), "billed")

    def test_mixed_is_not_billed(self):
        results = [{"cost_exact": True}, {"cost_exact": False}]
        label = panel.cost_label(results)
        self.assertNotEqual(label, "billed")
        self.assertEqual(label, "est (mixed)")

    def test_none_exact_is_est(self):
        results = [{"cost_exact": False}, {"cost_exact": False}]
        self.assertEqual(panel.cost_label(results), "est")

    def test_empty_is_est(self):
        self.assertEqual(panel.cost_label([]), "est")


if __name__ == "__main__":
    unittest.main()
