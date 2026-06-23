# ConFlow — Builder Platform

All-in-one web platform for Christchurch builders. Currently a single-file HTML app with full client-side persistence, ready to migrate to Next.js + Supabase.

---

## What's in this repo

```
ConFlow/
├── index.html          ← The entire current app (Tailwind CDN + vanilla JS)
├── ConFlow-Wordmark.png
├── ConFlow-Logomark.png
├── supabase/
│   └── schema.sql      ← Full DB schema for the Next.js migration
└── README.md
```

---

## Running locally right now

No build step needed. Just open `index.html` in a browser.

Demo login: `demo@conflow.co.nz` / `1234`  
Beta code:   `CF26#`

---

## Uploading to GitHub

### First time setup

1. Create a new **private** repo on GitHub — name it `conflow`
2. Open Terminal and run:

```bash
cd ~/Desktop/ConFlow
git init
git add .
git commit -m "initial: ConFlow HTML app + Supabase schema"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/conflow.git
git push -u origin main
```

### Updating after changes

```bash
cd ~/Desktop/ConFlow
git add .
git commit -m "describe what you changed"
git push
```

---

## Supabase Setup (Free Tier)

### Step 1 — Create project

1. Go to [supabase.com](https://supabase.com) → **Start your project** → Sign in with GitHub
2. Click **New project**
3. Name: `conflow` | Database password: save this somewhere safe | Region: **Sydney** (closest to NZ)
4. Click **Create new project** — takes ~2 minutes to spin up

### Step 2 — Run the schema

1. In your Supabase project, go to **SQL Editor** → **New query**
2. Open `supabase/schema.sql` from this repo
3. Paste the entire contents into the editor
4. Click **Run** (top right)
5. You should see "Success. No rows returned." — that means all tables were created

### Step 3 — Get your API keys

1. Go to **Settings** → **API** in your Supabase project
2. Copy these two values (you'll need them when building the Next.js version):
   - `Project URL` (looks like `https://xxxx.supabase.co`)
   - `anon/public` key (long string starting with `eyJ...`)

### Step 4 — Enable email auth

1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled (it is by default)
3. For now, turn **off** "Confirm email" so users can sign in immediately after signup (you can turn this on later)

### Step 5 — Create Storage bucket (for compliance docs)

1. Go to **Storage** → **New bucket**
2. Name: `documents` | Toggle: **Private**
3. Click **Create bucket**

---

## Planned Tech Stack (Next.js migration)

| Layer | Tool | Why |
|-------|------|-----|
| Frontend | Next.js 14 (App Router) | SSR, file routing, great DX |
| Styling | Tailwind CSS (via npm) | Full CDN + custom config |
| Backend / Auth | Supabase | Postgres + Auth + Storage + Realtime |
| Hosting | Vercel | Free tier, auto-deploys from GitHub |
| Domain | GoDaddy → point to Vercel | Buy `conflow.co.nz` |
| Mobile (later) | Capacitor | Wrap Next.js app as native iOS/Android |

### Migration order (when ready)

1. Set up Next.js project with Supabase auth
2. Mirror current HTML sections as Next.js pages/components
3. Replace localStorage calls with Supabase queries
4. Deploy to Vercel + connect GoDaddy domain
5. Test with beta users
6. Capacitor iOS build → App Store submission

---

## Current data persistence (HTML version)

All user data is saved in `localStorage` under the key `cf-data-[email]` and auto-saved every 3 seconds when changes are detected. Data persists across logins for the same browser/device.

Data saved per user:
- Projects & project counter
- Quotes & quote counter  
- Crew members
- Variations & var counter
- Invoices & invoice counters
- Compliance documents
- Chat messages

The Supabase schema in `supabase/schema.sql` maps directly to these data structures for a clean migration.
