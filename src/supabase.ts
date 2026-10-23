import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL;
const key=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY;
export const configured=Boolean(url&&key);
export const supabase=configured?createClient(url,key):null;
export type SharedSubject={id:string;title:string;description:string;year:number;semester:number};
export type SharedModule={id:string;subject_id:string;title:string;notes:string;position:number};
export type Resource={id:string;module_id:string;title:string;storage_path:string;mime_type:string|null};
export type StudentProfile={id:string;full_name:string;role:'student'|'admin'};
