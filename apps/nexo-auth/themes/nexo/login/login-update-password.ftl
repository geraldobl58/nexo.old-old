<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true; section>
    <#if section = "header">
        <div class="mb-6">
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("updatePasswordTitle")}</h2>
            <p class="text-sm text-gray-600">${msg("updatePasswordSubtitle")}</p>
        </div>
    <#elseif section = "form">
        <form id="kc-passwd-update-form" class="space-y-5" action="${url.loginAction}" method="post">
            <input type="text" id="username" name="username" value="${username}" autocomplete="username" readonly="readonly" style="display:none;"/>
            <input type="password" id="password" name="password" autocomplete="current-password" style="display:none;"/>

            <#if message?has_content && message.type != 'error'>
                <div class="rounded-lg p-4 bg-blue-50 border border-blue-200">
                    <p class="text-sm text-blue-800">${kcSanitize(message.summary)?no_esc}</p>
                </div>
            </#if>

            <div>
                <label for="password-new" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("passwordNew")}
                </label>
                <input 
                    type="password" 
                    id="password-new" 
                    name="password-new"
                    autofocus
                    autocomplete="new-password"
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    placeholder="${msg('passwordNewPlaceholder')}"
                />
            </div>

            <div>
                <label for="password-confirm" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("passwordConfirm")}
                </label>
                <input 
                    type="password" 
                    id="password-confirm" 
                    name="password-confirm"
                    autocomplete="new-password"
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    placeholder="${msg('passwordConfirmPlaceholder')}"
                />
            </div>

            <div class="space-y-3">
                <button 
                    type="submit"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                >
                    ${msg("doSubmit")}
                </button>

                <#if isAppInitiatedAction??>
                    <button 
                        type="submit" 
                        name="cancel-aia" 
                        value="true"
                        class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200"
                    >
                        ${msg("doCancel")}
                    </button>
                </#if>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>
