# 8steps_mobile

MVP offline-first de finanzas personales en Flutter con Riverpod + Drift.

## 1) Crear proyecto base Flutter (si aún no tienes ios/android)

```bash
cd 8steps_mobile
flutter create . --platforms=android,ios
```

## 2) Dependencias

```bash
flutter pub get
```

## 3) Generar código Drift

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 4) Ejecutar

Android:

```bash
flutter run -d android
```

iOS:

```bash
flutter run -d ios
```

## Arquitectura

- `lib/app`: app, router y providers globales
- `lib/core`: utilidades y formatters
- `lib/data/local`: base Drift + tablas + DAOs
- `lib/data/repositories`: repositorio de finanzas
- `lib/features/auth`: onboarding/login/register con `AuthRepository` mock
- `lib/features/finance`: dashboard, transacciones, fijos, cuotas, proyecciones

## Notas

- Persistencia local con SQLite (Drift).
- Montos almacenados como centavos (`int`) para evitar errores de precisión.
- Categorías por defecto se insertan en el primer arranque.
- Endpoints futuros de auth ya están anotados en `MockAuthRepository`.
