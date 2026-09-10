# Email validation fix

- Accepts valid domains such as `@warga.com`, `@gmail.com`, `@jelantahku.com`, etc.
- Email is trimmed before Supabase sign-in/register.
- Supabase Auth remains the source of truth.
- Roles remain exactly: warga, admin, owner.
