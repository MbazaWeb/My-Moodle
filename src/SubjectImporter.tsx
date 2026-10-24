import {useEffect,useState} from 'react';
import {supabase,type SharedSubject} from './supabase';
type Chapter={title:string;notes:string};
const sb=supabase!;
export default function SubjectImporter({subject,onSaved}:{subject:SharedSubject;onSaved:()=>void}){
 const [file,setFile]=useState<File|null>(null),[chapters,setChapters]=useState<Chapter[]>([]),[phase,setPhase]=useState<'idle'|'extracting'|'preview'|'saving'|'saved'>('idle'),[progress,setProgress]=useState(0),[current,setCurrent]=useState(''),[error,setError]=useState(''),[jobId,setJobId]=useState<string|null>(null);
 useEffect(()=>{setFile(null);setChapters([]);setPhase('idle');setProgress(0);setJobId(null);setError('')},[subject.id]);
 async function convert(){
  if(!file)return;if(subject.is_published){setError('Hide the subject before importing new chapters.');return}setError('');setPhase('extracting');setProgress(0);setCurrent('Uploading document for backend extraction');
  try{
   const {data:{session}}=await sb.auth.getSession();
   if(!session)throw Error('Please sign in again.');
   const {data:job,error:jobError}=await sb.from('study_import_jobs').insert({subject_id:subject.id,instructor_id:session.user.id,filename:file.name,status:'processing',progress:0}).select('id').single();
   if(jobError)throw jobError;setJobId(job.id);
   const form=new FormData();form.append('subject_id',subject.id);form.append('file',file);
   const response=await fetch(import.meta.env.VITE_SUPABASE_URL+'/functions/v1/subject-import',{method:'POST',headers:{Authorization:'Bearer '+session.access_token,apikey:String(import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY||import.meta.env.VITE_SUPABASE_ANON_KEY||'')},body:form});
   const result=await response.json();if(!response.ok)throw Error(result.error||'Conversion failed');
   if(!Array.isArray(result.chapters)||!result.chapters.length)throw Error('No chapters found.');
   setChapters(result.chapters);setProgress(100);setCurrent(result.chapters.length+' chapters extracted. Review before saving.');setPhase('preview');
   await sb.from('study_import_jobs').update({status:'preview',progress:100,chapters_total:result.chapters.length,chapters_done:result.chapters.length,updated_at:new Date().toISOString()}).eq('id',job.id);
  }catch(e){setError(e instanceof Error?e.message:String(e));setPhase('idle');if(jobId)void sb.from('study_import_jobs').update({status:'failed',error_message:String(e)}).eq('id',jobId)}
 }
 async function saveDraft(){
  if(!chapters.length)return;if(subject.is_published){setError('Hide the subject before saving imported chapters.');return}setError('');setPhase('saving');setProgress(0);
  try{
   const {data:existing,error:loadError}=await sb.from('study_modules').select('id,position').eq('subject_id',subject.id).order('position',{ascending:false}).limit(1);
   if(loadError)throw loadError;
   const start=existing?.length?existing[0].position+1:0;
   for(let i=0;i<chapters.length;i++){
    const ch=chapters[i];setCurrent('Saving chapter '+(i+1)+' of '+chapters.length+': '+ch.title);
    const {error:saveError}=await sb.from('study_modules').insert({subject_id:subject.id,title:ch.title,notes:ch.notes,position:start+i,content_json:{version:1,blocks:[{type:'paragraph',text:ch.notes}]}});
    if(saveError)throw saveError;
    const percent=Math.round((i+1)/chapters.length*100);setProgress(percent);
    if(jobId)await sb.from('study_import_jobs').update({status:'processing',progress:percent,chapters_total:chapters.length,chapters_done:i+1,updated_at:new Date().toISOString()}).eq('id',jobId);
   }
   if(jobId)await sb.from('study_import_jobs').update({status:'saved',progress:100,updated_at:new Date().toISOString()}).eq('id',jobId);
   setPhase('saved');setCurrent('All chapters saved. Subject remains '+(subject.is_published?'published':'draft')+'.');onSaved();
  }catch(e){setError(e instanceof Error?e.message:String(e));setPhase('preview')}
 }
 return <section className="card stack subject-importer"><h2>Import Subject Document</h2><p className="muted">Upload PDF, Word (.docx), or text (.txt), up to 8 MB. The backend extracts existing text and separates chapters. Scanned PDFs need OCR and legacy .doc files must be converted to .docx.</p>
  <input type="file" accept=".pdf,.docx,.txt,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document,text/plain" disabled={phase==='extracting'||phase==='saving'} onChange={e=>setFile(e.target.files?.[0]||null)}/>
  {subject.is_published&&<p className="muted">Hide this subject before importing so the new chapters remain private until publication.</p>}<button disabled={subject.is_published||!file||phase==='extracting'||phase==='saving'} onClick={()=>void convert()}>Convert to Chapters</button>
  {error&&<p className="error" role="alert">{error}</p>}
  {phase!=='idle'&&<div className="import-status" role="status" aria-live="polite"><div className="row"><strong>{phase==='extracting'?'Extracting document…':phase==='preview'?'Preview ready':phase==='saving'?'Saving chapter by chapter…':'Saved successfully'}</strong><strong>{phase==='extracting'?'Working…':progress+'%'}</strong></div><div className={phase==='extracting'?'import-progress indeterminate':'import-progress'}><div style={{width:progress+'%'}}/></div><p className="muted">{current}</p></div>}
  {(phase==='preview'||phase==='saving')&&<div className="stack"><h3>Preview & Edit ({chapters.length} chapters)</h3><p className="muted">Review extracted text carefully. Edit titles/content or remove unwanted chapters before saving.</p>{chapters.map((ch,i)=><article className="work-item" key={i}><div className="row"><strong>Chapter {i+1}</strong><button className="danger" disabled={phase==='saving'} onClick={()=>setChapters(items=>items.filter((_,j)=>j!==i))}>Delete Chapter</button></div><label>Chapter Title<input disabled={phase==='saving'} value={ch.title} onChange={e=>setChapters(items=>items.map((item,j)=>j===i?{...item,title:e.target.value}:item))}/></label><label>Chapter Text<textarea disabled={phase==='saving'} rows={8} value={ch.notes} onChange={e=>setChapters(items=>items.map((item,j)=>j===i?{...item,notes:e.target.value}:item))}/></label></article>)}<button disabled={!chapters.length||phase==='saving'||chapters.some(c=>!c.title.trim()||!c.notes.trim())} onClick={()=>void saveDraft()}>Save Chapters to Subject</button></div>}
  {phase==='saved'&&<p className="muted">Import complete. You can manage chapters and control subject publication above.</p>}
 </section>
}
