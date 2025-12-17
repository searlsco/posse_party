# Instagram Account Setup

This guide walks through connecting your Instagram account to POSSE Party so it can publish posts on your behalf.

Before you start, you’ll need a Meta developer app with the Instagram use case enabled. If you haven’t done that yet, follow [Meta app setup guide](/docs/account_setup/meta.md), then return here.

Also note: any Instagram users you add to your app must be **Professional** accounts (Creator or Business). See [Instagram's docs](https://help.instagram.com/502981923235522) for details.

## What POSSE Party Needs From You

- `App ID` - the Instagram app ID shown in Meta for Developers
- `App Secret` -the Instagram app secret shown in Meta for Developers
- `User ID` your Instagram user ID shown when generating access tokens
- `Access Token` - generated for that user

## How to Set Up Your Account

1. [Open the Instagram use case in Meta for Developers](#1-open-the-instagram-use-case-in-meta-for-developers)
2. [Copy your Instagram app ID and app secret](#2-copy-your-instagram-app-id-and-app-secret)
3. [Enable instagram_content_publish](#3-enable-instagram_content_publish)
4. [Add yourself as an Instagram tester](#4-add-yourself-as-an-instagram-tester)
5. [Accept the tester invite in Instagram](#5-accept-the-tester-invite-in-instagram)
6. [Generate an access token and copy your user ID](#6-generate-an-access-token-and-copy-your-user-id)
7. [Add Instagram to POSSE Party](#7-add-instagram-to-posse-party)

### 1. Open the Instagram Use Case in Meta for Developers

1. From the dashboard, click **Customize the Manage messaging & content on Instagram use case**.

![Meta app dashboard ready for platform configuration](../images/meta-13.png)

This should take you to the **API setup with Instagram login** tab of the **Customize use case** screen.

### 2. Copy Your Instagram App ID and App Secret

1. On the **API setup with Instagram login** tab, take note of the **Instagram app ID** and click **Show** next to the **Instagram app secret**.

![Instagram use case customize link](../images/instagram-1.png)

2. Copy and store both values. These are the `App ID` and `App Secret` you’ll paste into POSSE Party later.

![Instagram use case settings showing Instagram app ID and app secret](../images/instagram-2.png)

### 3. Enable instagram_content_publish

1. Scroll down to **Add required messaging permissions** and click **Add all required permissions**.

![Add required messaging permissions section](../images/instagram-3.png)

2. Click **Go to permissions and features**.

![Add all required permissions button](../images/instagram-4.png)

3. On the permissions page, scroll to **instagram_content_publish**.

![Go to permissions and features button](../images/instagram-5.png)

4. Click **+ Add** next to **instagram_content_publish**.

![Permissions list scrolled to instagram_content_publish](../images/instagram-6.png)

5. Verify the permission reads **Ready for testing**.

![Add instagram_content_publish permission](../images/instagram-7.png)

### 4. Add Yourself as an Instagram Tester

1. From the left sidebar, go to **App roles → Roles** and click **Add People**.

![App roles navigation](../images/instagram-8.png)

2. Select **Instagram Tester**.

![Select Instagram Tester role](../images/instagram-9.png)

3. Enter your Instagram username and click **Add**.

![Add Instagram tester username](../images/instagram-10.png)

4. The account should show as **Pending** until you accept the invite in Instagram, as described in the next section

![Pending test user](../images/instagram-11.png)

### 5. Accept the Tester Invite in Instagram

1. Log into Instagram as the same user you just added, then open **Account settings**. Scroll the sidebar and click **Website permissions**.

![Instagram account settings entry point](../images/instagram-12.png)

2. Click **Apps and websites**.

![Website permissions pane](../images/instagram-13.png)

3. Click **Tester Invites**.

![Apps and websites menu](../images/instagram-14.png)

4. Under your app, click **Accept**.

![Tester invites section](../images/instagram-15.png)

5. Verify your POSSE Party app is authorized.

![Accept tester invite](../images/instagram-16.png)

### 6. Generate an Access Token and Copy Your User ID

1. Back in Meta for Developers, return to the Instagram use case setup screen.

![Instagram use case setup screen](../images/instagram-17.png)

2. Scroll down to **Generate access tokens** and expand it. You should see your user listed there. Under the username is your Instagram **User ID** (the number here begins with `178414...`). Click the numeric ID to copy it and take note of it, then click **Generate token**.

![Generate access tokens panel expanded](../images/instagram-18.png)

3. A log in pop-up should appear (check your browser's pop-up blocker UI if it doesn't)

![Add account prompt](../images/instagram-20.png)

4. Log in as the same Instagram user you selected above.

![Instagram login screen](../images/instagram-21.png)

5. After logging in, you should see a permissions panel. POSSE Party should only need to check the **Access and publish content** permission, but you can choose whether to leave the other permissions enabled. Click **Allow**.

![Instagram consent permissions panel](../images/instagram-22.png)

6. Check **I understand** and copy the generated **Access Token**.

![Generated access token with I understand checkbox](../images/instagram-24.png)

### 7. Add Instagram to POSSE Party

1. In POSSE Party, go to **Accounts** and click **Add Account**. Enter a label and select **Instagram** as the platform.

![POSSE Party create new account](../images/instagram-25.png)

2. Scroll down to **Credentials for Instagram**.

![Credentials for Instagram section](../images/instagram-26.png)

3. Fill in the fields you took note of in the previous steps: `App ID`, `App Secret`, `User ID`, `Access Token`

![Filled credentials](../images/instagram-27.png)

After clicking **Create Account**, POSSE Party will begin to automatically syndicate any posts containing image and video media to your Instagram account. Text-based posts will be skipped.
