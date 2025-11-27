# Configuring e-mail delivery

POSSE Party was designed to send several important e-mails to help you maintain your instance and user account. When an e-mail sender is configured:

1. Login via email is fully supported (via [searls-auth](https://github.com/searlsco/searls-auth))
2. OAuth token renewals that require manual intervention (e.g., LinkedIn and YouTube) are sent as links via e-mail
3. Failures and 500s encountered by the server are delivered with messages stack traces

Most cloud hosting providers now block outbound SMTP. So in addition to SMTP, POSSE Party also supports a number of other mail providers (enumerated below) that offer HTTP APIs.

**Note that only Amazon SES and SMTP have actually been tested. The rest were essentially vibe coded without tests. YMMV.**

## Choose a provider

- Set `MAIL_PROVIDER` to one of: `amazon_ses`, `resend`, `mailgun`, `postmark`, `sendgrid`, `brevo`, `mailjet`, `smtp`
- If `MAIL_PROVIDER` is blank, POSSE Party will search for the first configured service, in this order: `amazon_ses`, `resend`, `mailgun`, `postmark`, `sendgrid`, `brevo`, `mailjet`, then `smtp`
- All providers need a valid `MAIL_FROM_ADDRESS` (e.g., `possy@posseparty.com`) configured. Rules on sender address verification vary from provider to provider

## Provider settings

### SMTP (`MAIL_PROVIDER=smtp`)
- `SMTP_HOST`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_PORT` (default: `587`)
- `SMTP_ENABLE_STARTTLS` (default: `true`)

### Amazon SES (`MAIL_PROVIDER=amazon_ses`)
- `AWS_SES_REGION`
- `AWS_SES_ACCESS_KEY_ID`
- `AWS_SES_SECRET_ACCESS_KEY`

### Resend (`MAIL_PROVIDER=resend`)
- `RESEND_API_KEY`

### Mailgun (`MAIL_PROVIDER=mailgun`)
- `MAILGUN_API_KEY`
- `MAILGUN_DOMAIN` (e.g., `mg.example.com`)

### Postmark (`MAIL_PROVIDER=postmark`)
- `POSTMARK_API_TOKEN` (Server API token)

### SendGrid (`MAIL_PROVIDER=sendgrid`)
- `SENDGRID_API_KEY`

### Brevo / Sendinblue (`MAIL_PROVIDER=brevo`)
- `BREVO_API_KEY`

### Mailjet (`MAIL_PROVIDER=mailjet`)
- `MAILJET_API_KEY`
- `MAILJET_API_SECRET`

