import importlib.util
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "markdown-server"


def load_markdown_server():
    loader = SourceFileLoader("markdown_server", str(MODULE_PATH))
    spec = importlib.util.spec_from_loader("markdown_server", loader)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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


if __name__ == "__main__":
    unittest.main()
