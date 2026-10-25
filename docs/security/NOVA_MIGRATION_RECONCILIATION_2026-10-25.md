# NOVA Toddle — reconciliação do histórico de migrações
Data da verificação: 2026-10-25  
Ambiente: Supabase, consultas apenas de leitura.  
Branch de trabalho: `security/remediation-2026-10`.

## Resultado confirmado
- O Supabase reporta **67 migrações aplicadas**.
- Primeira migração listada: `20260928113052_initial_cambridge_school_core_chat_ai`.
- Última migração listada: `20261019122041_seed_crescer_saude_educational_catalog`.
- A branch `main` não contém a pasta de migrações SQL correspondente. O histórico aplicado existe no Supabase, mas ainda não está reconciliado com a fonte versionada.
- O projeto está reportado como `ACTIVE_HEALTHY`, PostgreSQL 17.6.1; isso não comprova isolamento multi-instituição nem conformidade fiscal.

## Avisos de segurança observados
- O advisor reporta seis tabelas com RLS ativado e sem políticas: `acompanhamentos_rede_educacao`, `contratos_profissionais_nova`, `documentos_candidatura_profissional`, `historico_verificacao_profissional`, `pagamentos_rede_educacao` e `propostas_apoio_educacional`. Isto pode bloquear acesso direto intencionalmente; antes de criar políticas, confirmar grants, consumidores, Edge Functions e modelo de acesso esperado.
- O advisor reporta cinco funções SECURITY DEFINER executáveis por `authenticated`: `fiscal_emitir_documento`, `nova_atualizar_estado_cobranca`, `nova_criar_cobranca`, `nova_registar_pagamento` e `nova_vincular_documento_cobranca`. EXECUTE por utilizadores autenticados não é, por si só, prova de exploração; é necessário validar autorização por função, instituição, aluno, responsável e documento.
- A emissão fiscal deve validar a pertença do aluno e do documento de origem à instituição da sessão e a coerência de `p_criado_por` com a identidade autenticada, após revisão de constraints, triggers e consumidores.
- O bucket público `school-logos` aceita SVG; avaliar risco de conteúdo ativo e compatibilidade com a necessidade real. Preferir PNG/JPEG/WEBP ou sanitização validada se SVG não for requisito.

## Plano seguro de reconciliação
1. Gerar dump de esquema sem dados e preservar checksum, incluindo funções, triggers, views, grants, RLS, constraints, índices e buckets/policies relevantes.
2. Recuperar os 67 scripts originais de migração da origem de desenvolvimento/CI ou backups; não gerar SQL a partir dos nomes.
3. Comparar o estado real com scripts e registar divergências por objeto.
4. Testar a restauração do backup em ambiente isolado; não avançar com um backup não testado.
5. Preparar correções específicas e pequenas numa branch isolada; nenhuma política genérica deve ser criada só para eliminar avisos do advisor.
6. Validar autorização positiva e negativa entre instituições, papéis e dados de alunos; testar emissão, pagamento, recibo, cancelamento/estorno conforme aplicável e rollback.
7. Homologar antes de qualquer alteração de produção.

## Critérios para desbloquear correções
- Migrações originais recuperadas e reconciliadas.
- Backup restaurável verificado.
- Testes RLS multi-tenant e testes de autorização das RPCs aprovados.
- Revisão do acesso aos seis objetos sem políticas e do conteúdo público de logos concluída.
- Plano de rollback e aprovação explícita antes de produção.

## Limite desta etapa
Foram consultados os inventários de migração e os avisos do advisor. Não houve DDL, alteração de políticas, alterações de privilégios, deploy de Edge Functions nem modificação de dados.
