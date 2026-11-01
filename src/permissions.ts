export const modules = ['companies','contacts','opportunities','meetings','projects','candidates','tasks','reports'] as const;
export type Module = typeof modules[number];
export type Scope = 'none'|'view_assigned'|'edit_assigned'|'view_team'|'edit_team'|'full';
export type Role = 'admin'|'appointment_setter'|'sales'|'talent_broker';
export type Profile = {user_id:string;display_name:string;role:Role;active:boolean;team_id:string|null};
export type Permission = {module:Module;scope:Scope};
export const defaults:Record<Role,Partial<Record<Module,Scope>>> = {
 admin:Object.fromEntries(modules.map(m=>[m,'full'])),
 appointment_setter:{companies:'edit_assigned',contacts:'edit_assigned',opportunities:'edit_assigned',meetings:'edit_assigned',tasks:'edit_assigned'},
 sales:{companies:'edit_assigned',contacts:'edit_assigned',opportunities:'edit_assigned',meetings:'edit_assigned',projects:'view_assigned',tasks:'edit_assigned',reports:'view_assigned'},
 talent_broker:{companies:'view_assigned',contacts:'view_assigned',projects:'edit_assigned',candidates:'edit_assigned',meetings:'edit_assigned',tasks:'edit_assigned'}
};
export function scopeFor(profile:Profile|null,overrides:Permission[],module:Module):Scope {if(!profile?.active)return 'none';return overrides.find(p=>p.module===module)?.scope??defaults[profile.role][module]??'none'}
export function editable(scope:Scope){return ['edit_assigned','edit_team','full'].includes(scope)}
