# 💝 Sevgi Albümü 📱

Sevgi Albümü, sevdiklerinizle olan özel anılarınızı dijital ortamda saklamanızı ve düzenlemenizi sağlayan modern bir Flutter uygulamasıdır.

![Flutter Version](https://img.shields.io/badge/Flutter-3.6.0-blue)
![Dart Version](https://img.shields.io/badge/Dart-3.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-1.0.2-orange)

## 📲 APK İndirme Bağlantısı

Uygulamayı Android cihazınıza yüklemek için aşağıdaki bağlantıyı kullanabilirsiniz:

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://drive.google.com/file/d/1HdhPxOLa9FG2s_3Mv0ZxK5LuXMWuKDMB/view?usp=sharing)

### Kurulum Adımları
1. APK dosyasını indirin
2. Android cihazınızda "Bilinmeyen kaynaklar"dan yüklemeye izin verin
3. İndirilen APK dosyasını açın ve yükleyin
4. Uygulamayı başlatın ve anılarınızı kaydetmeye başlayın!

## ✨ Özellikler

- 📸 Fotoğraf ekleme ve düzenleme
- 📅 Takvim görünümü ile anıları tarihe göre görüntüleme
- 💾 SQLite veritabanı ile yerel depolama
- 🎥 Özel açılış videosu
- 🌈 Modern ve kullanıcı dostu arayüz
- 💫 Akıcı animasyonlar
- 📱 Responsive tasarım
- 🇹🇷 Türkçe dil desteği

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (^3.6.0)
- Dart SDK (^3.0.0)
- Android Studio veya VS Code
- Git

### Adım Adım Kurulum

1. **Flutter'ı Yükleyin**
   ```bash
   # Flutter SDK'yı indirin ve kurun
   https://flutter.dev/docs/get-started/install
   ```

2. **Projeyi Klonlayın**
   ```bash
   # Projeyi klonlayın
   git clone https://github.com/kerimayvaz77/Sevgi_Albumu.git
   
   # Proje dizinine gidin
   cd Sevgi_Albumu
   ```

3. **Bağımlılıkları Yükleyin**
   ```bash
   # Gerekli paketleri yükleyin
   flutter pub get
   ```

4. **Uygulamayı Çalıştırın**
   ```bash
   # Debug modunda çalıştırın
   flutter run
   
   # Release APK oluşturun
   flutter build apk --release
   ```

## 📦 Kullanılan Paketler

- 🖼️ `image_picker`: Fotoğraf seçimi ve kamera erişimi
- 🎥 `video_player`: Video oynatma işlemleri
- 📅 `table_calendar`: Takvim görünümü
- 💾 `sqflite`: Yerel veritabanı yönetimi
- 🎨 `google_fonts`: Özel yazı tipleri
- 🔄 `cached_network_image`: Görsel önbellekleme
- 🆔 `uuid`: Benzersiz ID oluşturma
- 🌍 `intl`: Yerelleştirme desteği

## 🛠️ Proje Yapısı

```
lib/
├── main.dart           # Ana uygulama girişi
├── app.dart            # Uygulama yapılandırması
├── screens/           # Ekran widget'ları
│   ├── splash_screen.dart
│   └── my_home_page.dart
├── models/            # Veri modelleri
│   └── album_entry.dart
├── services/          # Servisler
│   └── database_service.dart
└── routes/           # Sayfa yönlendirmeleri
```

## 📱 Ekran Görüntüleri

[Ekran görüntülerini buraya ekleyin]

## 🤝 Katkıda Bulunma

1. Bu depoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/amazing`)
3. Değişikliklerinizi commit edin (`git commit -m 'Harika özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/amazing`)
5. Bir Pull Request oluşturun

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için `LICENSE` dosyasına bakın.

## 📞 İletişim

Kerim Ayvaz - [kerimayvaz7@gmail.com](mailto:kerimayvaz7@gmail.com)

---
⭐️ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
