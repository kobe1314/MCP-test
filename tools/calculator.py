#!/usr/bin/env python3
"""Simple safe calculator REPL and one-shot evaluator.

Usage:
  python3 calculator.py "2 + 3 * (4 - 1)"
  python3 calculator.py   # starts interactive REPL
"""
import ast
import operator as op
import sys

# supported operators
_OPS = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.Mod: op.mod,
    ast.Pow: op.pow,
    ast.USub: op.neg,
    ast.UAdd: op.pos,
}


def eval_expr(expr: str):
    """Safely evaluate a math expression string and return result."""
    try:
        node = ast.parse(expr, mode="eval").body
        return _eval(node)
    except Exception as e:
        raise ValueError(f"Invalid expression: {e}")


def _eval(node):
    if isinstance(node, ast.Num):  # <number>
        return node.n
    if isinstance(node, ast.BinOp):
        left = _eval(node.left)
        right = _eval(node.right)
        op_type = type(node.op)
        if op_type in _OPS:
            return _OPS[op_type](left, right)
    if isinstance(node, ast.UnaryOp):
        operand = _eval(node.operand)
        op_type = type(node.op)
        if op_type in _OPS:
            return _OPS[op_type](operand)
    if isinstance(node, ast.Expression):
        return _eval(node.body)
    raise ValueError(f"Unsupported expression element: {ast.dump(node)}")


def repl():
    print("Simple calculator. Type 'exit' or Ctrl-D to quit.")
    while True:
        try:
            s = input('> ').strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not s:
            continue
        if s.lower() in ('exit', 'quit'):
            break
        try:
            print(eval_expr(s))
        except Exception as e:
            print(f"Error: {e}")


def main():
    if len(sys.argv) > 1:
        expr = ' '.join(sys.argv[1:])
        try:
            print(eval_expr(expr))
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
    else:
        repl()


if __name__ == '__main__':
    main()
