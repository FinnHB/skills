"""Starter step. Replace with real analysis. Demonstrates provenance recording."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import pipeline
os.makedirs("output", exist_ok=True)
out = "output/example.txt"
with open(out, "w") as f: f.write("hello from {{MODULE}}\n")
pipeline.record("src/01_example.py", inputs=[], outputs=[out])
