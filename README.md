# Homemade Bliss

Homemade Bliss คือแอปพลิเคชันไมโครคอมเมิร์ซสำหรับร้านขนมโฮมเมด ที่ออกแบบให้ทั้งลูกค้าและเจ้าของร้านสามารถจัดการการซื้อขายได้ครบวงจรในแอปเดียว (Authentication, คำสั่งซื้อ, ชำระเงินออนไลน์, แชท, แจ้งเตือน และแดชบอร์ดบริหารร้าน)

## Table of Contents
- [Overview](#overview)
- [Feature Highlights](#feature-highlights)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Quick Start (Flutter App)](#quick-start-flutter-app)
- [Firebase & Firestore Setup](#firebase--firestore-setup)
- [Payments Backend (Stripe & PromptPay)](#payments-backend-stripe--promptpay)
- [Project Structure](#project-structure)
- [Useful Commands](#useful-commands)
- [Run on Physical Device](#run-on-physical-device)
- [Maintenance Checklist](#maintenance-checklist)
- [Stripe Cloud Functions Workflow](#stripe-cloud-functions-workflow)
- [Resources](#resources)

## Overview
- ลูกค้าเลือกสินค้า จัดการตะกร้า ใช้คูปอง ชำระเงินผ่านบัตรเครดิต (Stripe) พร้อมรับการแจ้งเตือนสถานะต่าง ๆ
- เจ้าของร้านบริหารสินค้า สต็อก คำสั่งซื้อ แชทกับลูกค้า และดูสถิติสรุปบน Owner Dashboard
- ใช้ Firebase ในการจัดการ Auth, Firestore, Storage รวมถึง push/local notifications ผ่าน `flutter_local_notifications`
- รองรับการขยายฟีเจอร์อื่น ๆ (personalization, promotions, storefront) ด้วยโครงสร้างโค้ดแบบ feature-first ภายใต้ `lib/features/*`

## Feature Highlights
- **Customer App**: สมัคร/ล็อกอิน, ค้นหาและดูสินค้าพร้อม variants, เพิ่มลงตะกร้า, คำนวณราคาหลังคูปอง, Checkout, ดูประวัติคำสั่งซื้อ และรับการแจ้งเตือน
- **Owner Dashboard**: สรุปสถิติยอดขาย, จัดการสินค้าและสต็อก, อัปเดตสถานะออเดอร์, สร้างคูปอง, แชทกับลูกค้า และแก้ไขโปรไฟล์ร้าน
- **Real-time Services**: ข้อมูลซิงก์กับ Firestore, สั่งซื้อแล้วตัดสต็อกอัตโนมัติ, ชำระเงินสำเร็จแล้วส่ง Local Notification และนำผู้ใช้ไปหน้า success
- **Extensible Modules**: โครงสร้างแยกตามฟีเจอร์ (cart, chat, notifications, personalization ฯลฯ) ทำให้เพิ่ม/ปรับแต่งได้ง่ายในอนาคต

## Tech Stack
- **Frontend**: Flutter (Material 3 style, Provider + ChangeNotifier, Firebase SDKs)
- **Backend (optional demo)**: Node.js (Express, Stripe SDK, Omise/Opn promptpay ตัวอย่าง), dotenv สำหรับ environment config
- **Cloud**: Firebase Authentication, Cloud Firestore, Firebase Storage
- **Payments**: Stripe (บัตรเครดิต)
- **Notifications**: flutter_local_notifications (แจ้งเตือนในเครื่อง)

## Requirements
- Flutter SDK 3.x (Dart >= 2.17)
- Android Studio หรือ Xcode สำหรับ build native
- Firebase project ที่เปิดใช้งาน Authentication + Firestore + Storage
- Stripe account (test mode) และ Omise/Opn account หากต้องการ PromptPay
- Node.js 18+ (เฉพาะถ้าจะรัน backend ตัวอย่าง `opn_sandbox_backend.js`)

## Quick Start (Flutter App)
1. **Clone**
   ```bash
   git clone https://github.com/<your-org>/homemade_bliss.git
   cd homemade_bliss
   ```
2. **ติดตั้ง package Flutter**
   ```bash
   flutter pub get
   ```
3. **เตรียมไฟล์ Firebase**
   - Android: วาง `google-services.json` ใน `android/app/`
   - iOS/macOS: วาง `GoogleService-Info.plist` ในโฟลเดอร์ Runner และอัปเดต Xcode project
   - ถ้าใช้ FlutterFire CLI ให้รัน `flutterfire configure` แล้วอัปเดต `main.dart` ให้ใช้ค่า `DefaultFirebaseOptions`
4. **ปรับ Stripe Publishable Key** ใน `lib/common/stripe_config.dart`
   - ตั้งค่า `StripeConfig.ensureInitialized()` ให้ชี้ endpoint backend ของคุณ (ค่าเดิมคือ IP เฉพาะสภาพแวดล้อมเดิม)
   - หรือกำหนดคีย์ใน `_fallbackKey` เฉพาะเครื่องทดสอบ
5. **ตั้งค่า assets**
   - รูปภาพอยู่ที่ `assets/images/`
   - ถ้ามีฟอนต์/รูปเพิ่ม ตรวจสอบให้ประกาศใน `pubspec.yaml`
6. **Run แอป**
   ```bash
   flutter run -d <deviceId>
   ```
   - Android Emulator / iOS Simulator / Web (ต้องเปิด Firebase Hosting/Config เพิ่มเติมหาก build สำหรับ Web)

> TIP: หากใช้ VS Code task ที่ฝังไว้ ให้รัน task `Install firebase_storage and image_picker` เพื่อ sync dependencies เพิ่มเติมก่อน build (ครั้งแรกเท่านั้น)

## Firebase & Firestore Setup
1. เปิดใช้งาน **Authentication (Email/Password)**
2. สร้าง **Cloud Firestore** โหมด Production
3. วาง **Security Rules** ที่บังคับสิทธิ์เจ้าของร้าน/ลูกค้า เช่น
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       function isSignedIn() { return request.auth != null; }
       function userRole(uid) {
         return get(/databases/$(database)/documents/users/$(uid)).data.role;
       }
       function isOwner() {
         return isSignedIn() && userRole(request.auth.uid) == 'owner';
       }

       match /products/{id} {
         allow read: if true;
         allow create, update, delete: if isOwner();
       }

       match /users/{id} {
         allow read: if isOwner() || (isSignedIn() && request.auth.uid == id);
         allow create, update: if isSignedIn() && request.auth.uid == id;
       }

       match /orders/{id} {
         allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
         allow read: if isOwner() || (isSignedIn() && resource.data.userId == request.auth.uid);
         allow update: if isOwner();
       }

       match /chats/{chatId} {
         allow read, write: if isOwner() || (isSignedIn() && request.auth.uid in [resource.data.ownerUid, resource.data.customerUid]);
       }
     }
   }
   ```
4. สร้างข้อมูลตั้งต้น
   - `users/<uid>`: ระบุ `role` (`owner` หรือ `customer`), `displayName`, `phone`, `createdAt`
   - `products`: เพิ่มเอกสารด้วยฟิลด์ `name`, `description`, `imageUrl`, `variants`, `basePrice`, `totalStock`, `createdAt`
   - `coupons`: หากต้องการ ให้สร้างฟิลด์ `code`, `discountType`, `value`, `isActive`, `expiredAt`
   - `orders`: ปล่อยให้แอปสร้างเมื่อชำระเงินสำเร็จ
   - `chats`: แอปจะสร้างอัตโนมัติเมื่อเริ่มสนทนา
5. ตั้งค่า **Firebase Storage** (สำหรับอัปโหลดสลิป/รูปสินค้า) และเพิ่ม Security Rules ให้สอดคล้องกับ user role หากเปิดใช้งาน

## Payments Backend (Stripe & PromptPay)
ไฟล์ตัวอย่างอยู่ที่ `opn_sandbox_backend.js`

1. ติดตั้ง dependencies
   ```bash
   npm install express stripe axios dotenv
   ```
2. สร้างไฟล์ `.env` ที่ root ของ backend ด้วยค่าจริงของคุณ
   ```env
   STRIPE_SECRET_KEY=sk_test_xxx
   STRIPE_PUBLISHABLE_KEY=pk_test_xxx
   OMISE_PUBLIC_KEY=pkey_test_xxx
   OMISE_SECRET_KEY=skey_test_xxx
   ```
3. รันเซิร์ฟเวอร์
   ```bash
   node opn_sandbox_backend.js
   ```
4. อัปเดต base URL ใน `lib/common/stripe_config.dart` และ `lib/features/orders/views/payment_view.dart` ให้เรียก endpoint ตามที่รันไว้ (เช่น `http://localhost:3000` หรือผ่าน LAN)
5. (ตัวเลือก) เปิดใช้งานส่วน Omise PromptPay โดยเลิกคอมเมนต์บล็อก Omise และติดตั้ง SDK เพิ่มเติม (`npm install omise`)

> หมายเหตุ: ห้าม commit ข้อมูล `.env` หรือคีย์จริงขึ้น Git Repository

## Project Structure
```
homemade_bliss/
|-- lib/
|   |-- main.dart
|   |-- app.dart
|   |-- common/            # การตั้งค่ากลาง (stripe_config, notification_service, in-app alerts)
|   |-- features/
|   |   |-- authentication/
|   |   |-- cart/
|   |   |-- chat/
|   |   |-- coupons/
|   |   |-- dashboard/
|   |   |-- notifications/
|   |   |-- orders/
|   |   |-- owner/
|   |   |-- personalization/
|   |   |-- products/
|   |   |-- store/
|   |-- services/          # การเชื่อมต่อภายนอกอื่น ๆ
|   |-- util/              # helper functions
|-- assets/
|   |-- images/
|   |-- fonts/
|-- android/, ios/, macos/, linux/, windows/, web/
|-- opn_sandbox_backend.js # backend sample สำหรับชำระเงิน
|-- docs/styling_reference.md
|-- pubspec.yaml
|-- README.md
```

## Useful Commands
- ติดตั้ง dependencies: `flutter pub get`
- รันแอป (device/OS ต่างกัน): `flutter run -d <deviceId>`
- ทดสอบหน่วย (widget test): `flutter test`
- ตรวจโค้ด format: `flutter format lib test`
- สร้าง build สำหรับ Android (debug APK): `flutter build apk --debug`
- สร้าง build สำหรับ iOS (release): `flutter build ios --release`

## Run on Physical Device
- **Start backend**
   - `cd C:\Users\mauy1\FlutterApp_\week1\homemade_bliss`
   - (ครั้งแรกหลัง clone หรือติดตั้ง Node) `npm install`
   - `node opn_sandbox_backend.js` และเปิดหน้าต่างนี้ค้างไว้ (Allow access เมื่อ Windows firewall ถาม)
- **เชื่อมต่อโทรศัพท์ Android จริง**
   - เปิด Developer Options และ USB debugging จากนั้นเสียบสาย USB
   - ตรวจสอบด้วย `flutter devices` ถ้ามีหลายเครื่องให้ระบุ `-d <deviceId>` ตอนรัน
- **หา IP เครื่องพัฒนา**
   - รัน `ipconfig` และจดค่า `IPv4 Address` จากอะแดปเตอร์ Wi-Fi (เช่น `172.20.10.11`)
   - โทรศัพท์กับคอมต้องอยู่เครือข่ายเดียวกัน จากโทรศัพท์ลองเปิดเบราว์เซอร์เข้า `http://<ip>:3000/stripe-publishable-key` เพื่อตรวจว่า backend เข้าถึงได้
- **รัน Flutter แอป**
   - `flutter pub get` (ถ้ายังไม่รันหลังอัปเดต dependencies)
   - `flutter run --dart-define=STRIPE_BACKEND_URL=http://<ip>:3000`
   - แทน `<ip>` ด้วยค่าจริง เช่น `flutter run --dart-define=STRIPE_BACKEND_URL=http://172.20.10.11:3000`
- **ข้อควรทราบ**
   - ถ้าเปลี่ยนเครือข่ายหรือรีสตาร์ทเครื่อง ให้ทำขั้นตอนนี้ใหม่ทุกครั้ง
   - หากไม่มีสัญญาณจาก backend แอปจะขึ้นข้อความ “Backend ไม่ตอบสนอง” ให้ตรวจสอบว่าเซิร์ฟเวอร์ Node.js ยังรันอยู่และ firewall อนุญาตการเชื่อมต่อแล้ว

   ## Stripe Cloud Functions Workflow
   - **กำหนดค่า secret**
      - ใช้คีย์จาก Stripe Dashboard (test mode) รัน `firebase functions:secrets:set STRIPE_SECRET_KEY` และ `firebase functions:secrets:set STRIPE_PUBLISHABLE_KEY` แล้ววาง `sk_test_...` และ `pk_test_...`
      - กำหนด `STRIPE_WEBHOOK_SECRET` ด้วยค่า `whsec_...` ที่ได้จาก `stripe listen --forward-to https://api-uycndad22a-as.a.run.app/stripe-webhook`
   - **Deploy ให้บริการ**
      - `firebase deploy --only functions:api`
      - ตรวจสอบด้วย `curl https://api-uycndad22a-as.a.run.app/stripe-publishable-key` ต้องตอบกลับ JSON ที่มีคีย์ทดสอบล่าสุด
   - **ทดสอบปลายทาง**
      - เปิดสองเทอร์มินัล: (A) `stripe listen --forward-to https://api-uycndad22a-as.a.run.app/stripe-webhook` (B) `stripe trigger payment_intent.succeeded`
      - ดู log ผ่าน `firebase functions:log --only api` ต้องเห็น `Stripe webhook received`
   - **รันแอปกับ backend นี้**
      - `flutter run -d <deviceId> --dart-define=BACKEND_BASE_URL=https://api-uycndad22a-as.a.run.app`
      - แอปจะเรียก endpoint เดียวกันทั้งการสร้าง PaymentIntent และดึง publishable key; ใช้ SSL อยู่แล้วสามารถถอดสายหลังติดตั้งเสร็จ

## Maintenance Checklist
- [ ] อัปเดต Firebase config ทุกครั้งที่สลับ project หรือเพิ่ม platform ใหม่
- [ ] เปลี่ยนค่า `_fallbackKey` ใน `StripeConfig` ก่อนปล่อย production
- [ ] ตรวจสอบให้ Notification permission ขอสำเร็จบน Android 13+ (`NotificationService.init()`)
- [ ] ทดสอบ flow ชำระเงินด้วย Stripe test cards / PromptPay ก่อนปล่อยจริง
- [ ] สำรอง Security Rules และจัดการการ deploy ผ่าน Firebase CLI หากมีการแก้ไข
- [ ] ตรวจสอบ dependencies ใน `pubspec.yaml` ให้อัปเดตสม่ำเสมอ (ใช้ `flutter pub outdated`)
- [ ] อ่านคู่มือธีมใน `docs/styling_reference.md` ก่อนแก้ UI หลัก

## Resources
- [Flutter documentation](https://docs.flutter.dev)
- [Stripe Flutter SDK docs](https://stripe.com/docs/payments/accept-a-payment?platform=flutter)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Opn/Omise PromptPay guide](https://www.omise.co/)
- [Design tokens & สี](docs/styling_reference.md)
- หากต้องการไอเดียเพิ่มเติมสำหรับ UI ดู mockups/wireframes เดิมที่แนบไว้ใน repo (commit history)

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
