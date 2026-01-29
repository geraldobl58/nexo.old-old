<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("confirmLinkIdpTitle")}</h2>
    <#elseif section = "form">
        <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p class="text-sm text-blue-800">
                ${msg("confirmLinkIdpReviewProfile", idpAlias)}
            </p>
        </div>
        <form id="kc-register-form" action="${url.loginAction}" method="post" class="space-y-4">
            <div class="flex gap-3">
                <button 
                    type="submit"
                    name="submitAction"
                    value="updateProfile"
                    class="flex-1 px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("confirmLinkIdpReviewProfile")}
                </button>
                <button 
                    type="submit"
                    name="submitAction"
                    value="linkAccount"
                    class="flex-1 px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("confirmLinkIdpContinue", idpAlias)}
                </button>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>
