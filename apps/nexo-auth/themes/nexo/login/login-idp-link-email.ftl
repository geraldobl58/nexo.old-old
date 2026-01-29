<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("emailLinkIdpTitle", idpAlias)}</h2>
    <#elseif section = "form">
        <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p class="text-sm text-blue-800">
                ${msg("emailLinkIdp1", idpAlias, brokerContext.username, realm.displayName)}
            </p>
            <p class="text-sm text-blue-800 mt-2">
                ${msg("emailLinkIdp2")} <a href="${url.loginAction}" class="font-semibold underline">${msg("doClickHere")}</a> ${msg("emailLinkIdp3")}
            </p>
            <p class="text-sm text-blue-800 mt-2">
                ${msg("emailLinkIdp4")} <a href="${url.loginAction}" class="font-semibold underline">${msg("doClickHere")}</a> ${msg("emailLinkIdp5")}
            </p>
        </div>
    </#if>
</@layout.registrationLayout>
