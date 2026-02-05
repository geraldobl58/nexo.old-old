# 🤖 AI Code Review - Setup

Configuração completa de review automático com IA usando CodeRabbit e Danger.js.

## 🎯 O que temos

### ✅ CodeRabbit
- Review automático de PRs em PT-BR
- Análise de Clean Architecture no frontend
- Verificação de padrões React/Next.js
- Segurança e performance
- Sugestões de melhorias

### ✅ Danger.js
- Validações automáticas de PR
- Checagem de tamanho de PR
- Verificação de testes
- Análise de dependências
- Detecção de secrets hardcoded
- Resumo detalhado do PR

## 🚀 Setup CodeRabbit

### 1. Instalar CodeRabbit App

Acesse: https://github.com/apps/coderabbitai

1. Clique em **"Install"**
2. Selecione o repositório `nexo`
3. Autorize a aplicação

### 2. Verificar Configuração

O arquivo `.coderabbit.yaml` já está configurado com:

```yaml
language: pt-br  # Reviews em Português
reviews:
  auto_review: true  # Review automático
  
path_instructions:
  # Regras específicas para cada tipo de arquivo
  - apps/nexo-fe/src/**/*.tsx  # Componentes React
  - apps/nexo-be/src/**/*.ts   # Backend NestJS
```

### 3. Testar

Crie um PR de teste e veja o CodeRabbit em ação! 🎉

## 🛠️ Como Funciona

### No Pipeline CI/CD

```yaml
# .github/workflows/pipeline.yml

jobs:
  ai-review:  # Roda APENAS em PRs
    - Checkout código
    - Install Danger.js
    - Run Danger.js review
    - CodeRabbit review (automático)
```

### Fluxo Completo

```
1. Criar PR
   ↓
2. 🤖 AI Review (1-2 min)
   ├─ Danger.js valida PR
   └─ CodeRabbit analisa código
   ↓
3. 📝 Comentários no PR
   ├─ Danger.js: warnings/fails
   └─ CodeRabbit: sugestões linha a linha
   ↓
4. ✅ Fix e push
   ↓
5. 🔄 Re-review automático
```

## 📋 Checklist de Review

### Danger.js verifica:

- [ ] Tamanho do PR (< 1000 linhas)
- [ ] Descrição adequada (> 50 caracteres)
- [ ] Screenshots em mudanças visuais
- [ ] Testes adicionados/modificados
- [ ] Frontend (nexo-fe)
  - [ ] Props tipadas
  - [ ] Server Components quando possível
- [ ] TypeScript
  - [ ] Sem uso de `any`
  - [ ] Sem `@ts-ignore`
- [ ] Dependências
  - [ ] package.json + pnpm-lock.yaml sincronizados
- [ ] Segurança
  - [ ] Sem secrets hardcoded
  - [ ] Sem console.log em produção
- [ ] Performance
  - [ ] Imports específicos (não bibliotecas inteiras)

### CodeRabbit analisa:

- [ ] **Frontend (nexo-fe)**
  - [ ] Server Components vs Client Components
  - [ ] SEO e metadata
  - [ ] Acessibilidade (aria-labels)
  - [ ] Performance (React.memo)
  - [ ] Tailwind CSS
  - [ ] TypeScript tipagem

- [ ] **Backend (nexo-be) - Clean Architecture**
  - [ ] Arquitetura em camadas (Controller → Service → Repository)
  - [ ] Controllers: apenas roteamento e validação
  - [ ] Services: lógica de negócio isolada
  - [ ] DTOs e validação de entrada/saída
  - [ ] Princípios SOLID
  - [ ] Swagger documentation
  - [ ] Tratamento de exceções
  - [ ] Injeção de dependências

## 🎨 Exemplos de Reviews

### Danger.js

```
⚠️ apps/nexo-fe/src/components/UserCard.tsx: 
Props não tipadas. Defina interface ou type para as props.

❌ apps/nexo-be/src/services/auth.service.ts: 
Não use @ts-ignore (2 ocorrências). Resolva os erros de tipo.

✅ Bom uso de Server Components (8 arquivos). 
Continue usando quando possível!
```

### CodeRabbit

