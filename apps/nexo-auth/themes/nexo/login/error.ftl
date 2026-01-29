<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        <div class="mb-6 text-center">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-red-100 rounded-full mb-4">
                <svg class="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
            </div>
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("errorTitle")}</h2>
        </div>
    <#elseif section = "form">
        <div class="space-y-6">
            <#if message?has_content>
                <div class="rounded-lg p-4 bg-red-50 border border-red-200">
                    <p class="text-sm text-red-800 text-center">${kcSanitize(message.summary)?no_esc}</p>
                </div>
            <#else>
                <div class="rounded-lg p-4 bg-red-50 border border-red-200">
                    <p class="text-sm text-red-800 text-center">${msg("errorGeneric")}</p>
                </div>
            </#if>

            <#if client?? && client.baseUrl?has_content>
                <a 
                    href="${client.baseUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToApplication")}
                </a>
            <#else>
                <a 
                    href="${url.loginUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToLogin")}
                </a>
            </#if>
        </div>
    </#if>
</@layout.registrationLayout>
