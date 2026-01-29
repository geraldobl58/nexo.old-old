<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username'); section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("webauthnLoginTitle")}</h2>
    <#elseif section = "form">
        <form id="webauth" action="${url.loginAction}" method="post" class="space-y-5">
            <input type="hidden" id="clientDataJSON" name="clientDataJSON"/>
            <input type="hidden" id="authenticatorData" name="authenticatorData"/>
            <input type="hidden" id="signature" name="signature"/>
            <input type="hidden" id="credentialId" name="credentialId"/>
            <input type="hidden" id="userHandle" name="userHandle"/>
            <input type="hidden" id="error" name="error"/>
        </form>

        <div class="text-center py-8">
            <div class="inline-flex items-center justify-center w-20 h-20 bg-primary-100 rounded-full mb-4">
                <svg class="w-10 h-10 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 11c0 3.517-1.009 6.799-2.753 9.571m-3.44-2.04l.054-.09A13.916 13.916 0 008 11a4 4 0 118 0c0 1.017-.07 2.019-.203 3m-2.118 6.844A21.88 21.88 0 0015.171 17m3.839 1.132c.645-2.266.99-4.659.99-7.132A8 8 0 008 4.07M3 15.364c.64-1.319 1-2.8 1-4.364 0-1.457.39-2.823 1.07-4" />
                </svg>
            </div>
            <p class="text-gray-600 mb-4">${msg("webauthnAuthenticate")}</p>
            <div class="inline-block">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
        </div>

        <script type="text/javascript" src="${url.resourcesCommonPath}/node_modules/jquery/dist/jquery.min.js"></script>
        <script type="text/javascript" src="${url.resourcesPath}/js/base64url.js"></script>
        <script type="text/javascript">
            function webAuthnAuthenticate() {
                let challenge = "${challenge}";
                let userVerification = "${userVerification}";
                let rpId = "${rpId}";
                let allowCredentials = [];

                <#if authenticators??>
                    <#list authenticators.authenticators as authenticator>
                        allowCredentials.push({
                            id: base64url.decode("${authenticator.credentialId}", {loose: true}),
                            type: 'public-key',
                        });
                    </#list>
                </#if>

                navigator.credentials.get({
                    publicKey: {
                        challenge: base64url.decode(challenge, {loose: true}),
                        allowCredentials: allowCredentials,
                        userVerification: userVerification,
                        rpId: rpId
                    }
                }).then((result) => {
                    window.result = result;

                    let clientDataJSON = result.response.clientDataJSON;
                    let authenticatorData = result.response.authenticatorData;
                    let signature = result.response.signature;

                    $("#clientDataJSON").val(base64url.encode(new Uint8Array(clientDataJSON), {pad: false}));
                    $("#authenticatorData").val(base64url.encode(new Uint8Array(authenticatorData), {pad: false}));
                    $("#signature").val(base64url.encode(new Uint8Array(signature), {pad: false}));
                    $("#credentialId").val(result.id);
                    if (result.response.userHandle) {
                        $("#userHandle").val(base64url.encode(new Uint8Array(result.response.userHandle), {pad: false}));
                    }
                    $("#webauth").submit();
                }).catch((err) => {
                    $("#error").val(err);
                    $("#webauth").submit();
                });
            }

            webAuthnAuthenticate();
        </script>
    </#if>
</@layout.registrationLayout>
