# Eira - Flutter Microtask App

## 📁 Struktur Folder

```
lib/
├── models/
│   └── microtask_model.dart          # Data models untuk microtask
├── viewmodels/
│   ├── microtask_viewmodel.dart      # Business logic untuk microtasks
│   └── theme_viewmodel.dart          # Business logic untuk theme
├── views/
│   ├── home_page.dart                # Halaman utama dengan microtasks
│   ├── blocked_apps_page.dart        # Halaman blokir aplikasi (placeholder)
│   └── settings_page.dart            # Halaman pengaturan
├── widgets/
│   ├── active_session_widget.dart    # Widget untuk sesi aktif
│   ├── logo_widget.dart              # Widget logo Eira
│   ├── microtask_card.dart           # Card accordion untuk microtask
│   └── primary_button.dart           # Button utama reusable
├── theme/
│   └── app_theme.dart                # Konfigurasi light/dark theme
└── main.dart                         # Entry point dengan navigation
```

## 🎨 Design System

- **Primary Color**: #9747FF (Purple)
- **Background Light**: #FFFFFF (White)
- **Background Dark**: #000000 (Black)
- **Style**: Flat, minimalist, rounded corners (12-20px)
- **Language**: Bahasa Indonesia

## 🏗️ Architecture: MVVM + Provider

### Models

- `MicroTaskModel`: Menyimpan data target dan daftar microtasks
- `MicroTaskItem`: Item individual dalam microtask

### ViewModels

- `MicrotaskViewModel`:
  - Mengelola daftar microtasks
  - Start/pause/complete session
  - Timer management
  - Rest timer (30-60 detik)
  - Hanya 1 sesi aktif dalam satu waktu
- `ThemeViewModel`:
  - Toggle light/dark mode
  - Menyimpan preferensi di SharedPreferences

### Views

- `HomePage`: Input prompt, generate microtasks, list accordion, active session
- `BlockedAppsPage`: Placeholder untuk fitur blokir aplikasi
- `SettingsPage`: Theme toggle, limits, about section

## ⚙️ Fitur Utama

### Home Page

1. **Prompt Section**: User input target yang ingin diselesaikan
2. **Generate Button**: Generate microtasks (mock saat ini)
3. **Active Session**: Tampil saat ada sesi berjalan
   - Current task
   - Timer (jam:menit:detik)
   - Pause/Resume button
   - Complete button → trigger rest timer
4. **Microtask List**: Accordion cards dengan:
   - Emoji icon
   - Judul target
   - Progress counter
   - Expandable list microtasks
   - Tombol "Mulai" (hanya jika tidak ada sesi aktif)

### Logic Penting

- Hanya 1 sesi dapat aktif
- Setelah complete microtask → rest timer 30-60 detik
- Timer berjalan terus kecuali di-pause
- Status: pending → in-progress → done

## 🧩 Reusable Components

- `LogoWidget`: Logo Eira dengan gradient
- `PrimaryButton`: Button dengan icon dan loading state
- `MicrotaskCard`: Accordion card untuk microtask
- `ActiveSessionWidget`: Display sesi aktif dengan timer

## 🚀 Running the App

```bash
flutter pub get
flutter run
```

## 📱 Navigation

Bottom Navigation Bar dengan 3 tabs:

- Home
- Blokir Aplikasi
- Pengaturan

## 🔮 Next Steps (Future Implementation)

1. Integrasi AI API untuk generate microtasks
2. Implementasi native accessibility service untuk blokir apps
3. Persistent storage untuk microtasks (SQLite/Hive)
4. Notifikasi dan reminders
5. Analytics dan progress tracking
6. Customizable rest duration

## 🎯 Current State

✅ MVVM architecture dengan Provider
✅ Light/Dark theme dengan toggle
✅ 3 halaman lengkap dengan UI
✅ Session management dengan timer
✅ Rest timer setelah complete task
✅ Accordion cards untuk microtasks
✅ Reusable components
✅ Mock data untuk testing
