# homemade_bliss
---

## คู่มือ Step-by-step สำหรับ Week 2–3 (แนะแนวทางและสิ่งที่ต้องทำเอง)

### Week 2: UX/UI & Project Setup

#### สิ่งที่ผมช่วยให้แล้ว
- ตัวอย่าง Wireframe, User Flow, Theme (ดูด้านบน)
- โครงสร้างโฟลเดอร์ในโปรเจ็กต์ Flutter
- ตัวอย่าง README.md นี้

#### สิ่งที่คุณควรทำเอง
1. วาด wireframe ใน Figma/Whimsical หรือวาดมือแล้วถ่ายรูป (ใช้ตัวอย่างด้านบนเป็นแนวทาง)
2. สรุปปัญหา/ผู้ใช้เป้าหมาย (Problem Statement & Target User) เป็นข้อความสั้น ๆ
3. เลือกธีม/สี/ฟอนต์ที่ชอบ (สามารถใช้ตัวอย่างที่ให้ไว้)
4. ตรวจสอบโครงสร้างโฟลเดอร์ในโปรเจ็กต์ให้ตรงกับที่แนะนำ (lib/features, assets/fonts, ...)

---

### Week 3: Vertical Slice & Data & Sync

#### สิ่งที่ผมช่วยให้แล้ว
- ตัวอย่าง schema Firestore (products, users, orders)
- ตัวอย่าง Security Rules (ดูด้านล่าง)
- โค้ด Auth, CRUD, เชื่อม Firestore (ในโปรเจ็กต์)
- Error handling ตัวอย่างในโค้ด

#### สิ่งที่คุณควรทำเอง
1. ตั้งค่า Firebase Project (ถ้ายังไม่มี)
2. เปิดใช้งาน Authentication (Email/Password)
3. สร้าง Firestore Database (เลือกโหมด production หรือ test ตามต้องการ)
4. อัปเดต Security Rules (คัดลอกตัวอย่างด้านล่างไปวางใน Firestore Rules)
5. สร้างคอลเลกชัน/เอกสารเริ่มต้น:
	 - `users`: สร้างเอกสาร `<uid>` (uid จาก Auth) ใส่ฟิลด์ `role: 'owner'` หรือ `'customer'`
	 - `products`: เพิ่มสินค้าตัวอย่าง (ใช้ปุ่ม Add Product ในแอป หรือเพิ่มเองใน Firestore)
	 - `orders`: ยังไม่ต้องสร้างเอง รอให้แอปสร้างเมื่อมีการสั่งซื้อ
6. ทดสอบการล็อกอิน/สมัคร/เพิ่มสินค้า/ดูสินค้า/ลบสินค้า ตาม flow ที่ออกแบบไว้

---

## วิธีตั้งค่า Firebase/Firestore/Rules (Step-by-step)

1. สร้างโปรเจ็กต์ Firebase ที่ https://console.firebase.google.com/
2. เพิ่มแอป (Android/iOS/Web) และดาวน์โหลดไฟล์ config (google-services.json, GoogleService-Info.plist, ฯลฯ) ใส่ในโปรเจ็กต์ Flutter ตามคู่มือ
3. เปิดใช้งาน Authentication → Email/Password
4. เปิดใช้งาน Firestore Database (เลือกโหมดที่เหมาะสม)
5. ตั้งค่า Security Rules (คัดลอกด้านล่างไปวางในแท็บ Rules)

