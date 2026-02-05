import { danger, warn, fail } from "danger";

const pr = danger.github.pr;

// PR muito grande
if (pr.additions + pr.deletions > 600) {
  warn("⚠️ PR muito grande. Considere quebrar em partes menores.");
}

// Sem descrição
if (!pr.body || pr.body.length < 30) {
  fail("❌ PR precisa de uma descrição melhor.");
}

// UI change sem screenshot
if (pr.body.includes("UI") && !pr.body.includes("Screenshots")) {
  warn("📸 Mudanças visuais? Adicione screenshots.");
}

// Sem testes
if (!danger.git.modified_files.some((f) => f.includes("test"))) {
  warn("🧪 Nenhum teste foi modificado/adicionado.");
}
