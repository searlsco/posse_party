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

1. Visit [https://console.cloud.google.com](https://console.cloud.google.com) and sign in with the Google account you use for YouTube. Check **I agree…** and click **Agree and continue**

![Google Cloud welcome screen](../images/youtube-1.png)

2. In the top bar, click **Select a project**.

![Google Cloud terms of service prompt](../images/youtube-2.png)

3. In the Select a project dialog, click **New Project**.

![Google Cloud project selector](../images/youtube-3.png)

4. Give the project a clear name (for example, `POSSE Party YouTube`) and click **Create**.

![Google Cloud new project dialog](../images/youtube-4.png)

5. Wait for creation to finish, then click **Select project** for the new project so it becomes the active one.

![Google Cloud project creation in progress](../images/youtube-5.png)

6. In the left sidebar, choose **APIs & Services → Library**.

![Google Cloud dashboard with new project selected](../images/youtube-6.png)

7. Search for **YouTube Data API v3**.

![APIs & Services library in Google Cloud](../images/youtube-7.png)

8. Click the **YouTube Data API v3** result to open its details page.

![Search results for YouTube Data API v3](../images/youtube-8.png)

9. Click **Enable** to enable the API for your project.

![YouTube Data API v3 details page](../images/youtube-9.png)

10. After enabling, click **Create credentials** to start the OAuth setup.

![YouTube Data API v3 enabled in Google Cloud](../images/youtube-10.png)

### 2. Configure OAuth Consent and Scopes

1. When prompted for **Credential type**, select **User data** and click **Next**.

![Credential type selection for user data](../images/youtube-11.png)


2. On the **OAuth consent screen** step, fill out an app name and enter a user support email.

![Credential type selection for user data](../images/youtube-12.png)

3. Provide a developer contact email and click **Save and continue**.

![OAuth consent screen app details](../images/youtube-13.png)

4. On the **Scopes** step, search for the scope ending in `/auth/youtube.upload`.

![OAuth consent screen support email section](../images/youtube-14.png)

5. Check the box next to the YouTube upload scope and click **Update**.

![Scope search for youtube.upload](../images/youtube-15.png)

6. Back on the scopes list, click **Save and continue** to proceed.

![Selected youtube.upload scope in OAuth scopes](../images/youtube-16.png)

### 3. Create an OAuth Client with POSSE Party Redirect URLs

1. On the **OAuth client ID** step, choose **Web application** as the application type and give it a descriptive name.

![Scopes step ready to save and continue](../images/youtube-17.png)

2. Under **Authorized redirect URIs**, add two URLs and then click **Create**:
    - Your POSSE Party instance URL with the YouTube credential renewal path (e.g., `https://example.posseparty.com/credential_renewals/youtube`)
    - A localhost URL you will use once to obtain the initial tokens. (e.g., `http://localhost:1234/callback`)

![OAuth client ID configuration for web application](../images/youtube-18.png)

3. Under "Download your credentials", click **Download**.

![OAuth client created with redirect URIs](../images/youtube-19.png)

4. Open it in a text editor; it will contain a JSON object that looks like:

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

Take note of the `client_id` and `client_secret` values.

5. Click **Done** to exit the wizard.

![Google Cloud credentials list with new OAuth client](../images/youtube-20.png)

### 4. Add Test Users to the OAuth Consent Screen

1. In the left sidebar, click **OAuth consent screen** and then click **Audience**.

![OAuth consent screen link in Google Cloud sidebar](../images/youtube-21.png)

2. Scroll down to **Test users** and click **Add users**.

![OAuth consent screen Audience section](../images/youtube-22.png)

3. Add the email addresses for any Google accounts you plan to authorize with POSSE Party and click **Save**.

![Add test users dialog](../images/youtube-23.png)

### 5. Authorize POSSE Party and Exchange the Code for Tokens

Next, you will perform a one-time OAuth flow using the localhost redirect URI to obtain an initial access token and refresh token.

1. Copy the URL below and replace these two values:
    - `CLIENT_ID` with the client ID you noted earlier
    - `CALLBACK_URL` with the local callback URL you entered (we had suggested `http://localhost:1234/callback`)

```
https://accounts.google.com/o/oauth2/v2/auth?client_id=CLIENT_ID&redirect_uri=CALLBACK_URL&response_type=code&scope=https://www.googleapis.com/auth/youtube.upload&access_type=offline&prompt=consent
```

2. Open the URL in your browser and choose the Google account whose YouTube channel you want to connect.

![Google account selection for OAuth](../images/youtube-24.png)

3. Click the less prominent **Continue** link to proceed.

![Google account selection screen](../images/youtube-25.png)

4. Click **Continue** again.

![Google OAuth warning screen with Continue option](../images/youtube-26.png)

5. Your browser should redirect to your localhost URL. Don't be alarmed that it fails to connect! The value we need is in the URL itself.

![Google OAuth consent confirmation](../images/youtube-27.png)

6. Copy the URL from your browser's address bar and extract the `code` query parameter and take note of it

![Browser cannot connect to localhost callback](../images/youtube-28.png)

7. Open a terminal and run these commands, replacing the strings with the values you've noted in previous steps:

```bash
export CLIENT_ID="myclient.apps.googleusercontent.com"
export CALLBACK_URL="http://localhost:1234/callback"
export AUTH_CODE="the-code-you-just-copied"
export CLIENT_SECRET="myclientsecret"
```

8. In the same terminal window, run the following `curl` command to exchange the OAuth code for access and refresh tokens

```bash
curl --request POST \
  --data "code=$AUTH_CODE" \
  --data "client_id=$CLIENT_ID" \
  --data "client_secret=$CLIENT_SECRET" \
  --data "redirect_uri=$CALLBACK_URL" \
  --data "grant_type=authorization_code" \
  https://oauth2.googleapis.com/token
```

9. Google should return JSON similar to:

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

1. In POSSE Party, go to **Accounts** and click **Add Account**. Give the account a label and select **YouTube** as the platform.

2. Under **Credentials for YouTube**, fill:
    - `Client ID`
    - `Client Secret`
    - `Access Token`
    - `Refresh Token`

![Browser address bar showing OAuth code](../images/youtube-29.png)

Once saved, POSSE Party will be able to create YouTube posts for crossposts that include exactly one video, and will use your refresh token to renew the access token as needed.

