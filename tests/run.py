"""Optional runner: python3 -m pip install lupa==2.6; python3 tests/run.py.
Uses Lua 5.1, the addon language version; no Python runtime ships in the addon.
"""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime
os.chdir(Path(__file__).resolve().parents[1])
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval('function(s, name) local fn, err = loadstring(s, name); return fn ~= nil, err end')
for path in Path('SimpleFrames').glob('*.lua'):
    ok, error = compile_lua(path.read_text(), str(path))
    assert ok, error
print('PASS: all addon files parse as Lua 5.1', flush=True)
lua.execute(Path('tests/run.lua').read_text())
