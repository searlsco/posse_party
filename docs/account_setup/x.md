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
4. [Add X to POSSE Party](#5-add-x-to-posse-party)

### 1. Sign Up for an X Developer Account

1. Visit [https://developer.x.com/en/portal](https://developer.x.com/en/portal) and sign in with your X account.

![X developer portal home](../images/x-1.png)

2. Scroll down to the section offering free access and click **Sign up for Free Account**.

![X developer free account signup section](../images/x-2.png)

3. Fill out the application describing how you intend to use the API before agreeing to the terms and clicking **Submit**. For example, you might write something like:

> I intend to publish my work more consistently to X by automatically syndicating links and media from my blog/personal site to my X account via a simple application that mirrors my RSS/Atom feed. I agree to abide by the terms and conditions of the X API Platform.

![X developer application form](../images/x-3.png)

### 2. Configure Your X Project

Once your developer account is approved:

1. From the X developer portal, open your default project.

![X default project overview](../images/x-6.png)

2. Click **Settings**, then click **Edit**.

![X project settings link](../images/x-7.png)

3. Fill out the project name, use case, and description (for example, “Syndicating content from my blog / personal site to my X account.”), then click **Save**.

![X project edit form](../images/x-8.png)

4. Confirm your project details were persisted correctly

![X project settings saved](../images/x-9.png)

### 3. Configure Your App and User Authentication

1. From the project **Dashboard**, find your **Project App** and click the **Gear** icon (⚙️).

![X project dashboard with app gear icon](../images/x-10.png)

2. Click **Edit**

![X project app settings gear](../images/x-11.png)

3. Give the app a clear name and description, and click **Save**.

![X project app edit form](../images/x-12.png)

4. Scroll down to **User authentication settings** and click **Set up**.

![X project app details](../images/x-13.png)

4. Under **App permissions**, choose **Read and write**.

![X user authentication settings](../images/x-14.png)

5. Under **Type of App**, select **Web App, Automated App, or Bot**.

![X app type configuration](../images/x-15.png)

6. In **App info**, enter:
      - Your website's URL
      - An OAuth callback/renewal URL (for example, `https://posseparty.com/credential_renewals/x`). POSSE Party does not currently implement this route, but X requires one to be set.

![X app info confirmation](../images/x-17.png)

7. Click **Save** and confirm your settings. X will show OAuth 2.0 client credentials. POSSE Party does not use these today, but you should copy and take note of them.

![X OAuth 2.0 client credentials](../images/x-18.png)

### 4. Generate API Keys and Access Tokens

1. In your X app’s settings, go to **Keys and tokens**.

![X app settings main view](../images/x-19.png)

2. Under **API Key and Secret**, click **Generate** (or **Regenerate** if you have previously created them).

![X Keys and tokens page](../images/x-20.png)

3. Copy and take note of both the **API Key** and **API Key Secret**, then click **Yes, I saved them**.

![X regenerate API key and secret](../images/x-21.png)

4. Under **Access Token and Secret**, click **Generate**.

![X API key regeneration confirmation](../images/x-22.png)

5. Copy and store both the **Access Token** and **Access Token Secret**, then click **Yes, I saved them**.

![X generate access token and secret](../images/x-23.png)

### 5. Add X to POSSE Party

1. In POSSE Party, go to **Accounts** and click **Add Account**. Give the account a label and select **X** as the platform.

2. Under **Credentials for X**, fill:
    - `API Key`
    - `API Key Secret`
    - `Access Token`
    - `Access Token Secret`

![POSSE Party X account credentials form](../images/x-24.png)

Once saved, POSSE Party will be able to publish crossposts to your X account using your site's feed and account settings.
