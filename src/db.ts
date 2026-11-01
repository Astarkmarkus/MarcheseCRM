import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL,key=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
export const db=url&&key?createClient(url,key):null;
export type Row={id:string;name:string;status?:string;stage?:string;owner_id?:string;team_id?:string|null;created_at:string;[key:string]:unknown};
export const salesStages=['New Lead','Researching','Contacted','Interested','Qualified','Meeting Booked','Meeting Completed','Proposal Sent','Negotiation','Won','Lost'];
export const candidateStages=['New Candidate','Screening','Interview Scheduled','Interview Completed','Qualified','Presented to Client','Client Interview','Offer','Placed / Hired','Rejected / Withdrawn'];
