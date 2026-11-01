import {test} from 'node:test';
import assert from 'node:assert/strict';
import {translate,initialLanguage,sv} from '../src/i18n.ts';
test('Swedish is the default without stored language',()=>assert.equal(initialLanguage(),'sv'));
test('English labels remain unchanged',()=>assert.equal(translate('en','Dashboard'),'Dashboard'));
test('core workflow and permission labels are Swedish',()=>{for(const key of ['Dashboard','Sales Pipeline','Candidates','Sign in','New Lead','edit_assigned'])assert.notEqual(translate('sv',key),key)});
test('unknown business text is never modified',()=>assert.equal(translate('sv','Example Company AB'),'Example Company AB'));
test('every translation has content',()=>assert.ok(Object.values(sv).every(v=>v.trim().length>0)));
