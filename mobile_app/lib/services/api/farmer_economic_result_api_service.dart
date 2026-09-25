import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/economic_result.dart';
import 'api_client.dart';

/// Layanan API Phase 6: Farmer Economic Result
class FarmerEconomicResultApiService {
  final ApiClient _client = ApiClient();

  // ─── Per-Harvest ────────────────────────────────────────────────────────────

  /// GET /api/harvests/{harvestId}/economic-result
  /// Hasil ekonomi satu catatan panen (Gross Harvest Value, Allocated Cost, Profit/Loss).
  Future<HarvestEconomicResult?> getHarvestEconomicResult(int harvestId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/harvests/$harvestId/economic-result');
      final response = await http.get(uri, headers: _client.getHeaders());
      final data = _client.decodeApiResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return HarvestEconomicResult.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Per-Season ──────────────────────────────────────────────────────────────

  /// GET /api/seasons/{seasonId}/economic-summary
  /// Ringkasan ekonomi per musim tanam (termasuk semua panen di musim tersebut).
  Future<SeasonEconomicSummary?> getSeasonEconomicSummary(int seasonId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/seasons/$seasonId/economic-summary');
      final response = await http.get(uri, headers: _client.getHeaders());
      final data = _client.decodeApiResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return SeasonEconomicSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Farmer Overall ──────────────────────────────────────────────────────────

  /// GET /api/farmer/economic-summary
  /// Ringkasan ekonomi keseluruhan petani (semua musim, semua komoditas).
  Future<FarmerEconomicSummary?> getFarmerEconomicSummary() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/farmer/economic-summary');
      final response = await http.get(uri, headers: _client.getHeaders());
      final data = _client.decodeApiResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return FarmerEconomicSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Super Admin Aggregate ───────────────────────────────────────────────────

  /// GET /api/super-admin/economic-aggregate
  /// Agregat hasil ekonomi seluruh petani untuk Super Admin.
  Future<Map<String, dynamic>?> getSuperAdminEconomicAggregate() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/economic-aggregate');
      final response = await http.get(uri, headers: _client.getHeaders());
      final data = _client.decodeApiResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Integrated Agribusiness (Hulu + Hilir) ──────────────────────────────────

  /// GET /api/farmer/integrated-economic-summary
  /// Ringkasan Laba/Rugi Agribisnis Terpadu Petani (Hulu Kebun + Hilir Olahan).
  Future<IntegratedAgribusinessEconomicSummary?> getIntegratedEconomicSummary() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/farmer/integrated-economic-summary');
      final response = await http.get(uri, headers: _client.getHeaders());
      final data = _client.decodeApiResponse(response);

      if (data['success'] == true && data['data'] != null) {
        return IntegratedAgribusinessEconomicSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

