import { danger, warn, fail, message, markdown } from "danger";

const pr = danger.github.pr;
const modifiedFiles = danger.git.modified_files;
const createdFiles = danger.git.created_files;
const deletedFiles = danger.git.deleted_files;
const allFiles = [...modifiedFiles, ...createdFiles];

// Função async principal para permitir uso de await
async function runChecks() {
  // ============================================================================
  // 1. TAMANHO DO PR
  // ============================================================================
  const totalChanges = pr.additions + pr.deletions;

  if (totalChanges > 1000) {
    fail(
      "❌ PR muito grande (1000+ linhas). Divida em PRs menores para facilitar review.",
    );
  } else if (totalChanges > 600) {
    warn("⚠️ PR grande (600+ linhas). Considere quebrar em partes menores.");
  } else if (totalChanges > 300) {
    message(
      "📊 PR médio (300+ linhas). Pode ser revisado, mas menor seria melhor.",
    );
  }

  // ============================================================================
  // 2. DESCRIÇÃO DO PR
  // ============================================================================
  if (!pr.body || pr.body.length < 50) {
    fail(
      `❌ PR precisa de uma descrição detalhada (mínimo 50 caracteres, atual: ${pr.body?.length || 0})`,
    );
  }

  // Checklist de mudanças visuais
  if (pr.body?.includes("UI") || pr.body?.includes("visual")) {
    if (!pr.body.includes("screenshot") && !pr.body.includes("![")) {
      warn(
        "📸 Mudanças visuais detectadas. Adicione screenshots ou GIF para facilitar review.",
      );
    }
  }

  // ============================================================================
  // 3. FRONTEND - NEXT.JS
  // ============================================================================
  const frontendFiles = allFiles.filter((f) => f.startsWith("apps/nexo-fe/"));

  if (frontendFiles.length > 0) {
    // 3.1 - Props tipadas
    const componentFiles = frontendFiles.filter(
      (f) => f.includes("/components/") && f.endsWith(".tsx"),
    );

    for (const file of componentFiles) {
      const diff = await danger.git.diffForFile(file);
      const content = diff?.diff || "";

      // Props sem tipos
      if (
        content.includes("props:") &&
        !content.includes("interface") &&
        !content.includes("type Props")
      ) {
        warn(
          `⚠️ \`${file}\`: Props não tipadas. Defina interface ou type para as props.`,
        );
      }
    }

    // 3.2 - Server Components (processar de forma assíncrona)
    let serverComponentsCount = 0;
    for (const file of frontendFiles) {
      const diff = await danger.git.diffForFile(file);
      if (diff && !diff.diff.includes("'use client'")) {
        serverComponentsCount++;
      }
    }

    if (
      serverComponentsCount > 0 &&
      frontendFiles.some((f) => f.includes("/app/"))
    ) {
      message(
        `✅ Bom uso de Server Components (${serverComponentsCount} arquivos). Continue usando quando possível!`,
      );
    }
  }

  // ============================================================================
  // 4. TESTES
  // ============================================================================
  const hasTestChanges = allFiles.some(
    (f) =>
      f.includes(".test.") || f.includes(".spec.") || f.includes("__tests__"),
  );

  const hasSourceChanges = allFiles.some(
    (f) =>
      (f.endsWith(".ts") ||
        f.endsWith(".tsx") ||
        f.endsWith(".js") ||
        f.endsWith(".jsx")) &&
      !f.includes(".test.") &&
      !f.includes(".spec.") &&
      !f.includes("__tests__"),
  );

  if (hasSourceChanges && !hasTestChanges) {
    warn(
      "🧪 Nenhum teste foi modificado/adicionado. Considere adicionar testes para as mudanças.",
    );
  }

  // ============================================================================
  // 5. DEPENDÊNCIAS
  // ============================================================================
  const packageJsonChanged = modifiedFiles.some((f) =>
    f.includes("package.json"),
  );
  const lockFileChanged = modifiedFiles.some((f) =>
    f.includes("pnpm-lock.yaml"),
  );

  if (packageJsonChanged && !lockFileChanged) {
    fail(
      "❌ package.json foi alterado mas pnpm-lock.yaml não. Execute `pnpm install`.",
    );
  }

  if (lockFileChanged && !packageJsonChanged) {
    warn(
      "⚠️ pnpm-lock.yaml foi alterado mas package.json não. Verifique se está correto.",
    );
  }

  // ============================================================================
  // 6. TYPESCRIPT
  // ============================================================================
  const tsFiles = allFiles.filter(
    (f) => f.endsWith(".ts") || f.endsWith(".tsx"),
  );

  if (tsFiles.length > 0) {
    message(`📘 ${tsFiles.length} arquivo(s) TypeScript alterado(s).`);

    // Verificar uso de 'any'
    for (const file of tsFiles) {
      const diff = await danger.git.diffForFile(file);
      const content = diff?.diff || "";

      const anyCount = (content.match(/: any/g) || []).length;
      if (anyCount > 0) {
        warn(
          `⚠️ \`${file}\`: Evite usar \`any\` (${anyCount} ocorrências). Use tipos específicos.`,
        );
      }

      // @ts-ignore
      const tsIgnoreCount = (content.match(/@ts-ignore/g) || []).length;
      if (tsIgnoreCount > 0) {
        fail(
          `❌ \`${file}\`: Não use \`@ts-ignore\` (${tsIgnoreCount} ocorrências). Resolva os erros de tipo.`,
        );
      }
    }
  }

  // ============================================================================
  // 7. ESTILIZAÇÃO
  // ============================================================================
  const hasStyleFiles = allFiles.some(
    (f) => f.endsWith(".css") || f.endsWith(".scss"),
  );

  if (hasStyleFiles && frontendFiles.length > 0) {
    message(
      "💅 Arquivos de estilo modificados. Verifique se está usando Tailwind CSS como padrão.",
    );
  }

  // ============================================================================
  // 8. PERFORMANCE - IMPORTS
  // ============================================================================
  for (const file of frontendFiles) {
    const diff = await danger.git.diffForFile(file);
    const content = diff?.diff || "";

    // Importar biblioteca inteira ao invés de módulos específicos
    if (
      content.includes('import _ from "lodash"') ||
      content.includes("import * as _ from 'lodash'")
    ) {
      warn(
        `⚠️ \`${file}\`: Importe funções específicas do lodash: \`import { map } from 'lodash'\``,
      );
    }
  }

  // ============================================================================
  // 9. SEGURANÇA
  // ============================================================================
  for (const file of allFiles) {
    const diff = await danger.git.diffForFile(file);
    const content = diff?.diff || "";

    // Tokens ou secrets hardcoded
    if (
      content.match(/api[_-]?key/i) ||
      content.match(/secret/i) ||
      content.match(/password/i) ||
      content.match(/token/i)
    ) {
      if (content.match(/['"`]\w{20,}['"`]/)) {
        fail(
          `🔒 \`${file}\`: Possível secret hardcoded detectado. Use variáveis de ambiente.`,
        );
      }
    }

    // console.log em produção
    if (content.includes("console.log") || content.includes("console.error")) {
      warn(
        `⚠️ \`${file}\`: \`console.log\` detectado. Remova ou use logger apropriado.`,
      );
    }
  }

  // ============================================================================
  // 10. SUMMARY
  // ============================================================================
  markdown(`
## 📊 Resumo do PR

- **Arquivos alterados:** ${modifiedFiles.length}
- **Arquivos criados:** ${createdFiles.length}
- **Arquivos deletados:** ${deletedFiles.length}
- **Linhas adicionadas:** +${pr.additions}
- **Linhas removidas:** -${pr.deletions}
- **Total de mudanças:** ${totalChanges} linhas

### 📁 Arquivos por categoria:
${frontendFiles.length > 0 ? `- 🎨 Frontend: ${frontendFiles.length}` : ""}
${allFiles.filter((f) => f.startsWith("apps/nexo-be/")).length > 0 ? `- ⚙️ Backend: ${allFiles.filter((f) => f.startsWith("apps/nexo-be/")).length}` : ""}
${tsFiles.length > 0 ? `- 📘 TypeScript: ${tsFiles.length}` : ""}
${hasTestChanges ? `- 🧪 Testes: Sim ✅` : `- 🧪 Testes: Não ⚠️`}
`);
}

// Executar as verificações
runChecks();