```
// rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		function isSignedIn() { return request.auth != null; }
		function userRole(uid) {
			return get(/databases/$(database)/documents/users/$(uid)).data.role;
		}
		function isOwner() {
			return isSignedIn() && userRole(request.auth.uid) == 'owner';
		}

		// Products: public read, only owner can write
		match /products/{productId} {
			allow read: if true;
			allow create, update, delete: if isOwner();
		}

		// Users: owner อ่านได้ทั้งหมด (ถ้าต้องการ), ผู้ใช้แก้ไขของตนเองได้
		match /users/{userId} {
			allow read: if isOwner() || (isSignedIn() && request.auth.uid == userId);
			allow create: if isSignedIn() && request.auth.uid == userId;
			allow update: if isSignedIn() && request.auth.uid == userId;
		}

		// Orders
		match /orders/{orderId} {
			// ลูกค้า: สร้างของตัวเอง, อ่านของตัวเอง
			allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
			allow read: if isSignedIn() && resource.data.userId == request.auth.uid;

			// เจ้าของร้าน: อ่าน/อัปเดตสถานะออเดอร์ทั้งหมด (เช่น เปลี่ยน status)
			allow read, update: if isOwner();
		}
	}
}
```

6. สร้างข้อมูลเริ่มต้น:
	 - ไปที่ Firestore Database → Start collection → `users` → สร้าง document id ตรงกับ uid ใน Auth
	 - ใส่ฟิลด์ดังนี้ (ตัวอย่างสำหรับ owner):
		 - **role**: `'owner'` (string)
		 - **email**: `'owner@email.com'` (string)
		 - **phone**: `'0812345678'` (string)
		 - **displayName**: `'ชื่อเจ้าของร้าน'` (string)
		 - **createdAt**: `Timestamp` (เลือก Now)
		 - (ถ้ามีข้อมูลร้าน: shopName, shopAddress, ... เพิ่มได้)

	 - ตัวอย่าง users document (owner):
		 ```
		 {
			 "role": "owner",
			 "email": "owner@email.com",
			 "phone": "0812345678",
			 "displayName": "คุณโฮมเมด",
			 "createdAt": <Timestamp>
		 }
		 ```

	 - ตัวอย่าง users document (customer):
		 ```
		 {
			 "role": "customer",
			 "email": "customer@email.com",
			 "phone": "0899999999",
			 "displayName": "คุณลูกค้า",
			 "createdAt": <Timestamp>
		 }
		 ```

	 - เพิ่มสินค้าใน `products` (ผ่านแอปหรือ Firestore):
		 - **name**: `'Soft Cookie'` (string)
		 - **description**: `'คุกกี้นุ่มเต็มรส'` (string)
		 - **imageUrl**: `'https://via.placeholder.com/150'` (string)
		 - **price**: `59` (number)
		 - **stock**: `10` (number)
		 - **variants**: `["ช็อกโกแลต", "เมคาเดเมีย"]` (array of string)
		 - **createdAt**: `Timestamp` (เลือก Now หรือใช้ serverTimestamp ในแอป)

	 - ตัวอย่าง products document:
		 ```
		 {
			 "name": "Soft Cookie",
			 "description": "คุกกี้นุ่มเต็มรส",
			 "imageUrl": "https://via.placeholder.com/150",
			 "price": 59,
			 "stock": 10,
			 "variants": ["ช็อกโกแลต", "เมคาเดเมีย"],
			 "createdAt": <Timestamp>
		 }
		 ```

	 - ตรวจสอบให้มีฟิลด์ `createdAt` (Timestamp) ในทุกสินค้า เพื่อรองรับการเรียงลำดับ

7. ทดสอบการใช้งาน:
	 - ล็อกอินเป็น owner → เพิ่ม/ลบสินค้าได้
	 - ล็อกอินเป็น customer → ดูสินค้าได้ แต่เพิ่ม/ลบไม่ได้
	 - สั่งซื้อ (Place Order) → สร้างเอกสารใน `orders` อัตโนมัติ

---

## 6. โครงสร้างแชท (Chat) และ Edit Profile

### 6.1 โครงสร้าง Firestore สำหรับแชท (Chats/Messages)

- **chats** (collection)
	- **chatId** (document, สร้างจาก customerUid_ownerUid หรือ autoId)
		- **customerUid**: string (uid ของลูกค้า)
		- **ownerUid**: string (uid ของเจ้าของร้าน)
		- **lastMessage**: string
		- **lastTimestamp**: Timestamp
		- **messages** (subcollection)
			- **messageId** (document)
				- **senderUid**: string
				- **text**: string
				- **timestamp**: Timestamp
				- **read**: bool

