<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true; section>
    <#if section = "header">
        <div class="mb-6 text-center">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
                <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
            </div>
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("emailVerifyTitle")}</h2>
            <p class="text-sm text-gray-600">${msg("emailVerifyInstruction1")}</p>
        </div>
    <#elseif section = "form">
        <div class="space-y-6">
            <div class="rounded-lg p-4 bg-blue-50 border border-blue-200">
                <p class="text-sm text-blue-800 text-center">
                    ${msg("emailVerifyInstruction2")}
                    <br/>
                    <strong class="font-semibold">${user.email}</strong>
                </p>
            </div>

            <form id="kc-verify-email-form" action="${url.loginAction}" method="post" class="space-y-3">
                <button 
                    type="submit"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("doClickHere")} ${msg("emailVerifyInstruction3")}
                </button>

                <a 
                    href="${url.loginUrl}"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("backToLogin")}
                </a>
            </form>
        </div>
    </#if>
</@layout.registrationLayout>
