"""Extract official HIRA snapshot; no inferred language support or reviews."""
import csv, io, json, zipfile, hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
z=zipfile.ZipFile(root/'reference-data/HIRA_202609.zip')
def rows(index):
 name=next(n for n in z.namelist() if n.startswith(str(index)+'.'))
 return csv.DictReader(io.StringIO(z.read(name).decode('cp949')))
hospitals={}
for r in rows(1):
 if '포항' not in r['시군구코드명']: continue
 key=r['암호화요양기호']
 hospitals[key]={'id':hashlib.sha256(key.encode()).hexdigest()[:24],'name':r['요양기관명'],'type':r['종별코드명'],'address':r['주소'],'phone':r['전화번호'],'doctors':int(r['총의사수'] or 0),'longitude':r['좌표(X)'] or None,'latitude':r['좌표(Y)'] or None,'departments':[],'beds':None,'languageSupport':'unverified'}
for r in rows(3):
 if r['암호화요양기호'] in hospitals:
  hospitals[r['암호화요양기호']]['beds']={k:int(r[k] or 0) for k in ['일반입원실상급병상수','일반입원실일반병상수','응급실병상수']}
for r in rows(5):
 if r['암호화요양기호'] in hospitals:
  hospitals[r['암호화요양기호']]['departments'].append({'name':r['진료과목코드명'],'specialists':int(r['과목별 전문의수'] or 0)})
result={'source':'건강보험심사평가원 · 전국 병의원 및 약국 현황','sourceUrl':'https://www.data.go.kr/data/15051059/fileData.do','snapshot':'2026-09-30','license':'공공누리 제1유형 · 출처표시','hospitals':sorted(hospitals.values(),key=lambda h:h['name'])}
out=root/'server/resources';out.mkdir(exist_ok=True)
(out/'hospitals.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print('Imported',len(hospitals),'Pohang institutions; departments and facility counts joined by HIRA ID.')
