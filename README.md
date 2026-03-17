# GoPublic

GoPublic adalah tool untuk mempublikasikan proyek lokal kamu.

README ini ditujukan untuk user publik yang memakai binary hasil release GoPublic di Linux Debian/Ubuntu.

## Fungsi

GoPublic membantu Anda:

- mempublikasikan proyek lokal melalui Nginx dan Cloudflare Tunnel
- mengelola workflow `init -> add -> commit -> push`
- mengatur status config Nginx
- memeriksa kesehatan domain yang sudah dipublish
- mengelola deploy proyek multi-stack dari satu CLI

## Sistem yang Didukung

- Debian
- Ubuntu

GoPublic juga bisa berjalan di Linux lain, tetapi workflow dan dependency sistem paling aman dipakai di Debian/Ubuntu.

## Kebutuhan Sistem

Sebelum memakai GoPublic, pastikan mesin Anda memiliki:

- `nginx`
- `cloudflared`
- `systemd`
- `sudo`
- koneksi internet untuk login Cloudflare

Jika Anda memakai stack tertentu, runtime aplikasinya juga harus tersedia:

- PHP/Laravel: `php-fpm`
- Node.js: `node` dan `npm`
- Go: `go`
- Python: interpreter Python dan dependency aplikasi Anda

## Cara Menjalankan Binary

Misalnya file release Anda bernama:

```bash
gopublic-linux-amd64-v0.1.1
```

Jalankan langkah berikut:

```bash
chmod +x gopublic-linux-amd64-v0.1.1
./gopublic-linux-amd64-v0.1.1
```

Jika ingin dipakai seperti command biasa:

```bash
chmod +x gopublic-linux-amd64-v0.1.1
mv gopublic-linux-amd64-v0.1.1 ~/bin/gopublic
source ~/.bashrc
gopublic
```

Atau install secara global:

```bash
sudo install -m 755 gopublic-linux-amd64-v0.1.1 /usr/local/bin/gopublic
gopublic
```

## Verifikasi File Release

Jika file checksum tersedia:

```bash
sha256sum -c gopublic-linux-amd64-v0.1.1.sha256
```

Pastikan hasilnya valid sebelum binary dipakai.

## Quick Start

### 1. Lihat overview aplikasi

```bash
gopublic
```

### 2. Lihat daftar perintah

```bash
gopublic menu
```

### 3. Inisialisasi proyek

Jalankan dari root proyek:

```bash
gopublic init
```

Perintah ini membuat file `.gopublic.json`.

### 4. Tambahkan subdomain

```bash
gopublic add app
```

Perintah ini akan membuka login Cloudflare dan meminta Anda memilih base domain.

### 5. Simpan catatan lokal

```bash
gopublic commit "setup awal"
```

Langkah ini opsional.

### 6. Push proyek

```bash
gopublic push
```

Perintah ini akan:

- mendeteksi runtime proyek
- menjalankan build/start jika perlu
- menyiapkan Cloudflare Tunnel
- menulis route DNS
- membuat config Nginx

## Mode Interaktif

Untuk memakai dashboard interaktif:

```bash
gopublic ben
```

Mode ini menyediakan menu untuk:

- audit konfigurasi
- update proyek
- ubah status enabled/disabled
- edit config
- hapus target
- health check
- refresh Nginx
- restart Cloudflare

## Perintah Utama

- `gopublic`  
  Menampilkan overview aplikasi

- `gopublic menu`  
  Menampilkan daftar perintah

- `gopublic ben`  
  Menjalankan mode interaktif

- `gopublic init`  
  Membuat `.gopublic.json`

- `gopublic add <subdomain>`  
  Menambahkan target domain

- `gopublic commit [catatan]`  
  Menyimpan catatan lokal

- `gopublic push`  
  Menjalankan deploy proyek

- `gopublic check`  
  Menampilkan daftar config Nginx

- `gopublic update <target>`  
  Mengubah konfigurasi proyek

- `gopublic status <target>`  
  Mengubah status config

- `gopublic edit-config <target>`  
  Membuka config di editor

- `gopublic remove <target>`  
  Menghapus target

- `gopublic refresh-nginx`  
  Test dan reload Nginx

- `gopublic refresh-cloudflare`  
  Restart `cloudflared`

## Runtime yang Didukung

GoPublic saat ini mengenali:

- PHP / Laravel
- Node.js
- Go
- Django
- FastAPI / Starlette
- Flask

Jika runtime tidak terdeteksi otomatis, GoPublic akan fallback ke mode proxy manual.

## Lokasi Data Binary

Saat dipakai dalam mode binary, registry global GoPublic disimpan di:

```bash
~/.config/gopublic/projects.json
```

Sedangkan metadata proyek lokal tetap berada di file:

```bash
.gopublic.json
```

## Troubleshooting

### Domain tidak resolve

Periksa:

- zona Cloudflare yang dipilih saat `gopublic add`
- login Cloudflare yang aktif
- route DNS target

### Cloudflare Tunnel error 1033

Periksa:

```bash
systemctl status cloudflared --no-pager
journalctl -u cloudflared -n 50 --no-pager
```

Lalu coba:

```bash
gopublic refresh-cloudflare
gopublic push
```

### Config Nginx tidak aktif

Periksa:

```bash
nginx -t
gopublic refresh-nginx
```

### Runtime aplikasi tidak hidup

Pastikan runtime bahasa dan dependency proyek Anda memang sudah tersedia di server.