**ตัวอย่าง chats document:**
```
chats/
	customerUid_ownerUid/  (หรือ autoId)
		customerUid: "uid_customer"
		ownerUid: "uid_owner"
		lastMessage: "สวัสดีค่ะ ขอสอบถามสินค้า"
		lastTimestamp: <Timestamp>
		messages/
			msg1/
				senderUid: "uid_customer"
				text: "สวัสดีค่ะ ขอสอบถามสินค้า"
				timestamp: <Timestamp>
				read: false
			msg2/
				senderUid: "uid_owner"
				text: "สอบถามได้เลยค่ะ"
				timestamp: <Timestamp>
				read: true
```

### 6.2 Wireframe หน้าแชท (Chat UI)
```
┌───────────────────────────────┐
│  แชทกับร้าน Homemade Bliss     │
│  ───────────────────────────  │
│  [คุณลูกค้า]: สวัสดีค่ะ ขอสอบถามสินค้า │
│  [ร้าน]: สอบถามได้เลยค่ะ           │
│  ...                            │
│  [ช่องพิมพ์ข้อความ........][ส่ง]   │
└───────────────────────────────┘
```

**มาตรฐาน:**
- ลูกค้าสามารถเริ่มแชทกับร้านได้ 1-1 (1 customer : 1 owner)
- ข้อความใหม่ push เข้า subcollection messages
- มี lastMessage/lastTimestamp ใน document หลักเพื่อ query รายการแชทเร็ว
- สามารถเพิ่มฟีเจอร์แจ้งเตือน (notification) ได้ในอนาคต

---

### 6.3 Edit Profile (ลูกค้า/เจ้าของร้าน)

**ฟิลด์ที่ควรมีใน users:**
- displayName: string (ชื่อที่แสดง)
- email: string
- phone: string
- (owner เพิ่ม shopName, shopAddress, shopPhone ได้)
- createdAt: Timestamp

**Wireframe Edit Profile:**
```
┌───────────────────────────────┐
│  แก้ไขโปรไฟล์                  │
│  [ชื่อที่แสดง.............]     │
│  [เบอร์โทร.................]     │
│  [อีเมล...................]     │
│  (เจ้าของร้าน: [ชื่อร้าน] [ที่อยู่ร้าน] [เบอร์ร้าน]) │
│  [บันทึก]                        │
└───────────────────────────────┘
```

**มาตรฐาน:**
- ดึงข้อมูลจาก users/<uid> มาแสดงในฟอร์ม
- กดบันทึกแล้ว update ข้อมูลใน Firestore
- (อีเมลอาจแก้ไม่ได้ ขึ้นกับ business logic)

**ตัวอย่าง users document (owner):**
```
{
	"role": "owner",
	"displayName": "คุณโฮมเมด",
	"email": "owner@email.com",
	"phone": "0812345678",
	"shopName": "Homemade Bliss",
	"shopAddress": "123/4 ถ.ขนมหวาน กทม.",
	"shopPhone": "021234567",
	"createdAt": <Timestamp>
}
```

**ตัวอย่าง users document (customer):**
```
{
	"role": "customer",
	"displayName": "คุณลูกค้า",
	"email": "customer@email.com",
	"phone": "0899999999",
	"createdAt": <Timestamp>
}
```

---

## 7. สรุปสิ่งที่ต้องทำเพิ่ม (Action Items)

- เพิ่มคอลเลกชัน chats/messages ใน Firestore ตาม schema
- เพิ่มฟิลด์ shopName, shopAddress, shopPhone ใน users (owner)
- เพิ่มหน้า Edit Profile (ดึง/อัปเดต users/<uid>)
- เพิ่มหน้าแชท (ดึง/ส่งข้อความใน chats/messages)
- ทดสอบ flow: ลูกค้าทักหาเจ้าของร้าน, เจ้าของร้านตอบกลับ, แก้ไขโปรไฟล์

---

