# Plano de remediação de segurança — NOVA Toddle
Data: 2026-10-25
Estado: preparação em branch; nenhuma alteração na produção.

## Objetivo
Validar isolamento multi-instituição e acessos a dados escolares, financeiros e documentais antes de qualquer mudança em produção.

## Findings prioritários
1. O advisor identificou RLS ativo sem políticas nas tabelas `acompanhamentos_rede_educacao`, `contratos_profissionais_nova`, `documentos_candidatura_profissional`, `historico_verificacao_profissional`, `pagamentos_rede_educacao` e `propostas_apoio_educacional`. Determinar se são deliberadamente service-role-only ou se falta política. Não criar políticas genéricas; testar privilégios SQL/API e consumidores legítimos.
2. Rever funções SECURITY DEFINER `fiscal_emitir_documento`, `nova_atualizar_estado_cobranca`, `nova_criar_cobranca`, `nova_registar_pagamento` e `nova_vincular_documento_cobranca`: validar identidade, papel, instituição efetiva e vínculos de aluno/cobrança/documento.
3. Testar `saft-gerar`, `gerar-documento-pdf`, `exportar-dados` e `registar-instituicao-trial` com dois tenants fictícios; verificar exportações, documentos, elevação de papel e criação repetida de instituições.
4. Storage: rever acessos, duração de URLs assinadas e papéis permitidos para documentos fiscais. Avaliar restringir SVG público em `school-logos` ou sanitizá-lo.
5. Planear ativação e teste da proteção contra palavras-passe comprometidas após avaliar impacto.

## Testes obrigatórios
- Criar Tenant A e Tenant B com dados fictícios.
- Testar acesso direto como anon e utilizador autenticado às seis tabelas.
- Como admin da Escola A, tentar consultar/exportar/emitir/associar/descarregar dados da Escola B: tudo deve falhar sem revelar dados.
- Validar pagamentos e vínculos fiscais no servidor.
- Testar criação trial repetida, upsert de perfil, falha parcial e rollback.
- Testar documentos fiscais/SAF-T e links assinados com diferentes papéis.
- Restaurar backup em homologação e executar regressão.

## Divergência de configuração
A função `registar-instituicao-trial` define 30 dias, enquanto a especificação anteriormente registada prevê 14 dias. Confirmar a regra pretendida antes de alterar código ou dados.

## Sequência segura
1. Rever migrations, políticas e consumidores.
2. Preparar alterações mínimas e reversíveis nesta branch.
3. Executar testes com tenants fictícios em homologação.
4. Rever diff e criar PR.
5. Não fazer merge/deploy sem aprovação explícita, backup verificado e rollback documentado.

## Restrições
- Não aplicar DDL, policies, grants, alterações Auth ou deploy de Edge Functions em produção nesta fase.
- Não usar dados pessoais reais nos testes.
- Não declarar segurança completa sem testes de acesso e regressão.
