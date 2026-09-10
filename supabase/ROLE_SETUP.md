# JelantahKu — setup role admin/owner

`profiles.role` adalah sumber kebenaran role aplikasi. Registrasi publik selalu mulai sebagai `warga`.

Setelah akun admin/owner dibuat melalui Supabase Auth, buka **Supabase Dashboard → SQL Editor** dan jalankan query berikut dengan email akun yang tepat:

```sql
-- Admin Desa
update public.profiles
set role = 'admin'
where email = 'admin@contoh.com';

-- Owner
update public.profiles
set role = 'owner'
where email = 'owner@contoh.com';
```

Setelah itu logout/login kembali di aplikasi agar role terbaru dibaca dari Supabase.

> Jangan memberikan service-role key ke Flutter. Role admin/owner sebaiknya diberikan hanya oleh operator/backend tepercaya, bukan dari UI registrasi publik.
