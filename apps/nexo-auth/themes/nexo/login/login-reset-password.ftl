<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true; section>
    <#if section = "header">
        <div class="mb-6">
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("emailForgotTitle")}</h2>
            <p class="text-sm text-gray-600">${msg("emailInstruction")}</p>
        </div>
    <#elseif section = "form">
        <form id="kc-reset-password-form" class="space-y-5" action="${url.loginAction}" method="post">
            <div>
                <label for="username" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("usernameOrEmail")}
                </label>
                <input 
                    type="text" 
                    id="username" 
                    name="username" 
                    value="${(auth.attemptedUsername!'')}" 
                    autocomplete="username"
                    autofocus
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    placeholder="${msg('usernameOrEmailPlaceholder')}"
                />
            </div>
            
            <div class="space-y-3">
                <button 
                    type="submit"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("doSubmit")}
                </button>
                
                <a 
                    href="${url.loginUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToLogin")}
                </a>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>
