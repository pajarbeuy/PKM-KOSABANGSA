# Generalization Audit — Kentang → Hasil Tani

**Phase:** Phase 5
**Date:** 2026-09-20
**Status:** ✅ Completed

---

## Objective

Menghilangkan semua asumsi "komoditas = kentang" yang memengaruhi production logic, UI presentation, atau data yang terlihat pengguna.
**Prinsip:** Generalization = tidak ada asumsi komoditas yang membatasi, mengubah, atau menyesatkan perilaku aplikasi.

---

## Scope

Diizinkan: user-facing text/label, UI artifact tanpa DB support, chatbot keyword (intent ekuivalen), dokumentasi.
Tidak diizinkan: schema migration, API contract change, business rule change, AI behavior, test fixture change, data migration.

---

## Search Terms Used

kentang, potato, umbi, bibit, komoditas

---

## Classification Rules

- [UI-TEXT]           : Label/teks user-facing hardcoded ke kentang → Generalisasi
- [BEHAVIOR]          : Memengaruhi intent matching/logic → Audit intent
- [BUG]               : Hardcoded logic/value tanpa backend support → Fix
- [MOCK]              : Demo/preview/test fixture → Pertahankan
- [GENERAL]           : Valid domain term → Pertahankan
- [UNUSED]            : File tidak aktif → Low-risk housekeeping
- [OUT-OF-SCOPE]      : AI behavior → Catat sebagai technical debt

---

## Findings and Decisions

### Backend PHP — Changed

| File                           | Line(s)  | Occurrence                              | Classification | Decision      |
|--------------------------------|----------|-----------------------------------------|----------------|---------------|
| ChatbotController.php          | 25       | 'jual kentang' keyword                  | [BEHAVIOR]     | Changed       |
| ChatbotController.php          | 42       | "aplikasi pertanian kentang" greeting   | [UI-TEXT]      | Changed       |
| ChatbotController.php          | 46       | "Stok Kentang" about text              | [UI-TEXT]      | Changed       |
| ChatbotController.php          | 50       | "budidaya kentang" farewell             | [UI-TEXT]      | Changed       |
| DatabaseSeeder.php             | 43-44    | hero_title / hero_description seed      | [UI-TEXT]      | Changed       |
| landing.blade.php              | 188,194  | Hero fallback "Stok Kentang"           | [UI-TEXT]      | Changed       |
| profit-loss-pdf.blade.php      | 221      | "sistem Pertanian Kentang" footer       | [UNUSED]       | Changed       |
| target-vs-actual-pdf.blade.php | 214      | "sistem Pertanian Kentang" footer       | [UNUSED]       | Changed       |

### Flutter — Changed

| File                            | Line(s)    | Occurrence                               | Classification | Decision        |
|---------------------------------|------------|------------------------------------------|----------------|-----------------|
| add_edit_harvest_screen.dart    | 30-31,212  | _komoditasController hardcoded Kentang  | [BUG]          | Removed (field) |
| harvest_screen.dart             | 331,368-77 | Kolom KOMODITAS + cell 'Kentang'        | [BUG]          | Removed (col)   |
| add_edit_sale_screen.dart       | 507        | hintText 'berat kentang'                | [UI-TEXT]      | Changed         |
| chatbot_screen.dart             | 29         | quick reply 'budidaya kentang'          | [UI-TEXT]      | Changed         |
| feedback_management_screen.dart | 156,490    | farm_name fallback 'Pertanian Kentang'  | [UI-TEXT]      | Changed         |
| feedback_screen.dart            | 88         | 'platform pertanian kentang'            | [UI-TEXT]      | Changed         |
| register_screen.dart            | 144        | subtitle 'hasil panen kentang'          | [UI-TEXT]      | Changed         |
| settings_screen.dart            | 461        | 'penjualan kentang'                     | [UI-TEXT]      | Changed         |
| stock_screen.dart               | 655        | hintText 'Kentang busuk / susut'        | [UI-TEXT]      | Changed         |
| target_screen.dart              | 212        | subtitle 'pertanian kentang per musim'  | [UI-TEXT]      | Changed         |

---

## Intentionally Retained Occurrences

| File                     | Occurrence                           | Classification | Reason                              |
|--------------------------|--------------------------------------|----------------|-------------------------------------|
| landing.blade.php        | .potato-particle, triggerPotatoExplosion() | [GENERAL]  | Internal CSS/JS — tidak user-facing |
| landing_hero.dart        | 'Petani Kentang - Musim 1 2026'     | [MOCK]         | Demo preview data landing page      |
| ComprehensiveApiTest.php | 'Kebun Kentang Subur'               | [MOCK]         | Test fixture                        |
| ComprehensiveApiTest.php | 'Musim Kentang G1'                  | [MOCK]         | Test fixture                        |
| CostTest.php             | 'Bibit kentang berkualitas'          | [MOCK]         | Test description fixture            |
| DB migration             | enum('seed', ...)                   | [GENERAL]      | seed = valid business category      |
| ProductionCostFactory    | 'bibit' random element               | [GENERAL]      | Valid enum per BUSINESS_RULES.md    |

---

## Out-of-Scope Technical Debt

### n8n AI System Prompt
File: n8n/TaniBot_Chat_Workflow.json
System prompt Llama menyebut asumsi komoditas kentang.
Decision: TIDAK diubah pada Phase 5.
Reason: Perubahan system prompt dapat mengubah behavior AI model secara tidak terduga.
Follow-up: Audit AI persona pada phase dedicated.

### Persisted DB Landing Content
Jika DB sudah memiliki hero_title/hero_description yang mengandung "Kentang",
perubahan fallback tidak membersihkan data persisted tersebut.
Decision: Tidak dimigrate — di luar scope Phase 5.

---

## Verification

Backend: php artisan test tests/Feature/API → 63/63 PASSED ✅
Flutter analyze: flutter analyze → No issues found! ✅ (0 errors, 0 warnings)
Post-change grep: 0 unintended production/user-facing occurrences ✅

---

## Completion Criteria Status

[x] Tidak ada production logic yang mengharuskan komoditas kentang
[x] Tidak ada UI production yang menyatakan sistem hanya untuk kentang
[x] Harvest form tidak memiliki fake commodity field
[x] Harvest table tidak menampilkan fake commodity value
[x] Chatbot keyword tidak bergantung pada intent commodity-specific
[x] Landing fallback text generik
[x] API contract tidak berubah
[x] Database schema tidak berubah
[x] Business rules tidak berubah
[x] Backend tests 63/63 PASS
[x] Post-change grep 0 unintended production occurrences
[x] Flutter analyze (No issues found!)
[ ] Manual UAT (pending staging / device run)

