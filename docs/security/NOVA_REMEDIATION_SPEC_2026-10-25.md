# NOVA Toddle — plano de remediação específico (sem executar em produção)

Data da verificação: 2026-10-25. Fonte: definições atuais obtidas por consulta SQL read-only ao projeto Supabase NOVA Toddle.

## Riscos confirmados no código consultado

1. `fiscal_emitir_documento(...)` é SECURITY DEFINER e verifica papel/instituição do emissor, série pertencente à instituição e tipo/exercício. Contudo, a definição inspecionada insere `p_aluno_id`, `p_documento_origem_id` e `p_criado_por` sem validação explícita visível de que esses IDs pertencem à mesma instituição ou de que `p_criado_por=auth.uid()`. Isso precisa de ser confirmado por constraints/triggers antes de classificar como vulnerabilidade explorável.
2. `nova_atualizar_estado_cobranca(uuid)` verifica autorização depois de selecionar a cobrança; o update é tenant-scoped pelo ID da cobrança carregada e a soma de pagamentos depende de integridade/tenant das relações. Rever associações e constraints.
3. Advisor lista seis tabelas com RLS ativo e sem policies. Isto pode ser um desenho intencional para acesso apenas via service-role/server; não criar policies genéricas sem rever grants, consumidores e requisitos.
4. Funções de cobrança e pagamentos são SECURITY DEFINER; testar autorização por tenant, estados inválidos, duplicação de pagamentos, concorrência e transições de cobrança.

## Alterações propostas — ainda NÃO aplicadas

- Na emissão fiscal, validar que aluno, documento de origem e utilizador criador pertencem à instituição autorizada; preferir `auth.uid()` como criador/auditoria, ou aceitar ID fornecido apenas se validado contra perfil/tenant e regra de negócio.
- Validar cada linha JSON: descrição obrigatória, quantidade > 0, preço/desconto/taxa dentro de limites, desconto não superior à base conforme regra fiscal, formato e número máximo de linhas; rejeitar tipos/casts inválidos com erro controlado.
- Confirmar que `documento_origem_id` pertence à mesma instituição e só permite relações válidas (por exemplo, nota de crédito/debito), sem permitir cross-tenant.
- Rever funções de pagamento para garantir que o pagamento é associado à cobrança e instituição certas, que o valor é positivo, que o estado é permitido, e que idempotência/concorrência impedem duplicação.
- Tabelas RLS sem policy: verificar privilégios de `anon`/`authenticated`, uso por Edge Functions/service role e necessidade real de acesso direto. Manter bloqueio se service-only; documentar essa decisão.
- Não mudar trial de 30 para 14 dias até confirmação da regra comercial atual.

## Testes de aceitação

1. Escola A não emite documentos, consulta alunos, cobranças ou pagamentos da Escola B.
2. Alterar `p_aluno_id`, `p_documento_origem_id` ou `p_criado_por` para UUID de outro tenant é rejeitado.
3. Utilizadores sem papel autorizado não emitem documentos nem alteram pagamentos.
4. Quantidades/valores inválidos, linhas vazias, duplicação e concorrência não produzem documentos/pagamentos inconsistentes.
5. As seis tabelas sem policies permanecem inacessíveis diretamente aos papéis de cliente, caso sejam service-only.
6. Relatórios SAF-T, PDFs, faturas-recibo e histórico de auditoria continuam funcionais.

## Bloqueios antes de uma migration executável

- Confirmar constraints, triggers e todas as chamadas de frontend/Edge Function.
- Reconciliar migrations versionadas no Git com o histórico aplicado em Supabase.
- Preparar ambiente de homologação, dados fictícios de duas escolas e rollback.
- Não aplicar DDL ou alterar permissões em produção neste passo.
