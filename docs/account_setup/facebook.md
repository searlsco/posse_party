# Facebook Pages Account Setup

This guide walks through connecting your Facebook Page to POSSE Party so it can publish posts on your behalf.

Before you start, make sure you’ve created a Meta app with the Facebook Pages use case enabled by following [Meta app setup guide](/docs/account_setup/meta.md), then return here.

## What POSSE Party Needs From You

- `Page ID` for the Facebook Page you want POSSE Party to publish to
- `Page Access Token` (a long-lived Page Access Token for that Page)

## How to Set Up Your Account

1. [Enable Facebook Pages permissions for testing](#1-enable-facebook-pages-permissions-for-testing)
2. [Generate a user access token in Graph API Explorer](#2-generate-a-user-access-token-in-graph-api-explorer)
3. [Find your page ID and short-lived page access token](#3-find-your-page-id-and-short-lived-page-access-token)
4. [Exchange for a long-lived page access token](#4-exchange-for-a-long-lived-page-access-token)
5. [Publish your Meta app](#5-publish-your-meta-app)
6. [Add Facebook to POSSE Party](#6-add-facebook-to-posse-party)

### 1. Enable Facebook Pages Permissions for Testing

1. From the dashboard, click **Customize the Manage everything on your Page use case**.

![Meta app dashboard showing the Facebook Pages use case](../images/facebook-1.png)

2. This opens the **Customize use case** screen. Scroll down to **pages_manage_metadata**.

![Facebook Pages use case customize view](../images/facebook-2.png)

3. Click **+ Add** next to each of:
    - `pages_manage_metadata`
    - `pages_manage_posts`
    - `pages_read_engagement`

![Permissions list scrolled to Facebook Pages permissions](../images/facebook-3.png)

4. You may be asked to confirm that **pages_read_engagement** will impact the Instagram use case. If so, click **Add**.

![Permission impact confirmation dialog](../images/facebook-5.png)

5. Confirm all three permissions show **Ready for testing**.

![Pages permissions showing Ready for testing](../images/facebook-6.png)

### 2. Generate a User Access Token in Graph API Explorer

1. In Meta for Developers, select **Graph API Explorer** from the **Tools** menu.

![Tools menu with Graph API Explorer](../images/facebook-7.png)

2. In Graph API Explorer, locate the permissions picker toward the bottom of the panel on the right and click **Add a permission** .

![Graph API Explorer with Access Token panel](../images/facebook-8.png)

3. Select these permissions under **Events Groups Pages**:
    - `business_management`
    - `pages_manage_metadata`
    - `pages_manage_posts`
    - `pages_read_engagement`
    - `pages_show_list`

![Add a Permission dropdown showing required permissions](../images/facebook-9.png)

4. After selecting, your list should show all five permissions. Select **User Token** under "User or Page" and click **Generate Access Token**

![Selected permissions list](../images/facebook-10.png)

5. This will bring up an authorization dialog. If the current user has administrative privileges over the Facebook Page you wish to connect to POSSE Party, you can continue as the same user. Otherwise, you can change users in the top-right corner. Once the correct user is active, click **Continue as …**.

![Facebook authorization prompt](../images/facebook-12.png)

6. Decide whether to generate a token that will have access to all current and future pages, or select only the pages you intend to publish to via POSSE Party and click **Continue**.

![Choose Pages access scope](../images/facebook-13.png)

7. Similarly, if a business portfolio owns the page, select the appropriate business(es) and click **Continue**.

![Choose Businesses access scope](../images/facebook-14.png)

8. Review the request and click **Save**.

![Review access request](../images/facebook-15.png)

9. After saving, Facebook shows a confirmation screen. Click **Got it**.

![Facebook connected confirmation](../images/facebook-16.png)

10. Back in Graph API Explorer, confirm the token is populated and the five permissions are listed.

![Graph API Explorer with access token and selected permissions](../images/facebook-17.png)

### 3. Find Your Page ID and Short-Lived Page Access Token

 you’ll call `me/accounts` to get your Pages and their Page access tokens.

1. In the Graph API Explorer's request path field near the top, replace `me?fields=id,name` with `me/accounts` and click **Submit**.

![Graph API Explorer request path set to me/accounts](../images/facebook-18.png)

2. In the JSON response, find your Page under the top-level `data` array and copy:
    - `access_token` (this is a short-lived "Page Access Token" for your Page)
    - `id` (this is your `Page ID`)

![Graph API Explorer response showing Pages data](../images/facebook-19.png)

### 4. Exchange for a Long-Lived Page Access Token

1. In Meta for Developers, select **Access Token Debugger** from the **Tools** menu.

![Tools menu with Access Token Debugger](../images/facebook-20.png)

2. Paste the short-lived Page Access Token you copied above and click **Debug**.

![Access Token Debugger input with Debug button](../images/facebook-21.png)

3. Confirm the token is valid and includes these scopes:
    - `business_management`
    - `pages_manage_metadata`
    - `pages_manage_posts`
    - `pages_read_engagement`
    - `pages_show_list`

![Token debug results showing scopes](../images/facebook-22.png)

4. Scroll down and click **Extend Access Token** to exchange it for a long-lived Page access token.

![Extend Access Token button](../images/facebook-23.png)

5. Meta will prompt you to re-enter your password. Complete that prompt to finish the exchange.

![Password re-entry prompt](../images/facebook-24.png)

6. Copy the long-lived token. This is the `Page Access Token` you’ll paste into POSSE Party.

![Long-lived page access token](../images/facebook-25.png)

### 5. Publish Your Meta App

Before posts created by POSSE Party will be visible to other users on Facebook, your Meta app must be published.

1. In Meta for Developers, click **Publish** in the left sidebar.

![Publish in Meta for Developers](../images/facebook-28.png)

2. Click **Go to app settings**.

![Go to app settings](../images/facebook-29.png)

3. Add a publicly-accessible **Privacy Policy URL**.

POSSE Party includes a built-in privacy policy page at `https://<your APP_HOST>/policies/privacy` ([example](https://app.posseparty.com/policies/privacy)). The URL must be reachable from the public internet, or the publishing step will fail.

![App settings basic fields](../images/facebook-30.png)

4. Click **Save changes**.

![Save changes](../images/facebook-31.png)

5. Return to **Publish** and click **Publish**.

![Publish app](../images/facebook-32.png)

Once your app is published, new posts created by POSSE Party should be publicly visible.

### 6. Add Facebook to POSSE Party

1. In POSSE Party, go to **Accounts** and click **Add account**. Enter a label and select **Facebook** as the platform.

![POSSE Party create account screen](../images/facebook-26.png)

2. Scroll down to **Credentials for Facebook** and fill in:
  - `Page ID`
  - `Page Access Token`

![POSSE Party Facebook credentials form](../images/facebook-27.png)

Once created, POSSE Party will be able to publish crossposts to your Facebook Page from your site's feed.
