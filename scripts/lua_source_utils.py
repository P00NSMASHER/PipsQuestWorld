from __future__ import annotations

import re

_LONG_OPEN = re.compile(r"\[(=*)\[")

def mask_lua_comments(source: str) -> str:
    """Replace Lua/Luau comments with spaces while preserving newlines and offsets."""
    out = list(source)
    n = len(source)
    i = 0

    def blank(start: int, end: int) -> None:
        for j in range(start, min(end, n)):
            if out[j] != "\n":
                out[j] = " "

    while i < n:
        ch = source[i]

        # Quoted strings: skip over escapes so '--' inside a string is not a comment.
        if ch == "'" or ch == '"':
            quote = ch
            i += 1
            while i < n:
                if source[i] == "\\":
                    i += 2
                    continue
                if source[i] == quote:
                    i += 1
                    break
                i += 1
            continue

        # Lua long strings: preserve content and skip comment parsing inside.
        m = _LONG_OPEN.match(source, i)
        if m:
            eq = m.group(1)
            close = "]" + eq + "]"
            end = source.find(close, m.end())
            i = n if end < 0 else end + len(close)
            continue

        if source.startswith("--", i):
            # Long/block comment: --[[...]], --[=[...]=], etc.
            m = _LONG_OPEN.match(source, i + 2)
            if m:
                eq = m.group(1)
                close = "]" + eq + "]"
                end = source.find(close, m.end())
                if end < 0:
                    blank(i, n)
                    break
                end += len(close)
                blank(i, end)
                i = end
                continue

            # Single-line comment.
            end = source.find("\n", i)
            if end < 0:
                blank(i, n)
                break
            blank(i, end)
            i = end
            continue

        i += 1

    return "".join(out)
