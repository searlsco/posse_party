# Threads Account Setup

This guide walks through connecting your Threads account to POSSE Party so it can publish posts on your behalf.

Before you start, make sure you’ve created a Meta app with the Threads use case enabled by following [Meta app setup guide](/docs/account_setup/meta.md), then return here.

## What POSSE Party Needs From You

- `Access Token` generated for your Threads user via the Threads use case

## How to Set Up Your Account

1. [Enable Threads permissions for testing](#1-enable-threads-permissions-for-testing)
2. [Find your Threads app credentials](#2-find-your-threads-app-credentials)
3. [Add and approve a Threads tester](#3-add-and-approve-a-threads-tester)
4. [Generate a test user access token](#4-generate-a-test-user-access-token)
5. [Add Threads to POSSE Party](#5-add-threads-to-posse-party)

### 1. Enable Threads Permissions for Testing

1. From the dashboard, click **Customize the Access the Threads API use case**.

![Meta app dashboard ready for platform configuration](../images/meta-13.png)


2. Under **threads_content_publish**, click **+ Add**.

![Meta app dashboard with customize link for Access the Threads API](../images/threads-1.png)

3. After a short wait, confirm both **threads_basic** and **threads_content_publish** say **Ready for testing**.

![Permissions list with threads_content_publish add button](../images/threads-2.png)

### 2. Find Your Threads App Credentials

1. Within the **Customize use case** page, click **Settings**.

![Threads use case customize page with Settings tab](../images/threads-3.png)

2. Note your **Threads App ID**, then click **Show** next to **Threads app secret** and take note of it.

![Threads app settings with App ID and App Secret](../images/threads-4.png)

[Aside: even though POSSE Party doesn’t implement an interactive OAuth flow for Threads, if you wish to change the app’s display name, Meta will require you to enter callback URLs to pass form validation—in my case, I just entered dummy ones below.]


### 3. Add and Approve a Threads Tester

1. In the Threads use case settings, scroll to the bottom and click **Add or Remove Threads Testers**.

![Add or Remove Threads Testers link](../images/threads-5.png)

2. Click **Add People**.

![Threads testers page with Add People](../images/threads-6.png)

3. Choose **Threads Tester**.

![Role selection showing Threads Tester](../images/threads-7.png)

4. Enter the Threads username you want to authorize for this app, then click **Add**.

![Add Threads tester username form](../images/threads-8.png)

The Threads tester will appear as **Pending**.

![Tester added and showing pending status](../images/threads-10.png)

5. In another window or from a mobile device, have the user log into Threads and visit **Account settings** and click **Website permissions**.

![Threads account settings entry point](../images/threads-11.png)

6. Click **Invites**.

![Website permissions screen](../images/threads-12.png)

7. Click **Accept**.

![Invites screen](../images/threads-13.png)

8. Click **Accept** again on the confirmation dialog, then return to the app dashboard in Meta for Developers.

![Invite acceptance confirmation](../images/threads-14.png)

9. The Threads user should no longer appear as **Pending** in the **App Roles** screen.

![Meta dashboard after returning from invite acceptance](../images/threads-15.png)

### 4. Generate a Test User Access Token

1. Back in the Threads use case screen's **Settings** tab, scroll to the **User Token Generator** panel, and click **Generate Access Token** next to your user.

![Threads testers list in settings](../images/threads-16.png)

2. This brings up a consent screen requiring you to be authenticated as the test user. Ensure you're logged in as the same user and click **Continue**.

![OAuth consent screen for generating a Threads test token](../images/threads-17.png)

3. Check **I understand**, then copy the generated access token.

![Generated access token screen with I understand checkbox](../images/threads-18.png)

### 5. Add Threads to POSSE Party

1. In POSSE Party, go to **Accounts** and click **Add Account**. Give the account a label and select **Threads** as the platform.

![POSSE Party Add Account form](../images/threads-19.png)

2. Paste the access token into `Access Token`, then click **Create account**.

![POSSE Party create account screen with Threads selected](../images/threads-20.png)

Once saved, POSSE Party will be able to publish crossposts to your Threads account using your site's feed and account settings.
