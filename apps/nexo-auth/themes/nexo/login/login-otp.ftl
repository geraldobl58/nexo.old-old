<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('totp'); section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("loginOtpTitle")}</h2>
    <#elseif section = "form">
        <form id="kc-otp-login-form" class="space-y-5" action="${url.loginAction}" method="post">
            <#if otpLogin.userOtpCredentials?size gt 1>
                <div>
                    <label for="selected-credential-id" class="block text-sm font-semibold text-gray-900 mb-2">
                        ${msg("loginChooseAuthenticator")}
                    </label>
                    <select id="selected-credential-id" name="selectedCredentialId"
                            class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200">
                        <#list otpLogin.userOtpCredentials as otpCredential>
                            <option value="${otpCredential.id}" <#if otpCredential.id == otpLogin.selectedCredentialId>selected</#if>>
                                ${otpCredential.userLabel}
                            </option>
                        </#list>
                    </select>
                </div>
            </#if>
            
            <div>
                <label for="otp" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("loginOtpOneTime")}
                </label>
                <input 
                    type="text" 
                    id="otp" 
                    name="otp" 
                    autocomplete="off" 
                    autofocus
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base font-mono text-center text-2xl tracking-widest"
                    aria-invalid="<#if messagesPerField.existsError('totp')>true</#if>"
                    placeholder="${msg('otpPlaceholder')}"
                />
                <#if messagesPerField.existsError('totp')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('totp'))?no_esc}
                    </span>
                </#if>
            </div>
            
            <button 
                type="submit"
                class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
            >
                ${msg("doSubmit")}
            </button>
        </form>
    </#if>
</@layout.registrationLayout>
