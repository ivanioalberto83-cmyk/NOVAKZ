# Evidências e plano de testes de segurança — NOVA Toddle
Data: 2026-10-25
Branch: security/remediation-2026-10
Estado: auditoria read-only; sem alterações à base de dados.

## Evidências consultadas no Supabase
- Advisor sinaliza RLS ativo sem políticas em: `acompanhamentos_rede_educacao`, `contratos_profissionais_nova`, `documentos_candidatura_profissional`, `historico_verificacao_profissional`, `pagamentos_rede_educacao`, `propostas_apoio_educacional`. Não presumir que sejam falhas: confirmar privilégios e consumidores; tabelas sem policy negam acesso via roles sujeitas a RLS, mas service role pode ignorá-lo.
- Cinco RPCs financeiras são SECURITY DEFINER e executáveis por authenticated: `fiscal_emitir_documento`, `nova_atualizar_estado_cobranca`, `nova_criar_cobranca`, `nova_registar_pagamento`, `nova_vincular_documento_cobranca`.
- `fiscal_emitir_documento` verifica papel e instituição, verifica a série fiscal por instituição e tipo e cria auditoria. Ainda é necessário confirmar vínculos de `p_aluno_id`, `p_documento_origem_id` e `p_criado_por` com a instituição e utilizador efetivo, bem como validação de valores das linhas.
- Edge Function `registar-instituicao-trial` está ativa com `verify_jwt=true`; usa service role após validar sessão. A duração do trial (30 dias no código previamente inspecionado) diverge da especificação de 14 dias; não alterar até confirmar regra de negócio.
- Bucket `school-logos` permite SVG; avaliar risco de conteúdo ativo e restringir a formatos raster ou sanitizar no servidor.

## Alterações a preparar (não executar nesta fase)
1. Tabelas sem policies: determinar se são exclusivamente backend/service-role. Se sim, documentar e confirmar ausência de GRANT indevido; se usadas por cliente, criar políticas mínimas por instituição e papel, com testes de isolamento.
2. RPCs financeiras: validar auth.uid(), papel, instituição, aluno/responsável/cobrança/documento e autoria no servidor. Nunca confiar em `p_criado_por` recebido do cliente.
3. Pagamentos: impedir duplicação, associação de pagamento entre instituições e alteração de estados sem autorização; preservar integridade contabilística e trilho de auditoria.
4. Storage: testar acesso anon, acesso entre tenants, papéis permitidos e expiração de URL assinada; reduzir permissões para documentos fiscais ao mínimo necessário.
5. Trial: decidir explicitamente 14 ou 30 dias antes de alterar.

## Testes de aceitação obrigatórios
- Criar escolas fictícias A e B; utilizador A não consegue consultar, emitir, pagar, exportar ou descarregar registos de B.
- Anon não acede a tabelas privadas nem a documentos fiscais.
- Aluno, responsável, cobrança, série, documento de origem e utilizador criador pertencem à instituição autorizada.
- Testar repetição de pagamentos, duplicados, concorrência de emissão e rollback.
- Testar PDFs, SAF-T, exportações, links assinados, trial repetido e falhas parciais.
- Backup não vazio, checksum e restauro em homologação antes de migração.

## Bloqueio atual
O repositório NOVAKZ consultado não contém diretório de migrations nem código de Edge Functions versionado na raiz. Não criar uma migration operacional sem fonte versionada clara e sem revisão dos consumidores. Nenhuma alteração de produção foi executada.
