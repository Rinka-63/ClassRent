# Midtrans Configuration

This project is prepared for Midtrans, but real keys must not be committed.

## Flutter environment

Copy `.env.example` to `.env`, then fill only public client-side values:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
MIDTRANS_CLIENT_KEY=YOUR_CLIENT_KEY
```

`MIDTRANS_CLIENT_KEY` may be read by Flutter through `flutter_dotenv`.

Never add this value to Flutter:

```env
MIDTRANS_SERVER_KEY=YOUR_SERVER_KEY
```

The server key must stay server-side because it can create and manage transactions.

## Supabase Edge Function environment

Use `supabase/.env.example` as the template for Edge Function secrets:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY
MIDTRANS_SERVER_KEY=YOUR_SERVER_KEY
MIDTRANS_CLIENT_KEY=YOUR_CLIENT_KEY
MIDTRANS_IS_PRODUCTION=false
```

Set these as Supabase secrets before deploying Edge Functions. The future Midtrans create-transaction and webhook functions should read `MIDTRANS_SERVER_KEY` only from the Edge Function environment.

## Key placement rule

- Flutter: `MIDTRANS_CLIENT_KEY` only.
- Supabase Edge Functions: `MIDTRANS_SERVER_KEY` and backend-only service credentials.
- Git repository: placeholder examples only, no real keys.
