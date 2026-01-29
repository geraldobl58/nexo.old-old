<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("termsTitle")}</h2>
    <#elseif section = "form">
        <div id="kc-terms-text" class="prose prose-sm max-w-none mb-6 p-6 bg-gray-50 border border-gray-200 rounded-lg max-h-96 overflow-y-auto">
            ${kcSanitize(msg("termsText"))?no_esc}
        </div>
        <form class="space-y-4" action="${url.loginAction}" method="POST">
            <div class="flex gap-3">
                <button 
                    type="submit" 
                    name="accept"
                    class="flex-1 px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("doAccept")}
                </button>
                <button 
                    type="submit" 
                    name="cancel"
                    class="flex-1 px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("doDecline")}
                </button>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>
