import importlib.util
import http.client
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


if __name__ == "__main__":
    unittest.main()
