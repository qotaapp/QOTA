# Configuration native requise

Ce projet contient uniquement le code Dart (`lib/`). Une fois `flutter create .`
exécuté pour générer les dossiers `android/` et `ios/` (ou après `flutter pub get`
sur un projet déjà scaffoldé), ajouter les permissions suivantes :

## Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Qota a besoin de l'appareil photo pour ajouter des images et scanner les QR Code de transfert.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Qota a besoin d'accéder à vos photos pour illustrer vos publications.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Qota utilise votre position pour améliorer la pertinence du Feed (§10).</string>
```

## Pourquoi ces permissions

- **Caméra** : `image_picker` (photos de Service/User Item/Rating/Commentaire) et `mobile_scanner` (scan QR Code Qota Coin, §3).
- **Localisation** : `geolocator`, utilisé par l'algorithme du Feed (§10) pour le critère de proximité géographique — **toujours optionnel**, l'app fonctionne sans (score de proximité neutre).
- **Internet** : requis par Supabase (Auth, base de données, storage).

Sans ces déclarations, l'app plantera silencieusement ou l'OS refusera
l'accès au premier appel (photo, scan, position).
