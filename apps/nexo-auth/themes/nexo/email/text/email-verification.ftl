${msg("emailVerificationSubject")}

${msg("emailVerificationBody", user.firstName, realm.displayName)}

${msg("emailVerificationBodyText", link, linkExpiration)}

${msg("emailVerificationFooter")}

---
© ${.now?string('yyyy')} Nexo. ${msg("emailFooterCopyright")}
