# Chest X-Ray Görüntülerinde Histogram Tabanlı Kontrast İyileştirme ve Pneumonia Tespiti

Bu proje, akciğer röntgeni (Chest X-Ray) görüntülerinde kontrast iyileştirme yöntemlerinin etkisini incelemek ve bu iyileştirmenin derin öğrenme tabanlı pneumonia (zatürre) tespitine katkısını analiz etmek amacıyla geliştirilmiştir. Sistem, uçtan uca bir mimari ile mobil istemci ve sunucu tarafını birlikte ele almaktadır.

## Projenin Amacı

Tıbbi X-Ray görüntülerinde sıkça karşılaşılan düşük kontrast problemi, hem radyolog yorumlarını hem de yapay zeka tabanlı analizleri olumsuz etkilemektedir. Bu çalışmada:

* Histogram Equalization ve CLAHE yöntemleri uygulanmıştır
* Görüntü kalitesi PSNR ve SSIM metrikleri ile ölçülmüştür
* Kontrast iyileştirmenin pneumonia sınıflandırma performansına etkisi değerlendirilmiştir

## Sistem Mimarisi

Proje istemci–sunucu mimarisi ile tasarlanmıştır.

* Mobil Uygulama: Flutter
* Backend API: Python (Flask)
* Görüntü İşleme: OpenCV, NumPy
* Yapay Zeka Modeli: TensorFlow / Keras
* Dağıtım: PythonAnywhere

Genel akış:

1. Kullanıcı X-Ray görüntüsünü seçer
2. Görüntü backend servisine gönderilir
3. Histogram Equalization ve CLAHE uygulanır
4. PSNR ve SSIM hesaplanır
5. TFLite model ile pneumonia tahmini yapılır
6. Sonuçlar mobil uygulamada karşılaştırmalı sunulur

## Kullanılan Yöntemler

### Histogram Equalization

Görüntünün global histogramını yeniden dağıtarak kontrastı artıran klasik bir yöntemdir. Düşük kontrastlı bölgelerde detayları belirginleştirir ancak bazı durumlarda aşırı kontrasta yol açabilir.

### CLAHE

Adaptif histogram eşitleme yöntemidir. Görüntüyü küçük parçalara ayırarak yerel kontrast artırımı yapar ve clip limit sayesinde gürültü artışını sınırlar. Tıbbi görüntüler için daha dengeli sonuçlar üretir.

### Görüntü Kalite Metrikleri

* PSNR: Orijinal ve işlenmiş görüntü arasındaki bozulmayı ölçer
* SSIM: Yapısal benzerliği ölçerek insan görme sistemine daha yakın sonuçlar sunar

## Yapay Zeka Modeli

* Önceden eğitilmiş MobileNetV2 kullanılmıştır
* Transfer learning yaklaşımı uygulanmıştır
* Binary sınıflandırma (Normal / Pneumonia)
* Model, TensorFlow Lite formatına dönüştürülerek backend üzerinde çalıştırılmıştır

## Repository Yapısı

```text
project-root/
│
├── backend/
│   ├── main.py                  # Flask API ve ana sunucu kodu
│   ├── image_processing.py      # Histogram ve CLAHE fonksiyonları
│   ├── model.tflite             # TFLite pneumonia modeli
│   ├── requirements.txt         # Backend bağımlılıkları
│
├── model_training/
│   ├── train_model.py           # Derin öğrenme modelinin eğitimi
│   ├── convert_to_tflite.py     # Keras -> TFLite dönüşümü
│
├── mobile_app/
│   ├── lib/main.dart             # Flutter mobil uygulama
│   ├── pubspec.yaml
│
├── README.md
```

## Kurulum

### Backend

```bash
pip install -r requirements.txt
python main.py
```

### Flutter

```bash
flutter pub get
flutter run
```

## Veri Seti

Chest X-Ray Images (Pneumonia) veri seti kullanılmıştır.

* Kaynak: Kaggle
* Sınıflar: Normal, Pneumonia
* Gri seviye X-Ray görüntüler

## Deneysel Sonuçlar

Elde edilen PSNR ve SSIM değerleri, CLAHE yönteminin klasik histogram eşitlemeye kıyasla daha dengeli ve yapısal olarak tutarlı sonuçlar verdiğini göstermektedir. Ayrıca kontrast iyileştirmenin pneumonia tespit doğruluğunu olumlu yönde etkilediği gözlemlenmiştir.

## Gelecek Çalışmalar

* Farklı kontrast iyileştirme tekniklerinin denenmesi
* Daha gelişmiş kalite metriklerinin eklenmesi
* Çok sınıflı akciğer hastalığı tespiti
* Model performans optimizasyonu

## Lisans

Bu proje akademik amaçlı geliştirilmiştir. Veri seti ve kullanılan kütüphaneler kendi lisans koşullarına tabidir.
