# NOVA Toddle — homologação tenant/fiscal e reconciliação de migrations

## Resultado da inspeção adicional (2026-10-25)

- Supabase reporta histórico de migrations aplicado.
- A árvore `main` do repositório `NOVAKZ` contém apenas 5 caminhos e não apresenta diretório `supabase/migrations` nem SQL versionado de migrations. Não é seguro fabricar uma migration sem recuperar a fonte histórica.
- As tabelas `acompanhamentos_rede_educacao`, `contratos_profissionais_nova`, `documentos_candidatura_profissional`, `historico_verificacao_profissional`, `pagamentos_rede_educacao` e `propostas_apoio_educacional` têm RLS ligado e nenhuma policy.
- Outras tabelas relevantes têm policies tenant-aware, incluindo `alunos`, `cobrancas_escolares`, `pagamentos_escolares`, `documentos_fiscais`, `documentos_fiscais_linhas`, `perfis` e `series_fiscais`.
- As seis tabelas sem policies podem estar deliberadamente reservadas ao servidor. Não criar policies genéricas; confirmar grants e consumidores.

## Revisão obrigatória antes de alterar RPC fiscal

A função `fiscal_emitir_documento` verifica o papel e a instituição do emissor e valida que a série fiscal pertence à instituição. Na definição inspecionada, `p_aluno_id`, `p_documento_origem_id` e `p_criado_por` são usados na inserção sem validação explícita de tenant/identidade visível no corpo. Confirmar constraints e triggers; se não existir proteção equivalente, preparar validações dentro da função.

## Gate de segurança — não avançar diretamente para DDL

1. Exportar/reconstruir SQL histórico das migrations aplicadas e comparar com o repositório.
2. Inspecionar constraints e triggers sobre alunos, perfis, documentos fiscais, linhas e origem fiscal.
3. Identificar chamadas RPC de frontend e Edge Functions.
4. Criar dados fictícios de Escola A e Escola B em homologação.
5. Validar rollback, SAF-T, PDF, fatura-recibo e auditoria antes de qualquer produção.

## Matriz mínima de testes

| Caso | Resultado esperado |
|---|---|
| utilizador Escola A emite documento com aluno da Escola B | Rejeitado |
| utilizador Escola A indica documento de origem da Escola B | Rejeitado |
| utilizador tenta definir `p_criado_por` como outro perfil | Ignorado ou rejeitado conforme regra documentada |
| papel não autorizado emite documento | Rejeitado |
| linha com quantidade/preço/desconto/taxa inválidos | Rejeitada com erro controlado |
| pagamentos duplicados ou concorrentes | Sem duplicação ou estado inconsistente |
| cliente anon/authenticated consulta tabela server-only | Negado |
| Escola A consulta cobrança/documento da Escola B | Sem acesso |
| SAF-T, PDF, fatura-recibo e auditoria | Sem regressões |

## Estado

Este documento regista evidências de catálogo e o plano de homologação. Não contém migration executável e não alterou o projeto Supabase.
