<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=social.displayInfo displayWide=(realm.password && social.providers??); section>
    <#if section = "header">
        <div class="mb-6">
            <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("loginAccountTitle")}</h2>
            <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
                <p class="text-sm text-gray-600">
                    ${msg("noAccount")} 
                    <a href="${url.registrationUrl}" class="font-semibold text-primary-600 hover:text-primary-700 transition-colors duration-200">
                        ${msg("doRegister")}
                    </a>
                </p>
            </#if>
        </div>
    <#elseif section = "form">
        <#if realm.password>
            <form id="kc-form-login" class="space-y-5" action="${url.loginAction}" method="post">
                <div>
                    <label for="username" class="block text-sm font-semibold text-gray-900 mb-2">
                        <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                    </label>
                    <input 
                        type="text" 
                        id="username" 
                        name="username" 
                        value="${(login.username!'')}" 
                        autocomplete="username"
                        required
                        autofocus
                        class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base"
                        placeholder="${msg('usernameOrEmailPlaceholder')}"
                        aria-invalid="<#if messagesPerField.existsError('username')>true</#if>"
                    />
                    <#if messagesPerField.existsError('username')>
                        <span class="text-sm text-red-600 mt-1 block">
                            ${kcSanitize(messagesPerField.get('username'))?no_esc}
                        </span>
                    </#if>
                </div>
                
                <div>
                    <label for="password" class="block text-sm font-semibold text-gray-900 mb-2">
                        ${msg("password")}
                    </label>
                    <div class="relative">
                        <input 
                            type="password" 
                            id="password" 
                            name="password" 
                            autocomplete="current-password"
                            required
                            class="block w-full px-4 py-3 text-gray-900 border border-gray-300 rounded-lg shadow-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all duration-200 text-base pr-12"
                            placeholder="${msg('passwordPlaceholder')}"
                            aria-invalid="<#if messagesPerField.existsError('password')>true</#if>"
                        />
                        <button 
                            type="button" 
                            id="toggle-password"
                            class="absolute inset-y-0 right-0 flex items-center pr-4 text-gray-400 hover:text-gray-600 transition-colors duration-200"
                        >
                            <svg id="icon-eye-off" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                            </svg>
                            <svg id="icon-eye" class="w-5 h-5 hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                        </button>
                    </div>
                    <#if messagesPerField.existsError('password')>
                        <span class="text-sm text-red-600 mt-1 block">
                            ${kcSanitize(messagesPerField.get('password'))?no_esc}
                        </span>
                    </#if>
                </div>
                
                <#if realm.resetPasswordAllowed>
                    <div class="text-right">
                        <a href="${url.loginResetCredentialsUrl}" class="text-sm font-medium text-primary-600 hover:text-primary-700 transition-colors duration-200">
                            ${msg("doForgotPassword")}
                        </a>
                    </div>
                </#if>
                
                <#if realm.rememberMe && !usernameHidden??>
                    <div class="flex items-center">
                        <input 
                            id="rememberMe" 
                            name="rememberMe" 
                            type="checkbox"
                            <#if login.rememberMe??>checked</#if>
                            class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                        />
                        <label for="rememberMe" class="ml-2 block text-sm text-gray-700">
                            ${msg("rememberMe")}
                        </label>
                    </div>
                </#if>
                
                <button 
                    type="submit"
                    id="btn-login"
                    class="w-full flex items-center justify-center px-4 py-3 text-base font-semibold text-white bg-primary-600 rounded-lg shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <span id="btn-login-text">${msg("doLogIn")}</span>
                    <span id="btn-login-spinner" class="spinner hidden ml-2"></span>
                </button>
            </form>
        </#if>

        <#if realm.password && social.providers??>
            <div class="mt-6">
                <div class="relative">
                    <div class="absolute inset-0 flex items-center">
                        <div class="w-full border-t border-gray-300"></div>
                    </div>
                    <div class="relative flex justify-center text-sm">
                        <span class="px-4 bg-white text-gray-500 font-medium">${msg("identity-provider-login-label")}</span>
                    </div>
                </div>
                
                <div class="mt-6 grid grid-cols-1 gap-3">
                    <#list social.providers as p>
                        <a href="${p.loginUrl}" 
                           id="social-${p.alias}"
                           class="flex items-center justify-center px-4 py-3 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-all duration-200">
                            <#if p.iconClasses?has_content>
                                <i class="${p.iconClasses!}" aria-hidden="true"></i>
                            </#if>
                            <span>${p.displayName!}</span>
                        </a>
                    </#list>
                </div>
            </div>
        </#if>
    </#if>
</@layout.registrationLayout>
