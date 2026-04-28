import importlib.util
import http.client
import json
import os
import re
import tempfile
import threading
import unittest
from contextlib import contextmanager
from http.server import HTTPServer
from importlib.machinery import SourceFileLoader
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "markdown-server"


def load_markdown_server():
    loader = SourceFileLoader("markdown_server", str(MODULE_PATH))
    spec = importlib.util.spec_from_loader("markdown_server", loader)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@contextmanager
def chdir(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


class MarkdownServerTest(unittest.TestCase):
    def fetch_json(self, server, path):
        connection = http.client.HTTPConnection(*server.server_address)
        connection.request("GET", path)
        response = connection.getresponse()
        body = response.read().decode("utf-8")
        if response.status != 200:
            self.fail(f"expected 200 for {path}, got {response.status}: {body}")
        return json.loads(body)

    def test_process_mermaid_blocks_preserves_diagram_source_and_regular_code(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)
        content = """# Design

```mermaid
sequenceDiagram
    Alice->>Bob: <hello>
```

```python
print("still code")
```
"""

        processed = handler.process_mermaid_blocks(content)

        self.assertIn('<pre class="mermaid">sequenceDiagram', processed)
        self.assertIn("Alice-&gt;&gt;Bob: &lt;hello&gt;", processed)
        self.assertIn("```python", processed)
        self.assertIn('print("still code")', processed)

    def test_heading_styles_do_not_draw_underlines(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)

        rendered = handler.wrap_html(
            "<h1>Title</h1><h2>Section</h2><h3>Subsection</h3>",
            "Title",
        )

        for selector in ("h1", "h2", ".dir-title"):
            with self.subTest(selector=selector):
                self.assertIsNone(
                    re.search(rf"{re.escape(selector)}\s*\{{[^}}]*border-bottom", rendered)
                )

    def test_codehilite_highlight_wrapper_clips_to_rounded_pre_corners(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)

        rendered = handler.wrap_html('<div class="highlight"><pre>code</pre></div>', "Code")

        self.assertRegex(rendered, r"\.highlight\s*\{[^}]*border-radius:\s*8px")
        self.assertRegex(rendered, r"\.highlight\s*\{[^}]*overflow:\s*hidden")
        self.assertRegex(rendered, r"\.highlight\s*>\s*pre\s*\{[^}]*margin:\s*0")

    def test_relative_link_to_sibling_directory_serves_target_file(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            wiki = workspace / "wiki"
            target_dir = workspace / "py_test" / "tests"
            wiki.mkdir()
            target_dir.mkdir(parents=True)
            (wiki / "index.md").write_text(
                "1. [../py_test/tests/test_foo.py:4-9](../py_test/tests/test_foo.py:4)\n",
                encoding="utf-8",
            )
            (target_dir / "test_foo.py").write_text(
                "line 1\nline 2\nline 3\ndef test_foo():\n    assert True\n",
                encoding="utf-8",
            )

            with chdir(wiki):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/py_test/tests/test_foo.py:4")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn("test_foo.py", body)
            self.assertIn("test_foo", body)
            self.assertIn("assert", body)
            self.assertIn('<a class="crumb" href="/..">..</a>', body)

    def test_markdown_file_under_served_subdirectory_is_served(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            wiki = workspace / "wiki"
            wiki.mkdir()
            (wiki / "Goals.md").write_text("# Goals\n\nKeep notes here.\n", encoding="utf-8")

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/wiki/Goals.md")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn("<h1", body)
            self.assertIn("Goals", body)
            self.assertIn('<a class="crumb" href="/wiki">wiki</a>', body)

    def test_markdown_frontmatter_renders_as_preformatted_box(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Note.md").write_text(
                "---\ntitle: Launch Plan\nstatus: draft\n---\n# Launch\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/Note.md")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn('<pre class="frontmatter"><code>', body)
            self.assertIn("title: Launch Plan\nstatus: draft", body)
            self.assertIn("<h1", body)
            self.assertIn("Launch", body)

    def test_markdown_backslash_math_delimiters_are_preserved_for_mathjax(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Math.md").write_text(
                "Inline math \\(a < b\\) stays inline.\n\n\\[x^2 + y^2 = z^2\\]\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/Math.md")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn('<span class="math-inline">\\(a &lt; b\\)</span>', body)
            self.assertIn('<div class="math-display">\\[x^2 + y^2 = z^2\\]</div>', body)

    def test_markdown_obsidian_block_anchors_add_element_ids(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Blocks.md").write_text(
                "Link to [item](#^item-one).\n\n"
                "Lorem ipsum\n\n"
                "- item one ^item-one\n"
                "- item two ^item-two\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/Blocks.md")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn('<a href="#^item-one">item</a>', body)
            self.assertIn('<li id="^item-one">item one</li>', body)
            self.assertIn('<li id="^item-two">item two</li>', body)
            self.assertNotIn("item one ^item-one", body)

    def test_markdown_extended_syntax_renders_correctly(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Syntax.md").write_text(
                "***Bold and italic*** and ___also bold and italic___\n\n"
                "```javascript\nfunction greet(name) {\n  return name;\n}\n```\n\n"
                "Term\n: Definition of the term\n\n"
                "Special characters: \\\\ \\` \\* \\_ \\{ \\} \\[ \\] \\( \\) \\# \\+ \\- \\. \\!\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/Syntax.md")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 200, body)
            self.assertIn("<strong><em>Bold and italic</em></strong>", body)
            self.assertIn("<strong><em>also bold and italic</em></strong>", body)
            self.assertIn('<div class="highlight"><pre>', body)
            self.assertIn('<span class="kd">function</span>', body)
            self.assertIn("<dl>", body)
            self.assertIn("<dt>Term</dt>", body)
            self.assertIn("<dd>Definition of the term</dd>", body)
            self.assertIn("Special characters: \\ ` * _ { } [ ] ( ) # + - . !", body)
            self.assertNotIn('<span class="math-inline">\\( \\)</span>', body)
            self.assertNotIn('<div class="math-display">\\[ \\]</div>', body)

    def test_directory_without_trailing_slash_redirects_before_serving_index(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            wiki = workspace / "wiki"
            wiki.mkdir()
            (wiki / "index.md").write_text("[Goals](Goals.md)\n", encoding="utf-8")
            (wiki / "Goals.md").write_text("# Goals\n", encoding="utf-8")

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/wiki")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 301, body)
            self.assertEqual(response.getheader("Location"), "/wiki/")

    def test_directory_url_with_repeated_slashes_redirects_to_canonical_path(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            target_dir = workspace / "actual" / "bin"
            target_dir.mkdir(parents=True)
            (target_dir / "tool").write_text("#!/bin/sh\n", encoding="utf-8")

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    connection = http.client.HTTPConnection(*server.server_address)
                    connection.request("GET", "/actual//bin/")
                    response = connection.getresponse()
                    body = response.read().decode("utf-8")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(response.status, 301, body)
            self.assertEqual(response.getheader("Location"), "/actual/bin/")

    def test_search_returns_filename_matches_from_served_root(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Project Plan.md").write_text("# Notes\n", encoding="utf-8")
            (workspace / "Other.md").write_text("# Other\n", encoding="utf-8")

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    payload = self.fetch_json(server, "/_search?q=project")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertGreaterEqual(len(payload["results"]), 1)
            first = payload["results"][0]
            self.assertEqual(first["type"], "filename")
            self.assertEqual(first["path"], "Project Plan.md")
            self.assertEqual(first["url"], "/Project%20Plan.md")

    def test_search_returns_content_matches_with_line_numbers_and_previews(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Notes.md").write_text(
                "# Notes\nThe launch needle is in this line.\nDone.\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    payload = self.fetch_json(server, "/_search?q=needle")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            content_results = [result for result in payload["results"] if result["type"] == "content"]
            self.assertEqual(len(content_results), 1)
            result = content_results[0]
            self.assertEqual(result["path"], "Notes.md")
            self.assertEqual(result["line"], 2)
            self.assertEqual(result["url"], "/Notes.md:2")
            self.assertIn("launch needle", result["preview"])

    def test_search_treats_content_query_as_literal_text(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Notes.md").write_text(
                "Literal function_name( text.\n",
                encoding="utf-8",
            )

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    payload = self.fetch_json(server, "/_search?q=function_name%28")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            content_results = [result for result in payload["results"] if result["type"] == "content"]
            self.assertEqual(len(content_results), 1)
            self.assertEqual(content_results[0]["line"], 1)

    def test_search_scope_stays_within_served_root(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            served = workspace / "served"
            sibling = workspace / "sibling"
            served.mkdir()
            sibling.mkdir()
            (served / "Inside.md").write_text("visible term\n", encoding="utf-8")
            (sibling / "Outside.md").write_text("secret-outside-term\n", encoding="utf-8")

            with chdir(served):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    payload = self.fetch_json(server, "/_search?q=secret-outside-term")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(payload["results"], [])

    def test_search_empty_query_returns_empty_results(self):
        module = load_markdown_server()

        with tempfile.TemporaryDirectory() as tmp:
            workspace = Path(tmp)
            (workspace / "Anything.md").write_text("needle\n", encoding="utf-8")

            with chdir(workspace):
                server = HTTPServer(("127.0.0.1", 0), module.MarkdownHandler)
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    payload = self.fetch_json(server, "/_search?q=")
                finally:
                    server.shutdown()
                    thread.join(timeout=2)
                    server.server_close()

            self.assertEqual(payload["results"], [])

    def test_wrap_html_includes_search_modal_and_keyboard_shortcut(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)

        rendered = handler.wrap_html("<h1>Title</h1>", "Title")

        self.assertIn('id="search-overlay"', rendered)
        self.assertIn('id="search-input"', rendered)
        self.assertIn("event.metaKey", rendered)
        self.assertIn("event.ctrlKey", rendered)
        self.assertIn('key === "n"', rendered)
        self.assertIn('key === "p"', rendered)

    def test_wrap_html_includes_theme_config_panel(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)

        rendered = handler.wrap_html("<h1>Title</h1>", "Title")

        self.assertIn('<div class="page-chrome">', rendered)
        self.assertIn('<div class="controls">', rendered)
        self.assertLess(rendered.index('<div class="page-chrome">'), rendered.index('<nav class="breadcrumb"'))
        self.assertLess(rendered.index('<nav class="breadcrumb"'), rendered.index('<div class="controls">'))
        self.assertLess(rendered.index('<div class="controls">'), rendered.index('id="config-toggle"'))
        self.assertIn('id="config-toggle"', rendered)
        self.assertIn('aria-label="Open configuration"', rendered)
        self.assertIn('id="config-panel"', rendered)
        self.assertIn('class="config-drawer"', rendered)
        self.assertIn('name="theme-choice"', rendered)
        self.assertIn('value="system"', rendered)
        self.assertIn('value="light"', rendered)
        self.assertIn('value="dark"', rendered)
        self.assertIn('value="system" checked', rendered)
        self.assertIn('localStorage.getItem("markdown-server-theme")', rendered)
        self.assertIn('document.documentElement.dataset.theme', rendered)
        self.assertNotRegex(rendered, r"\.config-toggle\s*\{[^}]*position:\s*fixed")
        self.assertNotRegex(rendered, r"\.config-toggle\s*\{[^}]*border:\s*1px")
        self.assertRegex(rendered, r"\.config-toggle\s*\{[^}]*padding:\s*0")

    def test_wrap_html_includes_mathjax_configuration(self):
        module = load_markdown_server()
        handler = module.MarkdownHandler.__new__(module.MarkdownHandler)

        rendered = handler.wrap_html("<p>$x^2$</p>", "Math")

        self.assertIn("window.MathJax", rendered)
        self.assertIn("inlineMath", rendered)
        self.assertIn("displayMath", rendered)
        self.assertIn("mathjax@3", rendered)


if __name__ == "__main__":
    unittest.main()
