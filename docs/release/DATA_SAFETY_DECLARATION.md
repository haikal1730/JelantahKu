# JelantahKu — Data Safety Declaration (draft untuk Play Console)

Dokumen ini adalah draft berdasarkan implementasi aplikasi yang diperiksa. Nilai akhir pada Google Play Console harus disesuaikan dengan konfigurasi deployment aktual.

## Data yang diproses

- **Email** — digunakan untuk autentikasi akun Supabase.
- **Nama pengguna** — digunakan untuk profil pengguna dan tampilan aplikasi.
- **Village/desa** — dapat disimpan sebagai bagian profil pengguna bila digunakan.
- **Data transaksi minyak jelantah** — ID tabung, berat, harga/kg, total nilai, tipe dan status transaksi.
- **Data pembayaran** — order ID, nominal, status pembayaran, fraud status, provider, waktu pembayaran, dan response gateway yang relevan.
- **Token notifikasi FCM** — disimpan untuk mengaitkan perangkat pengguna dengan layanan push notification.
- **Data permintaan pickup** — lokasi operasional, kapasitas/isi tabung, status, jadwal, catatan, dan user pembuat.

## Tujuan

- Account management/authentication.
- Menyimpan dan menampilkan saldo serta riwayat transaksi.
- Memproses dan mencatat pembayaran Premium melalui Midtrans.
- Mengirim push notification.
- Mengelola operasional pickup minyak jelantah.

## Sharing pihak ketiga

- **Supabase**: authentication dan cloud database.
- **Midtrans**: payment gateway untuk transaksi subscription.
- **Firebase Cloud Messaging**: push notification.

## Keamanan

Row Level Security (RLS) digunakan pada tabel pengguna/transaksi yang relevan. Credential privileged backend tidak boleh dimasukkan ke aplikasi client.

## Catatan Play Console

Jawaban final mengenai apakah data tertentu “collected”, “shared”, “encrypted in transit”, atau “deletion available” harus dipilih di Play Console sesuai deployment produksi yang benar-benar digunakan.
