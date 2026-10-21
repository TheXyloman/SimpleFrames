"""Create an installable Forever ZIP from the addon sources (Python standard library)."""
from pathlib import Path
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parents[1]
addon = root / 'SimpleFrames'
toc = (addon / 'SimpleFrames.toc').read_text()
version = re.search(r'^## Version: (.+)$', toc, re.M).group(1)
assert f'SF.version = "{version}"' in (addon / 'Defaults.lua').read_text()
assert re.search(r'^## Interface: 16001$', toc, re.M), 'Reconfirm the target interface before changing the package'
for line in toc.splitlines():
    if line and not line.startswith('#'):
        assert (addon / line).is_file(), f'Missing TOC file: {line}'
output = root / 'dist' / f'SimpleFrames-{version}-Forever.zip'
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(addon.iterdir()):
        if path.is_file() and path.suffix in {'.lua', '.toc', '.png', '.tga'}:
            archive.write(path, f'SimpleFrames/{path.name}')
    archive.write(root / 'README.md', 'SimpleFrames/README.md')
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert all(name.startswith('SimpleFrames/') for name in archive.namelist())
    count = len(archive.namelist())
checksum = hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{checksum}  {output.name}\n')
print(f'{output}\n{count} files; SHA-256 {checksum}')
