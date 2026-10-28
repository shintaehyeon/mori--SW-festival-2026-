from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root=Path(__file__).resolve().parents[1]
out=root.parent/'CareBridge_Flutter_MVP_소스.zip'
blocked={'node_modules','data','.dart_tool','build','Pods','.symlinks','.git','.idea','ephemeral','FlutterGeneratedPluginSwiftPackage','.swiftpm','__pycache__'}
with ZipFile(out,'w',ZIP_DEFLATED) as z:
 for p in sorted(root.rglob('*')):
  rel=p.relative_to(root)
  if not p.is_file() or any(part in blocked for part in rel.parts): continue
  if p.name in {'.DS_Store','.flutter-plugins-dependencies','local.properties','Generated.xcconfig','flutter_export_environment.sh'}: continue
  if p.name.startswith('.env') and p.name!='.env.example': continue
  if p.suffix in {'.sqlite','.log','.pyc','.iml'}: continue
  z.write(p,Path('carebridge')/rel)
with ZipFile(out) as z:
 assert z.testzip() is None
 assert all('data' not in Path(n).parts and 'node_modules' not in Path(n).parts for n in z.namelist())
 print(f'{out.name}: {len(z.namelist())} files, {out.stat().st_size:,} bytes. Integrity OK.')
