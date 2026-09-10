# Fitur Pengambilan Minyak

## Alur
1. Sensor tabung mencapai >= 80%.
2. Admin Desa membuka kartu tabung dan memilih **Buat Pengambilan**.
3. Status menjadi **Menunggu Pengambilan**.
4. Admin Desa memilih **Jadwalkan Pengambilan**.
5. Petugas lapangan mengambil minyak secara fisik. Petugas ini bukan role login baru.
6. Admin Desa memilih **Sudah Diambil**.
7. Status menjadi **Selesai** dan simulasi UI mengosongkan tabung menjadi 0%.

Role aplikasi tetap 3: Warga, Admin Desa, Owner.

## Supabase
Jalankan migration:
`supabase/migrations/202609100002_pickup_requests.sql`

Migration membuat tabel `pickup_requests`, RLS, dan Realtime untuk antrean pengambilan.
