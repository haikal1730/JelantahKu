# JelantahKu — Balance Fix

Masalah yang diperbaiki:
- transaksi sukses bisa tercatat tetapi `profiles.balance` tetap 0;
- saldo sekarang direkonsiliasi dari ledger `transactions` yang berstatus `success`;
- transaksi yang sama tetap idempotent dan tidak dikreditkan dua kali;
- transaksi baru gagal dengan jelas jika profile user tidak ditemukan.

## Wajib dilakukan sekali di Supabase

Buka **SQL Editor** pada project Supabase yang dipakai JelantahKu, lalu jalankan isi file:

`supabase/migrations/202609100003_balance_repair.sql`

Migration ini juga melakukan **backfill saldo existing**. Jadi transaksi Rp40.000 yang sudah terlihat di aplikasi akan dihitung menjadi saldo Rp40.000 (dikurangi withdrawal sukses jika ada).

Setelah SQL sukses:
1. Restart Flutter/Web (`flutter run -d chrome` atau hot restart).
2. Login ulang bila perlu.
3. Refresh halaman.
4. Saldo Warga harus mengikuti total transaksi sukses.

## Catatan

Saldo tidak lagi boleh diedit langsung oleh client. Sumber perhitungan adalah ledger transaksi sukses, sedangkan `profiles.balance` disinkronkan secara atomik.
