<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>
    <#if section = "header">
        <div class="mb-6">
            <#-- STEP 1: Identificação -->
            <#if step?? && step == "1">
                <h2 class="text-3xl font-bold text-gray-900 mb-2">Criar sua conta</h2>
                <p class="text-sm text-gray-600 mb-6">Etapa 1 de 2 - Identificação</p>
                
                <!-- Barra de progresso Material UI Style -->
                <div class="relative flex items-start justify-between max-w-md mx-auto mb-6">
                    <!-- Linha conectora de fundo -->
                    <div class="absolute top-5 left-0 right-0 h-0.5 bg-gray-300" style="margin: 0 10%;"></div>
                    
                    <!-- Step 1 - Ativo -->
                    <div class="relative flex flex-col items-center flex-1 z-10">
                        <div class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-semibold text-base shadow-md">
                            1
                        </div>
                        <span class="text-xs font-medium text-gray-900 mt-2 text-center">Dados cadastrais</span>
                    </div>
                    
                    <!-- Step 2 - Inativo -->
                    <div class="relative flex flex-col items-center flex-1 z-10">
                        <div class="w-10 h-10 rounded-full bg-gray-300 text-gray-600 flex items-center justify-center font-semibold text-base shadow-sm">
                            2
                        </div>
                        <span class="text-xs font-medium text-gray-500 mt-2 text-center">Dados de acesso</span>
                    </div>
                </div>
            <#-- STEP 2: Finalização -->
            <#elseif step?? && step == "2">
                <h2 class="text-3xl font-bold text-gray-900 mb-2">Finalize sua conta</h2>
                <p class="text-sm text-gray-600 mb-6">Etapa 2 de 2 - Dados de acesso</p>
                
                <!-- Barra de progresso Material UI Style -->
                <div class="relative flex items-start justify-between max-w-md mx-auto mb-6">
                    <!-- Linha conectora completa azul -->
                    <div class="absolute top-5 left-0 right-0 h-0.5 bg-blue-600" style="margin: 0 10%;"></div>
                    
                    <!-- Step 1 - Completo -->
                    <div class="relative flex flex-col items-center flex-1 z-10">
                        <div class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-semibold text-base shadow-md">
                            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                            </svg>
                        </div>
                        <span class="text-xs font-medium text-gray-600 mt-2 text-center">Dados cadastrais</span>
                    </div>
                    
                    <!-- Step 2 - Ativo -->
                    <div class="relative flex flex-col items-center flex-1 z-10">
                        <div class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-semibold text-base shadow-md">
                            2
                        </div>
                        <span class="text-xs font-medium text-gray-900 mt-2 text-center">Dados de acesso</span>
                    </div>
                </div>
            <#-- Fallback para registro tradicional (sem steps) -->
            <#else>
                <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("registerTitle")}</h2>
                <p class="text-sm text-gray-600">${msg("registerSubtitle")}</p>
            </#if>
        </div>
    <#elseif section = "form">
        <form id="kc-register-form" class="space-y-5" action="${url.registrationAction}" method="post">
            
            <#-- ========================================== -->
            <#-- ETAPA 1: IDENTIFICAÇÃO -->
            <#-- ========================================== -->
            <#if !step?? || step == "1">
            
                <#if !realm.registrationEmailAsUsername>
                    <!-- Nome de usuário (oculto na ETAPA 1 - CPF será usado) -->
                    <input type="hidden" name="username" value="auto-generated" />
                </#if>

                <!-- Nome e Sobrenome -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label for="firstName" class="block text-sm font-semibold text-gray-900 mb-2">
                            ${msg("firstName")} <span class="text-red-500">*</span>
                        </label>
                        <input 
                            type="text" 
                            id="firstName" 
                            name="firstName" 
                            value="${(register.formData.firstName!'')}"
                            class="block w-full px-4 py-3 text-gray-900 border ${messagesPerField.existsError('firstName')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="${msg('firstNamePlaceholder')}"
                            autocomplete="given-name"
                            required
                        />
                        <#if messagesPerField.existsError('firstName')>
                            <span class="text-sm text-red-600 mt-1 block">${kcSanitize(messagesPerField.get('firstName'))?no_esc}</span>
                        </#if>
                    </div>

                    <div>
                        <label for="lastName" class="block text-sm font-semibold text-gray-900 mb-2">
                            ${msg("lastName")} <span class="text-red-500">*</span>
                        </label>
                        <input 
                            type="text" 
                            id="lastName" 
                            name="lastName" 
                            value="${(register.formData.lastName!'')}"
                            class="block w-full px-4 py-3 text-gray-900 border ${messagesPerField.existsError('lastName')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="${msg('lastNamePlaceholder')}"
                            autocomplete="family-name"
                            required
                        />
                        <#if messagesPerField.existsError('lastName')>
                            <span class="text-sm text-red-600 mt-1 block">${kcSanitize(messagesPerField.get('lastName'))?no_esc}</span>
                        </#if>
                    </div>
                </div>

                <!-- CPF e Telefone -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- CPF -->
                    <div>
                        <label for="cpf" class="block text-sm font-semibold text-gray-900 mb-2">
                            CPF <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            id="cpf"
                            name="user.attributes.cpf"
                            value="${(register.formData['user.attributes.cpf']!'')}"
                            class="block w-full px-4 py-3 text-gray-900 border ${messagesPerField.existsError('user.attributes.cpf')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="000.000.000-00"
                            maxlength="14"
                            required
                        />
                        <#if messagesPerField.existsError('user.attributes.cpf')>
                            <span class="text-sm text-red-600 mt-1 block">
                                ${kcSanitize(messagesPerField.get('user.attributes.cpf'))?no_esc}
                            </span>
                        </#if>
                    </div>

                    <!-- Telefone -->
                    <div>
                        <label for="phone" class="block text-sm font-semibold text-gray-900 mb-2">
                            Telefone <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="tel"
                            id="phone"
                            name="user.attributes.phone"
                            value="${(register.formData['user.attributes.phone']!'')}"
                            class="block w-full px-4 py-3 text-gray-900 border ${messagesPerField.existsError('user.attributes.phone')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="(11) 98765-4321 ou (11) 3456-7890"
                            maxlength="15"
                            required
                        />
                        <#if messagesPerField.existsError('user.attributes.phone')>
                            <span class="text-sm text-red-600 mt-1 block">
                                ${kcSanitize(messagesPerField.get('user.attributes.phone'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>

                <!-- Indicador de progresso -->
                <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-2 gap-2
                    ">
                        <span class="text-sm font-medium text-gray-700">Progresso do cadastro</span>
                        <span class="text-sm font-semibold text-primary-600">50%</span>
                    </div>
                    <div class="w-full bg-gray-200 rounded-full h-2">
                        <div class="bg-primary-600 h-2 rounded-full" style="width: 50%"></div>
                    </div>
                    <p class="text-xs text-gray-500 mt-2">Na próxima etapa você definirá email e senha</p>
                </div>

                <!-- Botão: Continuar para ETAPA 2 -->
                <button 
                    type="submit"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    Continuar →
                </button>

                <a 
                    href="${url.loginUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToLogin")}
                </a>

            <#-- ========================================== -->
            <#-- ETAPA 2: FINALIZAÇÃO DA CONTA -->
            <#-- ========================================== -->
            <#elseif step == "2">

                <!-- Informação do usuário -->
                <div class="bg-primary-50 border border-primary-200 rounded-lg p-4">
                    <div class="flex items-start">
                        <svg class="h-5 w-5 text-primary-600 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                        </svg>
                        <div class="ml-3">
                            <p class="text-sm font-medium text-primary-800">
                                Olá, ${firstName!''}!
                            </p>
                            <p class="text-xs text-primary-700 mt-1">
                                Agora precisamos do seu email e senha para finalizar o cadastro
                            </p>
                        </div>
                    </div>
                </div>

                <!-- E-mail -->
                <div>
                    <label for="email" class="block text-sm font-semibold text-gray-900 mb-2">
                        ${msg("email")} <span class="text-red-500">*</span>
                    </label>
                    <input 
                        type="email" 
                        id="email" 
                        name="email" 
                        value="${(register.formData.email!'')}"
                        class="block w-full px-4 py-3 text-gray-900 border ${messagesPerField.existsError('email')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                        placeholder="${msg('emailPlaceholder')}"
                        autocomplete="email"
                        required
                    />
                    <#if messagesPerField.existsError('email')>
                        <span class="text-sm text-red-600 mt-1 block">${kcSanitize(messagesPerField.get('email'))?no_esc}</span>
                    </#if>
                </div>

                <!-- Senha -->
                <div>
                    <label for="password" class="block text-sm font-semibold text-gray-900 mb-2">
                        ${msg("password")} <span class="text-red-500">*</span>
                    </label>
                    <div class="relative">
                        <input 
                            type="password" 
                            id="password" 
                            name="password"
                            class="block w-full px-4 py-3 pr-12 text-gray-900 border ${messagesPerField.existsError('password')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="${msg('passwordPlaceholder')}"
                            autocomplete="new-password"
                            required
                        />
                        <button
                            type="button"
                            onclick="togglePasswordVisibility('password', 'togglePassword')"
                            class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                        >
                            <svg id="togglePassword" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                            </svg>
                        </button>
                    </div>
                    <#if messagesPerField.existsError('password')>
                        <span class="text-sm text-red-600 mt-1 block">${kcSanitize(messagesPerField.get('password'))?no_esc}</span>
                    </#if>
                    <p class="text-xs text-gray-500 mt-1">Mínimo de 8 caracteres</p>
                </div>

                <!-- Confirmação de Senha -->
                <div>
                    <label for="password-confirm" class="block text-sm font-semibold text-gray-900 mb-2">
                        ${msg("passwordConfirm")} <span class="text-red-500">*</span>
                    </label>
                    <div class="relative">
                        <input 
                            type="password" 
                            id="password-confirm" 
                            name="password-confirm"
                            class="block w-full px-4 py-3 pr-12 text-gray-900 border ${messagesPerField.existsError('password-confirm')?then('border-red-500','border-gray-300')} rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                            placeholder="${msg('passwordConfirmPlaceholder')}"
                            autocomplete="new-password"
                            required
                        />
                        <button
                            type="button"
                            onclick="togglePasswordVisibility('password-confirm', 'togglePasswordConfirm')"
                            class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                        >
                            <svg id="togglePasswordConfirm" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                            </svg>
                        </button>
                    </div>
                    <#if messagesPerField.existsError('password-confirm')>
                        <span class="text-sm text-red-600 mt-1 block">${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</span>
                    </#if>
                </div>

                <!-- Indicador de progresso -->
                <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-sm font-medium text-gray-700">Progresso do cadastro</span>
                        <span class="text-sm font-semibold text-green-600">100%</span>
                    </div>
                    <div class="w-full bg-gray-200 rounded-full h-2">
                        <div class="bg-green-600 h-2 rounded-full" style="width: 100%"></div>
                    </div>
                    <p class="text-xs text-gray-500 mt-2">✓ Última etapa - clique em "Criar conta" para finalizar</p>
                </div>

                <!-- Termos e Condições -->
                <div class="space-y-3">
                    <div class="flex items-start">
                        <input 
                            id="termsAccepted" 
                            name="termsAccepted" 
                            type="checkbox" 
                            required
                            class="h-4 w-4 mt-0.5 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                        />
                        <label for="termsAccepted" class="ml-3 text-sm text-gray-700">
                            Li e aceito os <a href="/termos" target="_blank" class="text-primary-600 hover:text-primary-700 font-semibold">Termos de Uso</a> e a <a href="/privacidade" target="_blank" class="text-primary-600 hover:text-primary-700 font-semibold">Política de Privacidade</a> <span class="text-red-500">*</span>
                        </label>
                    </div>
                    
                    <div class="flex items-start">
                        <input 
                            id="newsletter" 
                            name="user.attributes.newsletter" 
                            type="checkbox"
                            class="h-4 w-4 mt-0.5 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                        />
                        <label for="newsletter" class="ml-3 text-sm text-gray-700">
                            Quero receber novidades e ofertas por e-mail
                        </label>
                    </div>
                </div>

                <!-- Botão: Criar conta -->
                <button 
                    type="submit"
                    style="background-color: #16a34a !important;"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-green-600 rounded-lg shadow-sm hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200"
                    onmouseover="this.style.backgroundColor='#15803d'"
                    onmouseout="this.style.backgroundColor='#16a34a'"
                >
                    ✓ Criar conta
                </button>
                
                <!-- Botão: Voltar para login -->
                <a 
                    href="${url.loginUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ← Voltar para o login
                </a>

            </#if>
            
            <#-- Captcha (se configurado) -->
            <#if recaptchaRequired??>
                <div class="g-recaptcha" data-size="compact" data-sitekey="${recaptchaSiteKey}"></div>
            </#if>
        </form>

        <#-- Script de máscaras (aplicado apenas na ETAPA 1) -->
        <#if !step?? || step == "1">
            <script>
                document.addEventListener("DOMContentLoaded", () => {
                    const cpf = document.getElementById("cpf");
                    const phone = document.getElementById("phone");

                    cpf?.addEventListener("input", () => {
                        cpf.value = cpf.value
                            .replace(/\D/g, "")
                            .replace(/(\d{3})(\d)/, "$1.$2")
                            .replace(/(\d{3})(\d)/, "$1.$2")
                            .replace(/(\d{3})(\d{1,2})$/, "$1-$2");
                    });

                    phone?.addEventListener("input", () => {
                        let value = phone.value.replace(/\D/g, "");
                        
                        if (value.length <= 10) {
                            // Telefone fixo: (11) 3456-7890
                            value = value.replace(/(\d{2})(\d)/, "($1) $2");
                            value = value.replace(/(\d{4})(\d)/, "$1-$2");
                        } else {
                            // Celular: (11) 98765-4321
                            value = value.replace(/(\d{2})(\d)/, "($1) $2");
                            value = value.replace(/(\d{5})(\d)/, "$1-$2");
                        }
                        
                        phone.value = value;
                    });
                });
            </script>
        </#if>
        
        <#-- Script para toggle de senha (ETAPA 2) -->
        <#if step?? && step == "2">
            <script>
                function togglePasswordVisibility(inputId, iconId) {
                    const input = document.getElementById(inputId);
                    const icon = document.getElementById(iconId);
                    
                    if (input.type === 'password') {
                        input.type = 'text';
                        // Ícone de olho cortado (senha visível)
                        icon.innerHTML = `
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/>
                        `;
                    } else {
                        input.type = 'password';
                        // Ícone de olho aberto (senha oculta)
                        icon.innerHTML = `
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                        `;
                    }
                }
            </script>
        </#if>
    </#if>
</@layout.registrationLayout>
