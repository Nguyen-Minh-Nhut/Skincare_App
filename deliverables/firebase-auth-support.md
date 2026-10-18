# Firebase Support — custom password-reset action URL rejected

Subject: EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED when saving custom email action URL

Hello Firebase Support,

For Firebase project `myapp-7f561`, we cannot save our custom email action URL. Please investigate why this configuration update is rejected and help enable the supported custom email action handler configuration.

- Current callback URI: https://myapp-7f561.firebaseapp.com/__/auth/action
- Desired callback URI: https://myapp-7f561-auth.web.app/reset-password
- The destination is deployed on Firebase Hosting site `myapp-7f561-auth` in the same project.
- `myapp-7f561-auth.web.app` has been added to Firebase Authentication authorized domains successfully.
- The deployed handler verifies password reset codes with Firebase Auth, supports password confirmation, and handles expired/used codes.
- Existing email delivery uses the DEFAULT provider.

Reproduction:
1. Open Authentication → Templates → Customize action URL.
2. Enter the desired callback URI and attempt to save.
3. A direct project configuration update also fails:
   PATCH https://identitytoolkit.googleapis.com/admin/v2/projects/myapp-7f561/config?update_mask=notification.sendEmail.callbackUri
   Body: {"notification":{"sendEmail":{"callbackUri":"https://myapp-7f561-auth.web.app/reset-password"}}}
4. API response: HTTP 400, EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED.

The callback remains the original Firebase handler. Authorized domain updates and Hosting deployment succeed, so the failure is specifically on the email action configuration update. Please identify any project restriction or additional required setup.

Related report: https://github.com/firebase/firebase-tools/issues/10188

No credentials, real reset codes, or user email addresses are included in this report.
