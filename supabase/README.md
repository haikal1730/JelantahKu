# Supabase setup JelantahKu

1. Create project at https://supabase.com/dashboard.
2. Open SQL Editor and run `migrations/202609090001_jelantahku.sql`.
3. In Authentication > Providers enable Email and Google.
4. For Google, configure Google Cloud OAuth Client ID/secret in Supabase and add the Supabase callback URL shown by the dashboard.
5. Add `io.supabase.jelantahku://login-callback/` to Additional Redirect URLs.
6. In Project Settings > API, copy Project URL and the Publishable Key (safe for Flutter client). Never use `service_role` in Flutter.
7. Run Flutter:

flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

The SQL creates profiles, transactions, payments and notification_tokens, RLS policies, auth profile trigger, atomic/idempotent transaction RPC, and Realtime publication.