```
📝 Sugestão em user.service.ts linha 25:

Siga Clean Architecture - Service não deve acessar repository diretamente.
Use injeção de dependências:

// user.service.ts
@Injectable()
export class UserService {
  constructor(
    private readonly userRepository: UserRepository
  ) {}
  
  async findById(id: string): Promise<UserDto> {
    return this.userRepository.findById(id);
  }
}

Isso segue Clean Architecture com injeção de dependências e separação de camadas.
```

## ⚙️ Configuração Avançada

### Customizar Regras Danger.js

Edite: `apps/nexo-fe/dangerfile.ts`

```typescript
// Adicionar nova regra
if (allFiles.some(f => f.includes('/pages/'))) {
  warn("📁 Usando /pages? Migre para /app (App Router)");
}
```

### Customizar CodeRabbit

Edite: `.coderabbit.yaml`

```yaml
path_instructions:
  - path: "apps/nexo-fe/src/hooks/**/*.ts"
    instructions: |
      Review de hooks customizados:
      - Use prefixo 'use' no nome
      - Retorne valores consistentes
      - Documente com JSDoc
```

## 🔕 Desabilitar Temporariamente

### Danger.js (via commit message)

```bash
git commit -m "fix: corrige bug [skip ci]"
```

### CodeRabbit (via comentário no PR)

```
@coderabbitai pause
```

Para reativar:
```
@coderabbitai resume
```

## 📊 Métricas

### Dashboard CodeRabbit

Acesse: https://app.coderabbit.ai/dashboard

Veja:
- PRs revisados
- Sugestões aceitas
- Tempo médio de review
- Issues detectados

### GitHub Insights

```
Insights → Code → Pull requests
```

Métricas de qualidade:
- Tempo de review
- Comentários por PR
- Taxa de aprovação

## 💡 Boas Práticas

### 1. PRs Pequenos
```
✅ Bom: 100-300 linhas
⚠️ Médio: 300-600 linhas
❌ Grande: 600+ linhas
```

### 2. Descrição Clara
```markdown
## 🎯 Objetivo
Adiciona sistema de notificações em tempo real

## 🔨 Mudanças
- Implementa WebSocket connection
- Adiciona NotificationContext
- Cria componente NotificationBell

## 📸 Screenshots
![Notificação](url)

## ✅ Checklist
- [x] Testes adicionados
- [x] Documentação atualizada
```

### 3. Responder Reviews
```
# Aceitar sugestão
@coderabbitai apply

# Explicar decisão
Mantive this approach porque...

# Pedir esclarecimento
@coderabbitai explain why this is better?
```

### 4. Iterar Rápido
```
1. Criar PR
2. Aguardar reviews (1-2 min)
3. Fazer ajustes
4. Push (re-review automático)
5. Merge quando aprovado
```

## 🆘 Troubleshooting

### CodeRabbit não comenta

1. Verificar instalação:
   - GitHub App instalada?
   - Repositório selecionado?

2. Verificar `.coderabbit.yaml`:
   - Sintaxe correta?
   - `auto_review: true`?

3. Re-trigger review:
   ```
   @coderabbitai review
   ```

### Danger.js falha

1. Ver logs no GitHub Actions:
   ```
   Actions → Pipeline → ai-review
   ```

2. Testar localmente:
   ```bash
   cd apps/nexo-fe
   npm install danger
   npx danger pr https://github.com/geraldobl58/nexo/pull/123
   ```

3. Verificar GITHUB_TOKEN:
   - Automático em PRs
   - Não precisa configurar

### Muitos comentários

1. Ajustar sensibilidade no `.coderabbit.yaml`:
   ```yaml
   reviews:
     request_changes_workflow: false  # Apenas sugestões
   ```

2. Ou pausar temporariamente:
   ```
   @coderabbitai pause
   ```

## 📚 Recursos

- [CodeRabbit Docs](https://docs.coderabbit.ai/)
- [Danger.js Guide](https://danger.systems/js/)
- [Clean Architecture Frontend](https://blog.cleancoder.com/)
- [Next.js Best Practices](https://nextjs.org/docs/app/building-your-application)

## 🎉 Pronto!

Agora seus PRs terão review automático com IA! 🚀

**Próximos passos:**
1. Criar PR de teste
2. Ver CodeRabbit e Danger.js em ação
3. Iterar e melhorar baseado nos feedbacks
4. Compartilhar learnings com o time

---

[← Voltar](../README.md)
