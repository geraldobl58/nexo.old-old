<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("loginX509Title")}</h2>
    <#elseif section = "form">
        <form id="kc-x509-login-info" class="space-y-5" action="${url.loginAction}" method="post">
            <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div class="space-y-2 text-sm text-blue-800">
                    <p><strong>${msg("loginX509CertificateUserLabel")}:</strong> ${x509.username}</p>
                    <#if x509.subjectDN??>
                        <p><strong>${msg("loginX509CertificateSubjectLabel")}:</strong> ${x509.subjectDN}</p>
                    </#if>
                    <#if x509.issuerDN??>
                        <p><strong>${msg("loginX509CertificateIssuerLabel")}:</strong> ${x509.issuerDN}</p>
                    </#if>
                </div>
            </div>
            
            <input type="hidden" id="username" name="username" value="${x509.username}"/>
            
            <button 
                type="submit"
                class="w-full px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
            >
                ${msg("doContinue")}
            </button>
        </form>
    </#if>
</@layout.registrationLayout>
