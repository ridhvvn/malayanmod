# Supabase + Flutter

A Flutter web app with Supabase backend, deployed via GitHub Actions to GitHub Pages.

## Quick Start

### 1. Clone & Install

```bash
flutter pub get
```

### 2. Configure Supabase

Copy the example env file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your Supabase project URL and anon key (found in your [Supabase Dashboard](https://supabase.com/dashboard) → Settings → API):

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Run Locally

```bash
flutter run -d chrome
```

## CI/CD — GitHub Pages Deployment

The project includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) that automatically builds and deploys to GitHub Pages on every push to `main`.

### Setup

1. **Enable GitHub Pages** in your repo: Settings → Pages → Source → **GitHub Actions**
2. **Add secrets** to your repo: Settings → Secrets and variables → Actions → New repository secret
   - `SUPABASE_URL` — your Supabase project URL
   - `SUPABASE_ANON_KEY` — your Supabase anon/public key
3. **Push to `main`** — the workflow will build and deploy automatically

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart   # Supabase initialization & client access
├── pages/
│   └── home_page.dart         # Main dashboard with connection test
├── theme/
│   └── app_theme.dart         # App-wide colors, gradients, theme
└── main.dart                  # Entry point
```

## Tech Stack

- **Flutter** (web)
- **Supabase** (BaaS — auth, database, storage)
- **GitHub Actions** (CI/CD)
- **GitHub Pages** (hosting)
