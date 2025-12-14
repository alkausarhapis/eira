# Eira 🎯

Aplikasi produktivitas berbasis Flutter yang membantu kamu menyelesaikan tugas dengan mudah menggunakan sistem micro-task dan AI.

## ✨ Fitur Utama

### 🤖 AI Micro-Task Generator

- Ubah target besar jadi langkah-langkah kecil yang mudah dikerjakan
- Powered by Google Gemini AI
- Otomatis dipecah jadi 3-7 micro-task yang logis dan berurutan

### ⏱️ Focus Mode

- Blokir semua distraksi dengan overlay layar penuh
- Timer otomatis mencatat durasi fokus
- Notifikasi dan aplikasi lain tersembunyi

### 🚫 Block Apps

- Blokir aplikasi yang mengganggu produktivitas
- Atur durasi pemblokiran
- Material Design 3 blocking overlay

### 📊 Session Tracking

- Timer otomatis untuk setiap micro-task
- Rest time di antara task
- Tracking waktu total penyelesaian
- Progress tersimpan otomatis

## 🛠️ Teknologi

- **Flutter/Dart** - UI Framework
- **Kotlin** - Native Android (AccessibilityService, System Overlay)
- **Google Gemini Flash 2.5** - AI untuk generate micro-task
- **sqflite** - Database lokal
- **Provider** - State management

## 📦 Instalasi

### Prasyarat

- Flutter SDK (latest stable)
- Android SDK
- Git

### Clone Repository

```bash
git clone <repository-url>
cd eira
```

### Setup API Key

1. Buat file `.env` di root project
2. Tambahkan Gemini API key:

```env
GEMINI_API_KEY=your_api_key_here
```

3. Dapatkan API key dari: https://makersuite.google.com/app/apikey

### Install Dependencies

```bash
flutter pub get
```

### Run Aplikasi

```bash
flutter run
```

## 🎮 Cara Menggunakan

> APK: https://drive.google.com/drive/folders/1Hz883o5KNqn5RRa6y2fUpAhQpoQrPw9B?usp=sharing

### 1. Generate Micro-task

- Tulis target yang ingin diselesaikan di kolom input
- Tekan tombol "Generate Micro-tasks"
- AI akan memecahnya jadi langkah-langkah kecil

### 2. Mulai Session

- Tap card micro-task
- Tekan tombol "Mulai"
- Ikuti setiap langkah dengan timer dan rest time otomatis

### 3. Aktifkan Permissions

Buka **Settings** dan aktifkan:

- ✅ **Tampilkan di Atas Aplikasi Lain** - untuk overlay
- ✅ **Aksesibilitas** - untuk deteksi aplikasi (Android 14+ harap berikan izin "allow restricted setting" agar bisa mengaktifkan accessibility)
- ✅ **Statistik Penggunaan** - untuk tracking

### 4. Block Apps

- Buka tab "Blocked Apps"
- Pilih aplikasi yang ingin diblokir
- Atur durasi pemblokiran
- Aplikasi akan otomatis terblokir dengan overlay

### 5. Focus Mode

- Tekan FAB (tombol bulat ungu) di home
- Konfirmasi untuk mulai fokus
- Layar akan tertutup overlay hitam dengan timer
- Tekan "Hentikan Fokus" untuk keluar
