import {test} from 'node:test';
import assert from 'node:assert/strict';
import {calendarDays,dayKey,stepDate,overlapsDay,layoutEvents,inputDateTime} from '../src/calendar-utils.ts';
test('week starts on Monday and contains seven local dates',()=>{const days=calendarDays(new Date(2026,10,1),'week');assert.equal(days.length,7);assert.equal(days[0].getDay(),1);assert.equal(dayKey(days[0]),'2026-10-26');assert.equal(dayKey(days[6]),'2026-11-01')});
test('month view includes the complete visible six-week grid',()=>{const days=calendarDays(new Date(2026,10,1),'month');assert.equal(days.length,42);assert.equal(days[0].getDay(),1);assert.equal(dayKey(days[0]),'2026-10-26');assert.equal(dayKey(days[41]),'2026-12-06')});
test('month navigation does not skip February from January 31',()=>assert.equal(dayKey(stepDate(new Date(2027,0,31),'month',1)),'2027-02-01'));
test('an event ending at midnight is not shown in the following day',()=>{const d=new Date(2026,10,1);assert.equal(overlapsDay(new Date(2026,9,31,23,30).toISOString(),d.toISOString(),d),false)});
test('overlapping events get separate columns, sequential groups reuse width',()=>{const rows=[{id:'a',starts_at:'2026-11-01T09:00:00Z',ends_at:'2026-11-01T10:00:00Z'},{id:'b',starts_at:'2026-11-01T09:30:00Z',ends_at:'2026-11-01T10:30:00Z'},{id:'c',starts_at:'2026-11-01T11:00:00Z',ends_at:'2026-11-01T12:00:00Z'}];const result=layoutEvents(rows);assert.equal(result[0].columns,2);assert.notEqual(result[0].column,result[1].column);assert.equal(result[2].columns,1)});
test('datetime form value uses local wall time, not UTC conversion',()=>assert.equal(inputDateTime(new Date(2026,10,1,9,30)),'2026-11-01T09:30'));
