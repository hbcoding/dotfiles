#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/.local/share/nvim/site/parser"
mkdir -p "$DEST"

build_parser() {
  local name="$1" url="$2" rev="$3" subdir="${4:-.}"
  local work="/tmp/ts-$name"

  echo "==> Building $name from $url@$rev"
  rm -rf "$work"
  git clone --quiet "$url" "$work"
  (
    cd "$work"
    git checkout --quiet "$rev"
    cd "$subdir"
    tree-sitter generate 2>/dev/null || true
    if [ -f src/scanner.c ]; then
      cc -o "$name.so" -shared -Os -I./src src/parser.c src/scanner.c -fPIC
    elif [ -f src/scanner.cc ]; then
      c++ -o "$name.so" -shared -Os -I./src src/parser.c src/scanner.cc -fPIC
    else
      cc -o "$name.so" -shared -Os -I./src src/parser.c -fPIC
    fi
    mv "$name.so" "$DEST/"
  )
  rm -rf "$work"
  echo "    installed $DEST/$name.so"
}

build_parser lua             https://github.com/tree-sitter-grammars/tree-sitter-lua       10fe0054734eec83049514ea2e718b2a56acd0c9
build_parser latex           https://github.com/latex-lsp/tree-sitter-latex               7e0ecdc02926c7b9b2e0c76003d4fe7b0944f957
build_parser markdown        https://github.com/tree-sitter-grammars/tree-sitter-markdown a0a00f817d02412bd92c54d316f164d827b57b5c tree-sitter-markdown
build_parser markdown_inline https://github.com/tree-sitter-grammars/tree-sitter-markdown a0a00f817d02412bd92c54d316f164d827b57b5c tree-sitter-markdown-inline

echo ""
echo "Done. Installed parsers:"
ls "$DEST"
