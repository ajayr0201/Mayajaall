# Mayajaall App - Pura Setup

## 1. GitHub Repositories

| Repo | Kaam | URL |
|------|------|-----|
| Mayajaall | Flutter app ka code | github.com/ajayr0201/Mayajaall |
| live-score-website | Vercel website ka code | github.com/ajayr0201/live-score-website |

## 2. Supabase Details

- **Project ID**: `[PRIVATE]`
- **Project URL**: `[PRIVATE]`
- **Publishable Key**: `[PRIVATE]`
- **Auth Provider**: Google (enabled)
- **Google Client ID (Supabase mein)**: `[PRIVATE]`
- **Google Client Secret**: `[PRIVATE]`

> **Note:** Saare secrets private rakho. Google Keep, Notepad, ya WhatsApp mein save karo.

## 3. Google Cloud Console

- **Project Name**: Mayajaall
- **Package Name**: `com.example.mayajaall`
- **GitHub Actions SHA-1**: `[GITHUB_ACTIONS_SE_SHA1]`
- **Web Client ID**: `[PRIVATE]`

**Google Cloud mein 2 Client IDs hain:**
1. Mayajaall Web (Web application type)
2. Mayajaall Android Debug (Android type, SHA-1 ke saath)

## 4. Vercel Details

- **Vercel URL**: `live-score-website-alpha.vercel.app`
- **Environment Variables**: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## 5. Telegram Details

- **Bot Username**: `@Mayajaalfilebot`
- **Bot Link**: `https://t.me/Mayajaalfilebot`
- **Bot Admin Rights**: Post, Edit, Delete Messages
- **Channel**: Filmy Pulse Ullu Kooku

## 6. App Package Details

- **App Name**: Mayajaall
- **Package Name**: `com.example.mayajaall`
- **Deep Link Domain**: `live-score-website-alpha.vercel.app`
- **Custom Scheme**: `mayajaall://`
- **Flutter Version**: 3.19.6

## 7. Fingerprints

| Type | Value | Kahan Use |
|------|-------|-----------|
| SHA-1 | `[GITHUB_ACTIONS_SE_SHA1]` | Google Sign-In |
| SHA-256 | `[GITHUB_ACTIONS_SE_SHA256]` | Deep Link |

> **Note:** Jab bhi nayi APK build karoge, fingerprint badal sakta hai. Us waqt dono jagah update karna padega.

## 8. APK Download Link
