# มะลิ — ผู้ช่วยซ่อมบ้าน (rakbaan_page1)

Flutter app (Android + iOS) ที่รัน LLM ที่ fine-tune แล้ว (Gemma-2-2B, quantized เป็น
`q4_k_m` GGUF) แบบ **on-device ล้วนๆ ไม่ต้องต่อเน็ตตอนคุยกับมะลิ** โดยใช้
[`fllama`](https://github.com/Telosnex/fllama) (Flutter binding ของ llama.cpp)

## โครงสร้างโปรเจกต์

```
lib/
  core/
    persona.dart          ระบบ prompt ของ "มะลิ" + รายการคำสำคัญสำหรับ pre-filter
    app_theme.dart
  models/
    chat_message.dart     โมเดลข้อความ 1 บับเบิลแชท
  services/
    domain_filter_service.dart   กรองคำถามนอกหัวข้อก่อนเข้าโมเดล
    model_manager_service.dart   ดาวน์โหลด/หาไฟล์ .gguf บนเครื่อง
    llama_chat_service.dart      ครอบ fllama, สตรีมคำตอบ, ยกเลิกได้
  providers/
    chat_provider.dart    ChangeNotifier ผูก UI เข้ากับ service ทั้งหมด
  screens/
    model_setup_screen.dart      หน้าจอแรก: เตรียม/ดาวน์โหลดโมเดล
    chat_screen.dart             หน้าแชทหลัก
  widgets/
    chat_bubble.dart
    message_input_bar.dart
  main.dart
```

## ก่อนรันจริง ต้องทำ 3 อย่างนี้ก่อน

### 1. Windows เท่านั้น: เปิด git long paths ก่อน `flutter pub get`

`fllama` vendor ซอร์ส llama.cpp ทั้งก้อนไว้ในแพ็กเกจ (รวม path ลึกมากของ tools/ui)
ซึ่งเกิน 260 ตัวอักษรที่ Windows/git จำกัดไว้โดย default ต้องรันคำสั่งนี้ครั้งเดียว
(ผลกระทบเป็น global git setting บนเครื่องคุณ ไม่ใช่แค่โปรเจกต์นี้):

```bash
git config --global core.longpaths true
```

จากนั้นค่อย `flutter pub get`. (บน macOS/Linux ไม่ต้องทำขั้นตอนนี้)

### 2. ใส่ URL ของไฟล์โมเดล .gguf ของคุณ

ไฟล์ `q4_k_m` ของโมเดล 2B ขนาดจะประมาณ 1.5-1.7 GB — **ใหญ่เกินกว่าจะ bundle เป็น
Flutter asset** (ชนขีดจำกัดขนาด APK/AAB ของ Play Store และ cellular-download cap
ของ App Store) แอปนี้จึงดาวน์โหลดไฟล์โมเดลจากเซิร์ฟเวอร์ของคุณเองตอนเปิดแอปครั้งแรก
แล้วเก็บไว้ในโฟลเดอร์ส่วนตัวของแอป (ครั้งต่อไปไม่ต้องดาวน์โหลดซ้ำ และคุยกับมะลิได้
โดยไม่ต้องต่อเน็ต)

แก้ค่านี้ใน `lib/services/model_manager_service.dart`:

```dart
static const String modelDownloadUrl =
    'https://example.com/replace-with-your-model-url/malii-home-repair-q4_k_m.gguf';
```

ชี้ไปที่ไฟล์ .gguf ของคุณจริง (ที่เก็บของคุณเอง, Firebase Storage, S3, หรือลิงก์
`resolve/main/...gguf` บน Hugging Face ก็ได้ ขอแค่เป็น HTTPS ธรรมดา)

### 3. Android build.gradle.kts ปรับให้เหมาะกับ on-device LLM แล้ว

`android/app/build.gradle.kts`:
- `applicationId = "com.rakbaan"` (ตามที่ระบุ)
- `minSdk = 24` — llama.cpp ต้องการ ABI 64-bit, อุปกรณ์ต่ำกว่านี้รันโมเดล 2B ไม่ไหวอยู่แล้ว
- `abiFilters = ["arm64-v8a"]` — จำกัดแค่ ABI เดียวเพื่อลดขนาดแอป (native lib ของ
  llama.cpp หนักหลายสิบ MB ต่อ ABI)

`AndroidManifest.xml`: เพิ่ม `INTERNET` permission (ไว้ดาวน์โหลดโมเดล) และ
`android:largeHeap="true"`

## iOS: ขั้นตอนที่ต้องทำเองบน Xcode (แก้จาก Windows ให้ไม่ได้)

โปรเจกต์นี้ scaffold ด้วย Flutter บน Windows ซึ่งไม่มี Xcode/macOS toolchain ให้ผม
รันหรือตรวจสอบ build ฝั่ง iOS ได้จริง — ต้องทำ 3 ขั้นตอนนี้เองบน Mac ก่อนรันบน iOS
ครั้งแรก:

1. `flutter pub get` แล้ว `cd ios && pod install` (CocoaPods จะ generate `Podfile`
   ให้อัตโนมัติตอนนี้ ถ้ายังไม่มี)
2. เปิด `ios/Runner.xcworkspace` (**ต้องเปิดไฟล์นี้ ไม่ใช่ .xcodeproj**) ด้วย Xcode
3. ไปที่ Runner target → **Signing & Capabilities** → กด **+ Capability** →
   เพิ่ม **Increased Memory Limit** (จำเป็นเพราะโมเดล ~1.5-2GB ใหญ่กว่า memory
   limit ปกติของแอป iOS ทั่วไปมาก โดยเฉพาะเมื่อรันตอนแอปอยู่ background)
4. iOS Deployment Target ตั้งไว้ที่ 13.0 อยู่แล้ว (เพียงพอสำหรับ fllama)

## กลไกกรองคำถามนอกหัวข้อ (Domain Filter)

`domain_filter_service.dart` ใช้ **keyword matching แบบออฟไลน์ล้วนๆ** เป็นด่านแรก
ก่อนเรียกโมเดลทุกครั้ง:

- ถ้าเจอคำในกลุ่มทักทาย (`สวัสดี`, `คุณคือใคร`, ...) → ส่งเข้าโมเดลตามปกติ ให้มะลิ
  แนะนำตัวได้
- ถ้าเจอคำในหมวดซ่อมบ้าน (ไฟฟ้า, ประปา, แอร์, หลังคา, ฯลฯ — ดูรายการเต็มใน
  `lib/core/persona.dart`) → ส่งเข้าโมเดลตามปกติ
- ถ้าไม่เจอเลย → ตอบด้วยข้อความสำเร็จรูป (`Persona.offTopicReply`) ทันที **โดยไม่
  เรียกโมเดล** ประหยัดแบตเตอรี่/ความร้อน/เวลาเครื่องได้จริง เพราะคำถามที่ชัดเจนว่า
  นอกหัวข้อ (เช่น "แต่งกลอนให้หน่อย", "พรุ่งนี้หวยออกอะไร") ไม่มีทางได้คำตอบที่มี
  ประโยชน์จากโมเดลที่ fine-tune เฉพาะเรื่องซ่อมบ้านอยู่แล้ว

**ทำไมไม่ใช้ keyword filter เป็นด่านเดียว:** ภาษาไทยพูดได้หลายแบบมาก
ประโยคที่เกี่ยวข้องจริงบางประโยคอาจไม่มีคำในลิสต์เลย (คำถามอาจสั้นเกินไปหรือใช้คำที่
ไม่คาดคิด) เพื่อความปลอดภัย `Persona.systemPrompt` (ข้อ 4) จึงสั่งให้ตัวโมเดลเองก็
ปฏิเสธคำถามนอกหัวข้ออย่างสุภาพด้วยอีกชั้นหนึ่งเสมอ — filter คือด่านประหยัดพลังงาน
สำหรับเคสที่ชัดเจน ส่วนตัวโมเดลคือความปลอดภัยที่แท้จริง

**คำแนะนำเพิ่มเติม:** ถ้าพบว่าลิสต์คำสำคัญเข้มงวด/หลวมเกินไปหลังทดสอบจริง
แนะนำให้ log ข้อความที่ถูก filter ออก (`FilterVerdict.offTopic`) เก็บไว้ในเครื่อง
ผู้ใช้เอง แล้วนำมาทบทวนเป็นระยะเพื่อเพิ่มคำสำคัญที่ตกหล่นบ่อยๆ ลงใน
`DomainKeywords.homeRepairKeywords`

## สิ่งที่ตรวจสอบแล้วในสภาพแวดล้อมนี้

- `flutter pub get`, `flutter analyze` (0 issues), `flutter test`, และ
  `flutter build apk --debug` **ผ่านทั้งหมด** — ยืนยันด้วยแพ็กเกจ stub ที่มี
  API เหมือน `fllama` เป๊ะ (ตรวจ signature จริงจากซอร์สโค้ด `fllama` บน GitHub)
  เพราะสภาพแวดล้อมนี้เป็น Windows และ git ตัดการ clone ซอร์ส llama.cpp ของ fllama
  เนื่องจากปัญหา long-path (ดูข้อ 1 ด้านบน)
- **ยังไม่ได้รันจริงบนอุปกรณ์/emulator ที่มีไฟล์โมเดลจริง** — หลังใส่ URL โมเดลและ
  แก้ปัญหา long-path แล้ว ให้รัน `flutter run` บนอุปกรณ์ Android จริงเพื่อทดสอบ
  golden path (พิมพ์คำถามเกี่ยวกับไฟฟ้า/ประปา/แอร์ ดูว่ามะลิตอบและลงท้าย "ค่ะ"
  ถูกต้อง) และ edge case (คำถามนอกหัวข้อ, กด "หยุดการตอบ" กลางคัน)
- ฝั่ง iOS **ยังไม่ได้ build/test เลย** เพราะไม่มี macOS/Xcode ในสภาพแวดล้อมนี้ —
  ทำตาม "iOS: ขั้นตอนที่ต้องทำเองบน Xcode" ด้านบนก่อนรันครั้งแรก

## ฟีเจอร์ที่ทำเป็น placeholder ไว้

- ปุ่มไมค์ในหน้าแชท (`message_input_bar.dart`) ตอนนี้กดแล้วขึ้น snackbar เฉยๆ —
  ยังไม่ได้ผูก speech-to-text จริง (ต้องเพิ่ม package เช่น `speech_to_text` และขอ
  permission ไมโครโฟนแยกต่างหาก ถ้าต้องการฟีเจอร์นี้บอกได้เลยครับ จะทำให้ในขั้นถัดไป)
