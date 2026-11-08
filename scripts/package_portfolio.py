"""Package only Git-indexed project files, with explicit sensitive-path exclusions."""
from pathlib import Path
import hashlib
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'releases'
out.mkdir(exist_ok=True)
files = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0')
blocked = {'node_modules', '.git', '.dart_tool', 'build', 'Pods', '.symlinks', 'output', 'releases', '__pycache__'}
archive = out / 'MORI-v1.0.0-portfolio.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in sorted(filter(None, files)):
        rel = Path(name)
        if any(part in blocked for part in rel.parts):
            raise RuntimeError(f'Unexpected generated path in index: {name}')
        if (rel.name.startswith('.env') and rel.name != '.env.example') or rel.suffix in {'.db', '.sqlite', '.pem', '.key', '.p12', '.keystore'}:
            raise RuntimeError(f'Sensitive path in index: {name}')
        if rel.parts[:2] == ('server', 'data'):
            raise RuntimeError(f'Private database path: {name}')
        z.write(root / rel, Path('MORI') / rel)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert 'MORI/docs/deliverables/MORI_presentation.pptx' in z.namelist()
    assert 'MORI/docs/deliverables/MORI_research_report.pdf' in z.namelist()
    count = len(z.namelist())
sha = hashlib.sha256(archive.read_bytes()).hexdigest()
(out / 'SHA256SUMS.txt').write_text(f'{sha}  {archive.name}\n')
print(f'{archive}\n{count} files · {archive.stat().st_size:,} bytes\nSHA256 {sha}')
