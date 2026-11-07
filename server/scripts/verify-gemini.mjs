// Run from server/: node --env-file=.env scripts/verify-gemini.mjs
// Sends fictional fixtures only. Never reads patient records or prints credentials.
import { translateSnapshot } from '../src/ai.js';
import { mkdirSync, writeFileSync } from 'node:fs';
const cases = [
  { language: 'English', symptoms: 'TEST ONLY. Sore throat and cough for 2 days. No shortness of breath.', onset: '2 days ago', allergies: {status:'known',detail:'TEST ONLY: Penicillin'}, medications:{status:'none',detail:''}},
  { language: 'French', symptoms: 'TEST ONLY. Mal à la tête depuis 3 jours. Pas de vomissements.', onset: 'Il y a 3 jours', allergies:{status:'unknown',detail:''},medications:{status:'known',detail:'TEST ONLY: Vitamin C 500 mg once daily.'}},
  { language: 'Japanese', symptoms: 'TEST ONLY. 昨日から喉が痛いです。発熱はありません。', onset:'昨日',allergies:{status:'none',detail:''},medications:{status:'unknown',detail:''}},
];
cases.push({language:'English with selected diary',symptoms:'TEST ONLY. Sore throat and cough. Worse today.',onset:'2 days ago',allergies:{status:'known',detail:'TEST ONLY: Penicillin allergy'},medications:{status:'none',detail:''},journals:[{id:'fictional-journal-1',date:'2026-11-08',condition:'low',sleep:6,note:'TEST ONLY: Slept 6 hours. Throat discomfort.'}]});
const results = [];
for (const c of cases) {
  const snapshot={symptoms:c.symptoms,onset:c.onset,profile:{allergies:c.allergies,medications:c.medications},journals:c.journals??[]};
  const start=Date.now();
  try {
    const translation=await translateSnapshot(snapshot);
    const result={language:c.language,ok:true,elapsedMs:Date.now()-start,original:snapshot,translation};
    results.push(result);console.log(JSON.stringify(result));
  } catch(e) {
    results.push({language:c.language,ok:false,status:e.status||null,message:e.message,elapsedMs:Date.now()-start});
    console.log(JSON.stringify(results.at(-1)));process.exitCode=1;
  }
}
mkdirSync('../output/qa-gemini',{recursive:true});
writeFileSync('../output/qa-gemini/live-translation-20261108.json',JSON.stringify({model:process.env.GEMINI_MODEL,fictionalOnly:true,results},null,2));
