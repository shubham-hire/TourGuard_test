# TourGuard Free Tier Deployment Guide

This guide will help you deploy your backend to **Render.com** (Free Tier) so you can have a permanent public URL (e.g., `https://tourguard-backend.onrender.com`) and stop dealing with local IP issues.

## Prerequisites

1.  **GitHub Account**: You need to push your code to a GitHub repository.
2.  **Render.com Account**: Sign up for free at [dashboard.render.com](https://dashboard.render.com/).
3.  **Google Gemini API Key**: Get a free API key from [aistudio.google.com](https://aistudio.google.com/app/apikey).

## Step 1: Push to GitHub

If you haven't already, push your entire `TourGuard_AppInterface` folder to a new GitHub repository.

```bash
git init
git add .
git commit -m "Prepare for Render deployment"
# Create a repo on GitHub.com and copy the remote URL
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## Step 2: Deploy to Render

1.  Go to the [Render Dashboard](https://dashboard.render.com/).
2.  Click **New +** -> **Blueprint**.
3.  Connect your GitHub repository.
4.  Render will automatically detect the `render.yaml` file we created.
5.  It will ask you for `ML_ENGINE_GOOGLE_API_KEY`. Paste the key you got from Google AI Studio.
6.  Click **Apply**.

Render will now deploy 3 services for you:
1.  `tourguard-backend` (Main API)
2.  `admin-backend` (Admin API)
3.  `ml-engine` (AI Service)

## Step 3: Get Your URLs

Once deployed (green "Live" status), you will get 3 URLs. They will look like:
- `https://tourguard-backend-xyz.onrender.com`
- `https://admin-backend-xyz.onrender.com`
- `https://ml-engine-xyz.onrender.com`

**Copy these URLs.**

## Step 4: Update Frontend Apps

You need to tell your Flutter App and Admin Panel to use these new URLs instead of your local IP.

### Flutter App (`lib/core/api_constants.dart` or similar)
Replace `http://192.168.x.x:3000` with `https://tourguard-backend-xyz.onrender.com`.

### Admin Frontend (`admin_pannel/frontend/.env` or config)
Replace the backend URL with `https://admin-backend-xyz.onrender.com`.

## Important Notes on Free Tier
- **Spin Down**: Free web services verify "spin down" after 15 minutes of inactivity. The first request after a break might take 30-50 seconds to load.
- **Database Reset**: Since we are using SQLite files in a container, **your database will reset every time the server restarts or deploys**. For a student demo, this is fine. For a real product, you would need a cloud database (like Render PostgreSQL).
