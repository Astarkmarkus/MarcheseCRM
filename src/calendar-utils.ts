export type CalendarView='day'|'week'|'month';
export function dayStart(date:Date){const d=new Date(date);d.setHours(0,0,0,0);return d}
export function addDays(date:Date,n:number){const d=new Date(date);d.setDate(d.getDate()+n);return d}
export function monday(date:Date){const d=dayStart(date);return addDays(d,-((d.getDay()+6)%7))}
export function dayKey(date:Date){return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`}
export function inputDateTime(date:Date){return `${dayKey(date)}T${String(date.getHours()).padStart(2,'0')}:${String(date.getMinutes()).padStart(2,'0')}`}
export function calendarDays(date:Date,view:CalendarView){const start=view==='day'?dayStart(date):view==='week'?monday(date):monday(new Date(date.getFullYear(),date.getMonth(),1));return Array.from({length:view==='day'?1:view==='week'?7:42},(_,i)=>addDays(start,i))}
export function stepDate(date:Date,view:CalendarView,direction:number){if(view!=='month')return addDays(date,direction*(view==='week'?7:1));return new Date(date.getFullYear(),date.getMonth()+direction,1)}
export function overlapsDay(start:string,end:string,day:Date){return +new Date(start)<+addDays(dayStart(day),1)&&+new Date(end)>+dayStart(day)}
// Assign overlap columns per connected group, keeping simultaneous events readable.
export function layoutEvents<T extends {id:string;starts_at:string;ends_at:string}>(events:T[]){
 const sorted=[...events].sort((a,b)=>+new Date(a.starts_at)-+new Date(b.starts_at));const result:{event:T;column:number;columns:number}[]=[];
 let group:{event:T;column:number;columns:number}[]=[],ends:number[]=[],groupEnd=-Infinity;
 const flush=()=>{for(const item of group){item.columns=ends.length;result.push(item)}group=[];ends=[];groupEnd=-Infinity};
 for(const event of sorted){const start=+new Date(event.starts_at),end=+new Date(event.ends_at);if(start>=groupEnd)flush();let col=ends.findIndex(e=>e<=start);if(col<0)col=ends.length;ends[col]=end;group.push({event,column:col,columns:0});groupEnd=Math.max(groupEnd,end)}flush();return result;
}
