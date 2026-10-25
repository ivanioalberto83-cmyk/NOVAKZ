-- NOVA Toddle security audit (READ ONLY)
-- Run in Supabase SQL Editor with an administrative role.
-- This script only SELECTs catalog metadata; it does not change data, grants, policies, or functions.
begin read only;

-- 1. SECURITY DEFINER RPC attributes and EXECUTE grants
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as identity_arguments,
       p.prosecdef as security_definer, p.proconfig as function_config,
       r.rolname as grantee, a.privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
cross join lateral aclexplode(coalesce(p.proacl, acldefault('f',p.proowner))) a
join pg_roles r on r.oid = a.grantee
where n.nspname = 'public'
  and p.proname in ('fiscal_emitir_documento','nova_atualizar_estado_cobranca',
                    'nova_criar_cobranca','nova_registar_pagamento',
                    'nova_vincular_documento_cobranca')
order by p.proname, r.rolname;

-- 2. RLS and policy state for the tables previously flagged by advisors
select n.nspname as schema_name, c.relname as table_name,
       c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced,
       pol.polname as policy_name, pol.polcmd as command,
       pol.polroles, pol.polqual, pol.polwithcheck
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policy pol on pol.polrelid = c.oid
where n.nspname = 'public'
  and c.relkind in ('r','p')
  and c.relname in ('acompanhamentos_rede_educacao',
                    'contratos_profissionais_nova',
                    'documentos_candidatura_profissional',
                    'historico_verificacao_profissional',
                    'pagamentos_rede_educacao',
                    'propostas_apoio_educacional',
                    'perfis','alunos','documentos_fiscais',
                    'cobrancas_escolares','pagamentos_escolares',
                    'series_fiscais')
order by c.relname, pol.polname;

-- 3. Check declared foreign keys for tenant-sensitive references before changing RPCs
select con.conname as constraint_name,
       conrelid::regclass as table_name,
       confrelid::regclass as referenced_table,
       pg_get_constraintdef(oid) as definition
from pg_constraint
where contype = 'f'
  and (conrelid::regclass::text in ('public.documentos_fiscais',
                                   'public.documentos_fiscais_linhas',
                                   'public.cobrancas_escolares',
                                   'public.pagamentos_escolares')
       or confrelid::regclass::text in ('public.alunos','public.perfis',
                                       'public.cobrancas_escolares',
                                       'public.documentos_fiscais'))
order by table_name::text, constraint_name;

-- 4. Grants for flagged tables to client roles
select table_schema, table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon','authenticated')
  and table_name in ('acompanhamentos_rede_educacao',
                     'contratos_profissionais_nova',
                     'documentos_candidatura_profissional',
                     'historico_verificacao_profissional',
                     'pagamentos_rede_educacao',
                     'propostas_apoio_educacional',
                     'documentos_fiscais','cobrancas_escolares',
                     'pagamentos_escolares','alunos')
order by table_name, grantee, privilege_type;

rollback;
