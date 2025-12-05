# X (Twitter) Account Setup

This guide walks through connecting your X (Twitter) account to POSSE Party so it can publish posts on your behalf.

## What POSSE Party Needs From You

- `API Key`
- `API Key Secret`
- `Access Token`
- `Access Token Secret`

All four values come from your X developer app’s **Keys and tokens** page.

## How to Set Up Your Account

1. [Sign up for an X developer account](#1-sign-up-for-an-x-developer-account)
2. [Configure your X project](#2-configure-your-x-project)
3. [Configure your app and user authentication](#3-configure-your-app-and-user-authentication)
4. [Generate API keys and access tokens and add them to POSSE Party](#4-generate-api-keys-and-access-tokens-and-add-them-to-posse-party)

### 1. Sign Up for an X Developer Account

1. Visit `https://developer.x.com/en/portal` and sign in with your X account.
2. Scroll down to the section offering free access and click **Sign up for Free Account**.

![X developer portal home](../images/x-1.png)

Scroll until you see the free tier signup panel.

![X developer free account signup section](../images/x-2.png)

3. Fill out the application describing how you intend to use the API. For example:

> I intend to publish my work more consistently to X by automatically syndicating links and media from my blog/personal site to my X account via a simple application that mirrors my RSS/Atom feed. I agree to abide by the terms and conditions of the X API Platform.

![X developer application form](../images/x-3.png)

4. Submit the application to create your developer account.

### 2. Configure Your X Project

Once your developer account is approved:

1. From the X developer portal, open your default project.

![X default project overview](../images/x-6.png)

2. Click **Settings**, then click **Edit**.

![X project settings link](../images/x-7.png)

Open the project settings to review configuration options.

![X project edit form](../images/x-8.png)

3. Fill out the project name, use case, and description (for example, “Syndicating content from my blog / personal site to my X account.”), then save.

![X project settings saved](../images/x-9.png)

### 3. Configure Your App and User Authentication

1. From the project **Dashboard**, find your **Project App** and click the gear icon.

![X project dashboard with app gear icon](../images/x-10.png)

Use the gear icon to open the app-level settings.

![X project app settings gear](../images/x-11.png)

2. Click **Edit**, give the app a clear name and description, and save.

![X project app edit form](../images/x-12.png)

Confirm the app name and description reflect how POSSE Party will use your account.

![X project app details](../images/x-13.png)

3. Scroll down to **User authentication settings** and click **Set up**.

![X user authentication settings](../images/x-14.png)

4. Under **App permissions**, choose **Read and write**.
5. Under **Type of App**, select **Web App, Automated App, or Bot**.

![X app type configuration](../images/x-15.png)

6. In **App info**, enter:

   - Your website URL
   - An OAuth callback/renewal URL (for example, `https://posseparty.com/credential_renewals/x`). POSSE Party does not currently use this URL, but X requires one to be set.

![X app info with website and redirect URL](../images/x-16.png)

Review the summary to confirm URLs and permissions look correct.

![X app info confirmation](../images/x-17.png)

7. Save and confirm your settings. X will show OAuth 2.0 client credentials; POSSE Party does not use these today, but you may want to save them.

![X OAuth 2.0 client credentials](../images/x-18.png)

### 4. Generate API Keys and Access Tokens and Add Them to POSSE Party

1. In your app’s settings, go to **Keys and tokens**.

![X app settings main view](../images/x-19.png)

Open the **Keys and tokens** section for your project app.

![X Keys and tokens page](../images/x-20.png)

2. Under **API Key and Secret**, click **Regenerate** (or **Generate** if you have not created them yet). Copy and store both the **API Key** and **API Key Secret**.

![X regenerate API key and secret](../images/x-21.png)

Confirm you’ve saved the new API key and secret before continuing.

![X API key regeneration confirmation](../images/x-22.png)

3. Under **Access Token and Secret**, click **Generate**. Copy and store both the **Access Token** and **Access Token Secret**.

![X generate access token and secret](../images/x-23.png)

4. In POSSE Party, add a new X account:

   - Set `API Key` to your X API key
   - Set `API Key Secret` to your X API key secret
   - Set `Access Token` to your X access token
   - Set `Access Token Secret` to your X access token secret
   - Save the account

![POSSE Party X account credentials form](../images/x-24.png)

Once saved, POSSE Party will be able to publish crossposts to your X account using your Atom feed and account settings.
