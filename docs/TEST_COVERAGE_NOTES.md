# Catatan Cakupan Pengujian (Test Coverage Notes)

**Proyek:** SumberTani berbasis AI  
**Dokumen:** `docs/TEST_COVERAGE_NOTES.md`  
**Status:** Canonical Living Document  
**Terakhir Diperbarui:** 21 September 2026  

---

## 📊 Ringkasan Test Suite Saat Ini

- **Framework Pengujian:** PHPUnit 11 / Laravel Feature Testing (In-Memory SQLite + DatabaseTransactions / RefreshDatabase).
- **Perintah Eksekusi:** `php artisan test tests/Feature/API`
- **Status Terkini:** **64 Tests Passed (216 Assertions) — 100% Success Rate.**
- **Durasi Eksekusi Rata-rata:** ~5.2 detik.

---

## 📂 Pemetaan File Test & Domain Pengujian

| Nama Test Suite | File Path | Jumlah Test | Domain yang Dicakup |
|---|---|---|---|
| **AuthApiTest** | `tests/Feature/API/AuthApiTest.php` | 5 | Register, Login, Token generation, Validation, Logout |
| **BugFixRegressionTest** | `tests/Feature/API/BugFixRegressionTest.php` | 6 | BUG-001 (Cost categories), BUG-002 (Season computed status & dashboard filtering) |
| **ChatbotApiTest** | `tests/Feature/API/ChatbotApiTest.php` | 2 | Endpoint chat responsivitas & format JSON |
| **ComprehensiveApiTest** | `tests/Feature/API/ComprehensiveApiTest.php` | 6 | Integrasi multi-modul, end-to-end data flow panen → stok → penjualan |
| **CostApiTest** | `tests/Feature/API/CostApiTest.php` | 4 | CRUD Biaya Produksi, 4 kategori resmi, kepemilikan tenant |
| **DashboardApiTest** | `tests/Feature/API/DashboardApiTest.php` | 4 | Ringkasan stok, total panen, pendapatan, biaya, transaksi terakhir |
| **HarvestApiTest** | `tests/Feature/API/HarvestApiTest.php` | 4 | CRUD Panen, auto stock-in mutation, verifikasi kepemilikan musim |
| **PasswordResetSecurityTest** | `tests/Feature/API/PasswordResetSecurityTest.php` | 4 | Keamanan reset password token, enkripsi, expiration, brute-force guard |
| **Phase4RegressionTest** | `tests/Feature/API/Phase4RegressionTest.php` | 17 | Negative tests, boundary tests (stok 0, harga 0), invariant multi-tenant |
| **SaleApiTest** | `tests/Feature/API/SaleApiTest.php` | 4 | CRUD Penjualan, auto stock-out mutation, verifikasi saldo stok cukup |
| **SeasonApiTest** | `tests/Feature/API/SeasonApiTest.php` | 5 | CRUD Musim tanam, `harvests_sum_weight_kg`, multi-harvest aggregation test |
| **StockApiTest** | `tests/Feature/API/StockApiTest.php` | 3 | Transaksi masuk/keluar gudang manual, saldo mutasi |

---

## 🎯 Rencana Penambahan Test Matrix (Phase 9 — Fitur Baru PKM)

Untuk fitur baru yang dikembangkan pada program PKM, berikut test matrix baru yang akan ditambahkan ke test suite:

### 1. Processed Product Domain (`ProcessedProductApiTest`)
- [ ] `test_farmer_can_create_processed_product` (201 Created)
- [ ] `test_farmer_can_only_view_own_processed_products` (Multi-tenant isolation)
- [ ] `test_farmer_cannot_update_or_delete_other_farmer_product` (403 Forbidden)
- [ ] `test_super_admin_can_view_all_processed_products` (200 OK)
- [ ] `test_product_stock_cannot_be_negative` (422 Unprocessable Entity)
- [ ] `test_stock_zero_transitions_to_out_of_stock` (Auto state transition)
- [ ] `test_restock_transitions_out_of_stock_to_active` (Auto state transition)
- [ ] `test_restock_on_inactive_product_keeps_inactive_status` (Manual status preservation)

### 2. Centralized Sales & Stock Decrement
- [ ] `test_farmer_cannot_create_sales_directly` (403 Forbidden)
- [ ] `test_super_admin_can_record_processed_product_sale` (201 Created)
- [ ] `test_sale_decrements_farmer_product_stock_atomically` (Consistency invariant)
- [ ] `test_sale_rejects_quantity_greater_than_stock` (422 Unprocessable Entity)

### 3. Super Admin Aggregate Profit/Loss
- [ ] `test_super_admin_can_view_aggregate_farmer_profit_loss` (Semantic response format)
- [ ] `test_aggregate_profit_loss_equals_sum_of_individual_farmers` (No double counting)

### 4. Super Admin Operational Chatbot
- [ ] `test_farmer_and_unauthenticated_cannot_access_chat` (401/403)
- [ ] `test_super_admin_can_access_operational_chat` (200 OK)
