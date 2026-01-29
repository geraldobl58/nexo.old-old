/**
 * Login Flow - Simplificado
 * Loading state + Toggle senha
 */
(function () {
  "use strict";

  // ==========================================
  // 1. ELEMENTOS DO DOM
  // ==========================================
  const form = document.getElementById("kc-form-login");
  const usernameInput = document.getElementById("username");
  const passwordInput = document.getElementById("password");
  const btnLogin = document.getElementById("btn-login");
  const btnLoginText = document.getElementById("btn-login-text");
  const btnLoginSpinner = document.getElementById("btn-login-spinner");
  const togglePasswordBtn = document.getElementById("toggle-password");
  const iconEyeOff = document.getElementById("icon-eye-off");
  const iconEye = document.getElementById("icon-eye");

  // ==========================================
  // 2. TOGGLE SENHA (MOSTRAR/OCULTAR)
  // ==========================================
  if (togglePasswordBtn && passwordInput) {
    togglePasswordBtn.addEventListener("click", function (e) {
      e.preventDefault();

      if (passwordInput.type === "password") {
        passwordInput.type = "text";
        if (iconEyeOff) iconEyeOff.classList.add("hidden");
        if (iconEye) iconEye.classList.remove("hidden");
      } else {
        passwordInput.type = "password";
        if (iconEyeOff) iconEyeOff.classList.remove("hidden");
        if (iconEye) iconEye.classList.add("hidden");
      }

      passwordInput.focus();
    });
  }

  // ==========================================
  // 3. LOADING STATE NO BOTÃO
  // ==========================================
  if (form && btnLogin) {
    form.addEventListener("submit", function (e) {
      // Ativa loading
      btnLogin.disabled = true;
      if (btnLoginText) btnLoginText.textContent = "Entrando...";
      if (btnLoginSpinner) btnLoginSpinner.classList.remove("hidden");

      // O form será submetido normalmente
    });
  }

  // ==========================================
  // 4. VALIDAÇÃO VISUAL SIMPLES
  // ==========================================
  if (usernameInput) {
    usernameInput.addEventListener("blur", function () {
      if (!usernameInput.value.trim()) {
        usernameInput.classList.add("border-red-500", "focus:ring-red-500");
      } else {
        usernameInput.classList.remove("border-red-500", "focus:ring-red-500");
      }
    });
  }

  if (passwordInput) {
    passwordInput.addEventListener("blur", function () {
      if (!passwordInput.value) {
        passwordInput.classList.add("border-red-500", "focus:ring-red-500");
      } else {
        passwordInput.classList.remove("border-red-500", "focus:ring-red-500");
      }
    });
  }
})();
