import test from 'node:test';
import assert from 'node:assert/strict';
import {aiConfigured,translateSnapshot} from '../src/ai.js';

test('Gemini sends only selected fields, rejects changed numbers and handles provider failure', async t => {
  const saved = {provider:process.env.AI_PROVIDER,key:process.env.GEMINI_API_KEY,model:process.env.GEMINI_MODEL,fetch:globalThis.fetch};
  t.after(()=>{for(const [key,value] of [['AI_PROVIDER',saved.provider],['GEMINI_API_KEY',saved.key],['GEMINI_MODEL',saved.model]]) {if(value===undefined) delete process.env[key]; else process.env[key]=value;} globalThis.fetch=saved.fetch;});
  process.env.AI_PROVIDER='gemini';process.env.GEMINI_MODEL='gemini-2.5-flash';delete process.env.GEMINI_API_KEY;
  assert.equal(aiConfigured(),false);
  process.env.GEMINI_API_KEY='test-only';assert.equal(aiConfigured(),true);
  const snapshot={symptoms:'Pain for 2 days',onset:'2 days ago',profile:{allergies:{status:'unknown',detail:''},medications:{status:'none',detail:''}},journals:[],intake:{patientName:'PRIVATE TEST NAME'}};
  let translation={symptomsKo:'통증 2일',onsetKo:'2일 전',allergiesKo:'미확인',medicationsKo:'없음',journalKo:[]};
  globalThis.fetch=async(url,options)=>{
    assert.equal(new URL(url).hostname,'generativelanguage.googleapis.com');
    assert.ok(!url.includes('test-only'));
    assert.ok(!options.body.includes('PRIVATE TEST NAME'));
    assert.equal(options.headers['x-goog-api-key'],'test-only');
    return {ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify(translation)}]}}]})};
  };
  const result=await translateSnapshot(snapshot);assert.equal(result.allergiesKo,'모름 / 미확인');
  translation={...translation,symptomsKo:'통증 3일'};
  await assert.rejects(()=>translateSnapshot(snapshot),/number/);
  globalThis.fetch=async()=>({ok:false});await assert.rejects(()=>translateSnapshot(snapshot),/unavailable/);
});
