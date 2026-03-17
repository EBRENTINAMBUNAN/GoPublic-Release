# GoPublic

GoPublic adalah tool untuk mempublikasikan proyek lokal kamu.

README ini ditujukan untuk user publik yang memakai binary hasil release GoPublic di Linux Debian/Ubuntu. Binary release bersifat mandiri, jadi Anda tidak perlu memasang source code GoPublic atau runtime Python untuk menjalankannya.

## Fungsi

GoPublic membantu Anda:

- mempublikasikan proyek lokal melalui Nginx dan Cloudflare Tunnel
- mengelola workflow `init -> add -> commit -> push`
- mengatur status config Nginx
- memeriksa kesehatan domain yang sudah dipublish
- mengelola deploy proyek multi-stack dari satu CLI

## Sistem yang Didukung

- Debian amd64
- Ubuntu amd64

Distribusi Linux lain mungkin tetap dapat menjalankan binary, tetapi alur instalasi dan dependency sistem resmi release ini ditujukan untuk Debian/Ubuntu.

## Prasyarat Wajib

Sebelum memakai GoPublic, pastikan:

- Anda memakai Linux Debian/Ubuntu 64-bit
- `sudo` tersedia
- koneksi internet tersedia
- Anda memiliki akun Cloudflare
- domain atau zone yang akan dipakai sudah aktif di Cloudflare
- `systemd` tersedia

Jika Anda memakai stack tertentu, runtime aplikasinya juga harus tersedia:

- PHP/Laravel: `php-fpm`
- Node.js: `node` dan `npm`
- Go: `go`
- Python: interpreter Python dan dependency aplikasi Anda

## Isi Folder Release

Secara umum folder release berisi:

- binary release GoPublic
- file checksum SHA-256
- file catatan release `.txt`
- installer publik `install-gopublic.sh`
- uninstaller publik `uninstall-gopublic.sh`

## Instalasi Cepat

Jika Anda memakai release `onefile`, langkah yang disarankan adalah:

```bash
chmod +x install-gopublic.sh uninstall-gopublic.sh
sudo bash ./install-gopublic.sh
gopublic
```

Installer publik akan:

- memasang `nginx`
- memasang `cloudflared`
- memasang binary ke `/usr/local/bin/gopublic`
- mengaktifkan `nginx`

Catatan:

- `cloudflared` dipasang, tetapi baru dipakai penuh saat Anda menjalankan `gopublic add` dan `gopublic push`
- jika ingin hanya memasang binary tanpa dependency sistem, pakai:

```bash
sudo bash ./install-gopublic.sh --binary-only
```

## Instalasi Manual

Jika Anda tidak ingin memakai installer publik, Anda bisa menjalankan binary langsung dari folder release:

```bash
chmod +x ./gopublic-linux-amd64-v<version>
./gopublic-linux-amd64-v<version>
```

Atau pasang manual ke PATH sistem:

```bash
sudo install -m 755 ./gopublic-linux-amd64-v<version> /usr/local/bin/gopublic
gopublic
```

## Verifikasi File Release

Jika file checksum tersedia:

```bash
sha256sum -c gopublic-linux-amd64-v<version>.sha256
```

Pastikan hasilnya `OK` sebelum binary dipakai.

## Langkah Pertama Setelah Binary Berhasil Jalan

1. Lihat overview aplikasi:

```bash
gopublic
```

2. Lihat daftar perintah:

```bash
gopublic menu
```

3. Masuk ke root proyek yang ingin dipublikasikan:

```bash
cd /path/to/project
```

4. Inisialisasi metadata proyek lokal:

```bash
gopublic init
```

5. Tambahkan subdomain:

```bash
gopublic add app
```

6. Push proyek:

```bash
gopublic push
```

## Workflow Utama

### 1. Inisialisasi proyek

Jalankan dari root proyek:

```bash
gopublic init
```

Perintah ini membuat file `.gopublic.json`.

### 2. Tambahkan subdomain

```bash
gopublic add app
```

Perintah ini akan membuka login Cloudflare dan meminta Anda memilih base domain.

### 3. Simpan catatan lokal

```bash
gopublic commit "setup awal"
```

Langkah ini opsional.

### 4. Push proyek

```bash
gopublic push
```

Perintah ini akan:

- mendeteksi runtime proyek
- menjalankan build/start jika perlu
- menyiapkan Cloudflare Tunnel
- menulis route DNS
- membuat config Nginx

## Dashboard Interaktif

Untuk memakai dashboard interaktif:

```bash
gopublic dashboard
```

Alias kompatibilitas lama tetap tersedia:

```bash
gopublic ben
```

Dashboard ini menyediakan menu untuk:

- audit konfigurasi
- update proyek
- ubah status enabled/disabled
- edit config
- hapus target
- health check
- refresh Nginx
- restart Cloudflare

## Perintah Publik Utama

- `gopublic`  
  Menampilkan overview aplikasi dan langkah berikutnya

- `gopublic dashboard`  
  Menjalankan dashboard interaktif

- `gopublic menu`  
  Menampilkan daftar perintah

- `gopublic init`  
  Membuat `.gopublic.json`

- `gopublic add <subdomain>`  
  Menambahkan target domain

- `gopublic commit [catatan]`  
  Menyimpan catatan lokal

- `gopublic push`  
  Menjalankan deploy proyek

## Perintah Operasional

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

## Perintah Manual Lanjutan

- `gopublic new`  
  Workflow manual satu perintah untuk setup Nginx + Cloudflare Tunnel

Perintah ini tetap tersedia, tetapi untuk user baru jalur yang direkomendasikan adalah `init -> add -> commit -> push`.

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

## Uninstall

Untuk mencabut binary dari sistem:

```bash
chmod +x uninstall-gopublic.sh
sudo bash ./uninstall-gopublic.sh
```

Jika Anda juga ingin menghapus `nginx`, `cloudflared`, dan repo Cloudflare yang dipasang oleh installer publik:

```bash
sudo bash ./uninstall-gopublic.sh --purge-system-deps
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
