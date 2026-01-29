<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=messagesPerField.exists('global'); section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("loginProfileTitle")}</h2>
        <p class="text-sm text-gray-600">${msg("loginUpdateProfileSubtitle")}</p>
    <#elseif section = "form">
        <form id="kc-update-profile-form" class="space-y-5" action="${url.loginAction}" method="post">
            <div>
                <label for="username" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("username")}
                </label>
                <input 
                    type="text" 
                    id="username" 
                    name="username" 
                    value="${(user.username!'')}" 
                    <#if !realm.registrationEmailAsUsername>readonly</#if>
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base <#if !realm.registrationEmailAsUsername>bg-gray-50</#if>"
                    aria-invalid="<#if messagesPerField.existsError('username')>true</#if>"
                />
                <#if messagesPerField.existsError('username')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('username'))?no_esc}
                    </span>
                </#if>
            </div>

            <div>
                <label for="email" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("email")}
                </label>
                <input 
                    type="text" 
                    id="email" 
                    name="email" 
                    value="${(user.email!'')}" 
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    aria-invalid="<#if messagesPerField.existsError('email')>true</#if>"
                />
                <#if messagesPerField.existsError('email')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('email'))?no_esc}
                    </span>
                </#if>
            </div>

            <div>
                <label for="firstName" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("firstName")}
                </label>
                <input 
                    type="text" 
                    id="firstName" 
                    name="firstName" 
                    value="${(user.firstName!'')}" 
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    aria-invalid="<#if messagesPerField.existsError('firstName')>true</#if>"
                />
                <#if messagesPerField.existsError('firstName')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('firstName'))?no_esc}
                    </span>
                </#if>
            </div>

            <div>
                <label for="lastName" class="block text-sm font-semibold text-gray-900 mb-2">
                    ${msg("lastName")}
                </label>
                <input 
                    type="text" 
                    id="lastName" 
                    name="lastName" 
                    value="${(user.lastName!'')}" 
                    class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                    aria-invalid="<#if messagesPerField.existsError('lastName')>true</#if>"
                />
                <#if messagesPerField.existsError('lastName')>
                    <span class="text-sm text-red-600 mt-1">
                        ${kcSanitize(messagesPerField.get('lastName'))?no_esc}
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
