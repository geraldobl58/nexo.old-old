<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        <div class="mb-6 text-center">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
                <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("infoTitle")}</h2>
        </div>
    <#elseif section = "form">
        <div class="space-y-6">
            <#if messageHeader??>
                <div class="mb-4">
                    <h3 class="text-xl font-semibold text-gray-900 text-center">${messageHeader}</h3>
                </div>
            </#if>

            <#if message?has_content>
                <div class="rounded-lg p-4 bg-blue-50 border border-blue-200">
                    <p class="text-sm text-blue-800 text-center">${kcSanitize(message.summary)?no_esc}</p>
                </div>
            </#if>

            <#if requiredActions??>
                <div class="rounded-lg p-4 bg-yellow-50 border border-yellow-200">
                    <p class="text-sm text-yellow-800 mb-3"><strong>${msg("requiredActions.heading")}</strong></p>
                    <ul class="list-disc list-inside space-y-1 text-sm text-yellow-800">
                        <#list requiredActions as reqActionItem>
                            <li>${msg("requiredAction.${reqActionItem}")}</li>
                        </#list>
                    </ul>
                </div>
            </#if>

            <#if skipLink??>
                <!-- Link para pular -->
            <#elseif pageRedirectUri?has_content>
                <a 
                    href="${pageRedirectUri}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToApplication")}
                </a>
            <#elseif actionUri?has_content>
                <a 
                    href="${actionUri}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("proceedWithAction")}
                </a>
            <#elseif client?? && client.baseUrl?has_content>
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
