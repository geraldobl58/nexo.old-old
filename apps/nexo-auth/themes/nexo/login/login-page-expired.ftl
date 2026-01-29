<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("pageExpiredTitle")}</h2>
    <#elseif section = "form">
        <div class="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <p class="text-sm text-yellow-800">
                ${msg("pageExpiredMsg1")} <a id="loginRestartLink" href="${url.loginRestartFlowUrl}" class="font-semibold underline">${msg("doClickHere")}</a>.
            </p>
            <p class="text-sm text-yellow-800 mt-2">
                ${msg("pageExpiredMsg2")} <a id="loginContinueLink" href="${url.loginAction}" class="font-semibold underline">${msg("doClickHere")}</a>.
            </p>
        </div>
    </#if>
</@layout.registrationLayout>
