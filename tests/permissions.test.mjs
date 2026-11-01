import {test} from 'node:test';
import assert from 'node:assert/strict';
import {scopeFor,editable} from '../src/permissions.ts';
const p={user_id:'test',display_name:'Test',role:'talent_broker',active:true,team_id:null};
test('talent broker has no sales pipeline access by default',()=>assert.equal(scopeFor(p,[],'opportunities'),'none'));
test('individual override grants sales access without changing primary role',()=>{assert.equal(scopeFor(p,[{module:'opportunities',scope:'edit_assigned'}],'opportunities'),'edit_assigned');assert.equal(p.role,'talent_broker')});
test('explicit denial overrides admin role defaults',()=>assert.equal(scopeFor({...p,role:'admin'},[{module:'candidates',scope:'none'}],'candidates'),'none'));
test('inactive users have no permissions even with full override',()=>assert.equal(scopeFor({...p,active:false},[{module:'candidates',scope:'full'}],'candidates'),'none'));
test('view scopes never allow writes',()=>{assert.equal(editable('view_assigned'),false);assert.equal(editable('view_team'),false);assert.equal(editable('edit_team'),true)});