## หมายเหตุเพิ่มเติม
- ถ้าต้องการเพิ่มฟีเจอร์ใหม่ (เช่น chat, แจ้งเตือน) ให้เพิ่มคอลเลกชันใหม่ใน Firestore และปรับ Rules ตามความเหมาะสม
- ถ้าต้องการให้ช่วยตรวจสอบ wireframe, flow, หรือโค้ด แจ้งได้เลย
- ถ้าติดปัญหาใด ๆ ในขั้นตอนข้างต้น ส่ง screenshot หรือ error message มาได้เลย ผมจะช่วยแก้ไขให้

## 3. ตัวอย่าง Wireframe (3–5 หน้าจอ)

### 1. หน้า Home (ลูกค้า)
```
┌───────────────────────────────┐
│  โลโก้ Homemade Bliss         │
│  [ค้นหา]                      │
│  ┌───────────────┐            │
│  │  รูปสินค้า   │  Soft Cookie  ฿59  [Add]
│  └───────────────┘            │
│  ...                          │
│  [Tab: Home | Categories | Orders | Profile] │
└───────────────────────────────┘
```

### 2. หน้า Cart/Orders (ลูกค้า)
```
┌───────────────────────────────┐
│  ตะกร้าสินค้า                 │
│  ┌───────────────┐            │
│  │  Soft Cookie │  x2  ฿118   │
│  └───────────────┘            │
│  รวม: ฿118                    │
│  [สั่งซื้อ]                   │
└───────────────────────────────┘
```

### 3. หน้า Owner Dashboard (เจ้าของร้าน)
```
┌───────────────────────────────┐
│  Owner Dashboard              │
│  [Tab: Dashboard | Products | Orders | Messages | Profile] │
│  ┌───────────────┐            │
│  │  Soft Cookie │  ฿59  สต็อก:10 [⋮]│
│  └───────────────┘            │
│  [ + Add Product ]            │
└───────────────────────────────┘
```

### 4. หน้า Login/Signup
```
┌───────────────────────────────┐
│  Login / Signup               │
│  [Email]                      │
│  [Password]                   │
│  [Sign in]  [Sign up]         │
└───────────────────────────────┘
```

### 5. หน้า Profile
```
┌───────────────────────────────┐
│  โปรไฟล์ผู้ใช้/ร้าน            │
│  [ชื่อ, เบอร์, อีเมล, ...]     │
│  [แก้ไขข้อมูล]                 │
└───────────────────────────────┘
```

---

## 4. User Flow หลัก

**ลูกค้า:**
1. สมัคร/ล็อกอิน
2. ดูสินค้า → ใส่ตะกร้า → สั่งซื้อ
3. ดูสถานะออเดอร์/แก้ไขโปรไฟล์

**เจ้าของร้าน:**
1. ล็อกอิน
2. จัดการสินค้า (เพิ่ม/ลบ/แก้ไข)
3. ดู/อัปเดตสถานะออเดอร์
4. แชท/แจ้งเตือนลูกค้า
5. แก้ไขโปรไฟล์ร้าน

---

## 5. ธีม/รูปลักษณ์ (Theme/Look & Feel)

- สีหลัก: น้ำตาลเข้ม (#4E342E), น้ำตาลกลาง (#8D6E63), ครีม (#FAF3EF)
- ฟอนต์: Poppins (assets/fonts)
- ปุ่ม: มุมโค้งมน, สีพื้นน้ำตาลกลาง ตัวอักษรขาว
- ไอคอน: ใช้ Material Icons (เช่น ตะกร้า, โปรไฟล์, สินค้า)
- รูปสินค้า: สี่เหลี่ยมมุมโค้ง, ขนาด 48–120px
- สไตล์โดยรวม: อบอุ่น, สะอาด, เน้นความเป็นกันเองแบบโฮมเมด

---

_หมายเหตุ: สามารถนำ wireframe นี้ไปวาดใน Figma หรือ Whimsical เพื่อความสวยงามและนำเสนอได้ต่อไป_

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.