<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "header">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">${msg("webauthnRegisterTitle")}</h2>
    <#elseif section = "form">
        <form id="register" action="${url.loginAction}" method="post" class="space-y-5">
            <input type="hidden" id="clientDataJSON" name="clientDataJSON"/>
            <input type="hidden" id="attestationObject" name="attestationObject"/>
            <input type="hidden" id="publicKeyCredentialId" name="publicKeyCredentialId"/>
            <input type="hidden" id="authenticatorLabel" name="authenticatorLabel"/>
            <input type="hidden" id="error" name="error"/>
        </form>

        <div class="text-center py-8">
            <div class="inline-flex items-center justify-center w-20 h-20 bg-primary-100 rounded-full mb-4">
                <svg class="w-10 h-10 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                </svg>
            </div>
            <p class="text-gray-600 mb-4">${msg("webauthnRegister")}</p>
            <div class="inline-block">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
        </div>

        <script type="text/javascript" src="${url.resourcesCommonPath}/node_modules/jquery/dist/jquery.min.js"></script>
        <script type="text/javascript" src="${url.resourcesPath}/js/base64url.js"></script>
        <script type="text/javascript">
            function webAuthnRegister() {
                let challenge = "${challenge}";
                let userid = "${userid}";
                let username = "${username}";
                let signatureAlgorithms = JSON.parse("${signatureAlgorithms}");
                let rpEntityName = "${rpEntityName}";
                let rpId = "${rpId}";
                let attestationConveyancePreference = "${attestationConveyancePreference}";
                let authenticatorAttachment = "${authenticatorAttachment}";
                let requireResidentKey = "${requireResidentKey}";
                let userVerificationRequirement = "${userVerificationRequirement}";

                let publicKey = {
                    challenge: base64url.decode(challenge, {loose: true}),
                    rp: {name: rpEntityName, id: rpId},
                    user: {
                        id: base64url.decode(userid, {loose: true}),
                        name: username,
                        displayName: username
                    },
                    pubKeyCredParams: signatureAlgorithms,
                    authenticatorSelection: {
                        requireResidentKey: requireResidentKey === 'Yes',
                        userVerification: userVerificationRequirement
                    },
                    timeout: 60000,
                    attestation: attestationConveyancePreference
                };

                if (authenticatorAttachment !== 'not specified') {
                    publicKey.authenticatorSelection.authenticatorAttachment = authenticatorAttachment;
                }

                navigator.credentials.create({publicKey: publicKey})
                    .then((result) => {
                        window.result = result;

                        let clientDataJSON = result.response.clientDataJSON;
                        let attestationObject = result.response.attestationObject;
                        let publicKeyCredentialId = result.rawId;

                        $("#clientDataJSON").val(base64url.encode(new Uint8Array(clientDataJSON), {pad: false}));
                        $("#attestationObject").val(base64url.encode(new Uint8Array(attestationObject), {pad: false}));
                        $("#publicKeyCredentialId").val(base64url.encode(new Uint8Array(publicKeyCredentialId), {pad: false}));
                        $("#authenticatorLabel").val(username + "'s authenticator");
                        $("#register").submit();
                    })
                    .catch((err) => {
                        $("#error").val(err);
                        $("#register").submit();
                    });
            }

            webAuthnRegister();
        </script>
    </#if>
</@layout.registrationLayout>
