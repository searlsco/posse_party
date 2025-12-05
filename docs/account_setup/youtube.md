# YouTube Account Setup

This guide walks through connecting your YouTube account to POSSE Party so it can upload videos on your behalf.

## What POSSE Party Needs From You

- `Client ID` for your Google Cloud OAuth client
- `Client Secret` for that client
- `Access Token` generated for the `youtube.upload` scope
- `Refresh Token` paired with that access token so POSSE Party can renew it

All four values come from your Google Cloud project’s OAuth client and the token exchange step below.

## How to Set Up Your Account

1. [Create a Google Cloud project and enable the YouTube Data API](#1-create-a-google-cloud-project-and-enable-the-youtube-data-api)
2. [Configure OAuth consent and scopes](#2-configure-oauth-consent-and-scopes)
3. [Create an OAuth client with POSSE Party redirect URLs](#3-create-an-oauth-client-with-posse-party-redirect-urls)
4. [Add test users to the OAuth consent screen](#4-add-test-users-to-the-oauth-consent-screen)
5. [Authorize POSSE Party and exchange the code for tokens](#5-authorize-posse-party-and-exchange-the-code-for-tokens)
6. [Add YouTube to POSSE Party](#6-add-youtube-to-posse-party)

### 1. Create a Google Cloud Project and Enable the YouTube Data API

1. Visit `https://console.cloud.google.com` and sign in with the Google account you use for YouTube.

![Google Cloud welcome screen](../images/youtube-1.png)

2. Accept any terms of service prompts if they appear.

![Google Cloud terms of service prompt](../images/youtube-2.png)

3. In the top bar, click **Select project**.

![Google Cloud project selector](../images/youtube-3.png)

4. In the project dialog, click **New Project**.

![Google Cloud new project dialog](../images/youtube-4.png)

5. Give the project a clear name (for example, `POSSE Party YouTube`) and click **Create**.

![Google Cloud project creation in progress](../images/youtube-5.png)

6. Wait for creation to finish, then click **Select project** for the new project so it becomes the active one.

![Google Cloud dashboard with new project selected](../images/youtube-6.png)

7. In the left sidebar, choose **APIs & Services → Library**.

![APIs & Services library in Google Cloud](../images/youtube-7.png)

8. Search for **YouTube Data API v3**.

![Search results for YouTube Data API v3](../images/youtube-8.png)

9. Click the **YouTube Data API v3** result to open its details page.

![YouTube Data API v3 details page](../images/youtube-9.png)

10. Click **Enable** to enable the API for your project.

![YouTube Data API v3 enabled in Google Cloud](../images/youtube-10.png)

11. After enabling, click **Create credentials** to start the OAuth setup.

![Create credentials button in YouTube Data API v3](../images/youtube-11.png)

### 2. Configure OAuth Consent and Scopes

1. When prompted for **Credential type**, select **User data** and click **Next**.

![Credential type selection for user data](../images/youtube-12.png)

2. On the **OAuth consent screen** step, fill out an app name and select your email address as the user-facing and developer contact.

![OAuth consent screen app details](../images/youtube-13.png)

3. Enter a support email and click **Save and continue**.

![OAuth consent screen support email section](../images/youtube-14.png)

4. On the **Scopes** step, search for the scope ending in `.../auth/youtube.upload`.

![Scope search for youtube.upload](../images/youtube-15.png)

5. Check the box next to the YouTube upload scope and click **Update**.

![Selected youtube.upload scope in OAuth scopes](../images/youtube-16.png)

6. Back on the scopes list, click **Save and continue** to proceed.

![Scopes step ready to save and continue](../images/youtube-17.png)

### 3. Create an OAuth Client with POSSE Party Redirect URLs

1. On the **OAuth client ID** step, choose **Web application** as the application type and give it a descriptive name.

![OAuth client ID configuration for web application](../images/youtube-18.png)

2. Under **Authorized redirect URIs**, add your POSSE Party instance URL with the YouTube credential renewal path. For example:

`https://example.posseparty.com/credential_renewals/youtube`

3. Add a second redirect URI for a local callback you will use once to obtain the initial tokens. For example:

`http://localhost:1234/callback`

4. Click **Create**.

![OAuth client created with redirect URIs](../images/youtube-19.png)

5. In the confirmation dialog, copy your **Client ID**, then click **Download** to download the OAuth client JSON. Open it in a text editor; it will contain keys like:

```json
{
  "web": {
    "client_id": "myclient.apps.googleusercontent.com",
    "project_id": "posse-party-example-lol",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "myclientsecret",
    "redirect_uris": ["https://example.posseparty.com/credential_renewals/youtube"]
  }
}
```

6. Note the `client_id` and `client_secret` values; you will paste these into POSSE Party later. Click **Done** to close the dialog.

![Google Cloud credentials list with new OAuth client](../images/youtube-20.png)

### 4. Add Test Users to the OAuth Consent Screen

1. In the left sidebar, click **OAuth consent screen**.

![OAuth consent screen link in Google Cloud sidebar](../images/youtube-21.png)

2. Within the consent screen, click **Audience** (or the section containing test user controls).

![OAuth consent screen Audience section](../images/youtube-22.png)

3. Scroll down to **Test users** and click **Add users**.

![Add test users dialog](../images/youtube-23.png)

4. Add the email addresses for any Google accounts you plan to authorize with POSSE Party and click **Save**.

### 5. Authorize POSSE Party and Exchange the Code for Tokens

Next, you will perform a one-time OAuth flow using the localhost redirect URI to obtain an initial access token and refresh token.

1. In a terminal, set environment variables for your client and callback URL:

```bash
export CLIENT_ID="myclient.apps.googleusercontent.com"
export CALLBACK_URL="http://localhost:1234/callback"
```

2. Construct an authorization URL that requests the `youtube.upload` scope:

```bash
echo "https://accounts.google.com/o/oauth2/v2/auth?client_id=$CLIENT_ID&redirect_uri=$CALLBACK_URL&response_type=code&scope=https://www.googleapis.com/auth/youtube.upload&access_type=offline&prompt=consent"
```

3. Run that command, copy the printed URL, and open it in your browser.

![Google account selection for OAuth](../images/youtube-24.png)

4. Choose the Google account whose YouTube channel you want to connect.

![Google account selection screen](../images/youtube-25.png)

5. When prompted about the app, click the secondary **Continue** link to proceed.

![Google OAuth warning screen with Continue option](../images/youtube-26.png)

6. Confirm any additional consent dialogs by clicking **Continue** again.

![Google OAuth consent confirmation](../images/youtube-27.png)

7. Eventually, your browser will fail to connect to `http://localhost:1234/callback` and show an error page. This is expected.

![Browser cannot connect to localhost callback](../images/youtube-28.png)

8. Despite the error, the URL in the address bar now contains a `code` query parameter. Copy the long `code` value from the URL.

![Browser address bar showing OAuth code](../images/youtube-29.png)

9. Back in your terminal, exchange the authorization code for tokens:

```bash
export AUTH_CODE="the-code-you-just-copied"
export CLIENT_SECRET="myclientsecret"

curl --request POST \
  --data "code=$AUTH_CODE" \
  --data "client_id=$CLIENT_ID" \
  --data "client_secret=$CLIENT_SECRET" \
  --data "redirect_uri=$CALLBACK_URL" \
  --data "grant_type=authorization_code" \
  https://oauth2.googleapis.com/token
```

10. Google should return JSON similar to:

```json
{
  "access_token": "yourtokenhere",
  "expires_in": 3599,
  "refresh_token": "yourrefreshtoken",
  "scope": "https://www.googleapis.com/auth/youtube.upload",
  "token_type": "Bearer",
  "refresh_token_expires_in": 604799
}
```

Copy both the `access_token` and `refresh_token` values for use in POSSE Party.

### 6. Add YouTube to POSSE Party

In POSSE Party, add a new YouTube account:

1. Set `Client ID` to the OAuth client ID from Google Cloud
2. Set `Client Secret` to the OAuth client secret from Google Cloud
3. Set `Access Token` to the `access_token` from the token response
4. Set `Refresh Token` to the `refresh_token` from the token response
5. Save the account

Once saved, POSSE Party will be able to create YouTube posts for crossposts that include exactly one video, and will use your refresh token to renew the access token as needed.

