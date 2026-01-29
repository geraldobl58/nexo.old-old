<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('totp','userLabel'); section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("loginTotpTitle")}</h2>
        <p class="text-sm text-gray-600">${msg("loginTotpStep1")}</p>
    <#elseif section = "form">
        <ol class="space-y-6 mb-6">
            <li class="flex gap-4">
                <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-primary-100 text-primary-600 font-semibold">1</span>
                <div class="flex-1">
                    <p class="text-sm text-gray-700 mb-3">${msg("loginTotpStep1")}</p>
                    <ul class="space-y-2 text-sm text-gray-600">
                        <#list totp.supportedApplications as app>
                            <li class="flex items-center gap-2">
                                <svg class="w-4 h-4 text-primary-500" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                                </svg>
                                ${app}
                            </li>
                        </#list>
                    </ul>
                </div>
            </li>

            <li class="flex gap-4">
                <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-primary-100 text-primary-600 font-semibold">2</span>
                <div class="flex-1">
                    <p class="text-sm text-gray-700 mb-3">${msg("loginTotpStep2")}</p>
                    <div class="bg-white border-2 border-gray-200 rounded-lg p-4 inline-block">
                        <img src="data:image/png;base64,${totp.totpSecretQrCode}" alt="QR Code" class="w-48 h-48" />
                    </div>
                    <div class="mt-3 p-3 bg-gray-50 rounded-lg border border-gray-200">
                        <p class="text-xs text-gray-500 mb-1">${msg("loginTotpManualStep2")}</p>
                        <code class="text-sm font-mono text-gray-900 break-all">${totp.totpSecretEncoded}</code>
                    </div>
                </div>
            </li>

            <li class="flex gap-4">
                <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-primary-100 text-primary-600 font-semibold">3</span>
                <div class="flex-1">
                    <p class="text-sm text-gray-700">${msg("loginTotpStep3")}</p>
                </div>
            </li>
        </ol>

        <form action="${url.loginAction}" method="post" class="space-y-5">
            <div>
                <label for="totp" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("authenticatorCode")}
                </label>
                <input 
                    type="text" 
                    id="totp" 
                    name="totp" 
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

            <div>
                <label for="userLabel" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("loginTotpDeviceName")}
                </label>
                <input 
                    type="text" 
                    id="userLabel" 
                    name="userLabel" 
                    autocomplete="off"
                    value="${totp.otpCredentialLabel!}"
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    placeholder="${msg('totpDeviceNamePlaceholder')}"
                    aria-invalid="<#if messagesPerField.existsError('userLabel')>true</#if>"
                />
                <#if messagesPerField.existsError('userLabel')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('userLabel'))?no_esc}
                    </span>
                </#if>
            </div>

            <input type="hidden" id="totpSecret" name="totpSecret" value="${totp.totpSecret}" />
            <#if mode??><input type="hidden" id="mode" name="mode" value="${mode}"/></#if>

            <button 
                type="submit"
                class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
            >
                ${msg("doSubmit")}
            </button>
        </form>
    </#if>
</@layout.registrationLayout>
