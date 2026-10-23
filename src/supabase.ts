import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL;
const key=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY;
export const configured=Boolean(url&&key);
export const supabase=url && key ? createClient(url,key) : null;
export type SharedSubject={id:string;title:string;code:string|null;description:string;year:number;semester:number};
export type SharedModule={id:string;subject_id:string;title:string;notes:string;content_json:{version:number;blocks:Array<{type:string;text:string}>};position:number};
export type Resource={id:string;module_id:string;title:string;storage_path:string;mime_type:string|null};
export type StudentProfile={id:string;full_name:string;role:'student'|'admin';phone:string|null;institution:string|null;programme:string|null;study_year:number|null;study_semester:number|null};
