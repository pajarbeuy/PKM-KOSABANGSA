import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/commission.dart';
import 'api_client.dart';

class CommissionApiService {
  final ApiClient _client = ApiClient();

  /// Fetch commissions list and summary (works for both Super Admin and Farmer)
  Future<Map<String, dynamic>> getCommissions({
    String? startDate,
    String? endDate,
    int? userId,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
    if (userId != null) queryParams['user_id'] = userId.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/commissions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _client.getHeaders());
    final data = _client.decodeApiResponse(response);

    if (data['success'] == true && data['data'] != null) {
      final payload = data['data'] as Map<String, dynamic>;
      final summary = CommissionSummary.fromJson(payload['summary'] as Map<String, dynamic>);
      final commissionsList = (payload['commissions']['data'] as List<dynamic>)
          .map((item) => Commission.fromJson(item as Map<String, dynamic>))
          .toList();

      final total = (payload['commissions']['total'] ?? commissionsList.length) as int;
      final lastPage = (payload['commissions']['last_page'] ?? 1) as int;

      return {
        'summary': summary,
        'commissions': commissionsList,
        'total': total,
        'last_page': lastPage,
      };
    }

    throw Exception(data['message'] ?? 'Gagal memuat data komisi');
  }

  /// Fetch standalone commission summary KPI
  Future<CommissionSummary> getCommissionSummary({
    String? startDate,
    String? endDate,
    int? userId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
    if (userId != null) queryParams['user_id'] = userId.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/commissions/summary').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _client.getHeaders());
    final data = _client.decodeApiResponse(response);

    if (data['success'] == true && data['data'] != null) {
      return CommissionSummary.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Gagal memuat ringkasan komisi');
  }
}
