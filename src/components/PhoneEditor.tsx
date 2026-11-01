import {useState} from 'react';
import {db,type Row} from '../db';
import {translate,type Language} from '../i18n';
export type PhoneTarget={module:'companies'|'contacts'|'candidates';row:Row};
export function PhoneEditor({target,language,onSaved}:{target:PhoneTarget;language:Language;onSaved:()=>void}){
 const t=(key:string)=>translate(language,key),[busy,setBusy]=useState(false),[error,setError]=useState('');
 return <form onSubmit={async e=>{e.preventDefault();if(!db)return;const phone=String(new FormData(e.currentTarget).get('phone')??'').trim();if(phone&&(phone.replace(/\D/g,'').length<3||!/^[+0-9() .#xX-]{3,50}$/.test(phone))){setError(t('Enter a valid phone number.'));return}setBusy(true);setError('');try{const result=await db.from(target.module).update({phone:phone||null}).eq('id',target.row.id).select('id,phone').single();if(result.error){setError(result.error.message);return}onSaved()}catch{setError(t('Could not save. Try again.'))}finally{setBusy(false)}}}><p>{target.row.name}</p><label>{t('Phone number')}<input name="phone" type="tel" inputMode="tel" autoComplete="tel" maxLength={50} defaultValue={String(target.row.phone??'')} autoFocus placeholder="+46 70 123 45 67"/></label><p className="muted">{t('Include the country code for international numbers. Clear the field to remove a number.')}</p>{error&&<div className="error" role="alert">{error}</div>}<button className="gold" disabled={busy}>{busy?t('Saving…'):t('Save phone number')}</button></form>
}
