import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../models/dashboard.dart';
import '../models/harvest.dart';
import '../models/stock.dart';
import '../models/sale.dart';
import '../models/season.dart';
import '../models/cost.dart';

import 'api/api_client.dart';
import 'api/auth_api_service.dart';
import 'api/season_api_service.dart';
import 'api/harvest_api_service.dart';
import 'api/stock_api_service.dart';
import 'api/sale_api_service.dart';
import 'api/cost_api_service.dart';
import 'api/report_api_service.dart';
import 'api/super_admin_api_service.dart';
import 'api/misc_api_service.dart';
import 'api/processed_product_api_service.dart';
import 'api/order_api_service.dart';
import 'api/farmer_group_api_service.dart';
import '../models/processed_product.dart';
import '../models/order_model.dart';
import '../models/farmer_group.dart';

/// Facade Singleton providing a unified API interface across all domain services.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final ApiClient _client = ApiClient();
  final AuthApiService _authService = AuthApiService();
  final SeasonApiService _seasonService = SeasonApiService();
  final HarvestApiService _harvestService = HarvestApiService();
  final StockApiService _stockService = StockApiService();
  final SaleApiService _saleService = SaleApiService();
  final CostApiService _costService = CostApiService();
  final ReportApiService _reportService = ReportApiService();
  final SuperAdminApiService _superAdminService = SuperAdminApiService();
  final MiscApiService _miscService = MiscApiService();
  final ProcessedProductApiService _processedProductService = ProcessedProductApiService();
  final OrderApiService _orderService = OrderApiService();
  final FarmerGroupApiService _farmerGroupService = FarmerGroupApiService();

  // ─── Client / Token Management ─────────────────────────────────────────────
  void setAuthToken(String token) => _client.setAuthToken(token);
  String? getAuthToken() => _client.getAuthToken();
  void clearAuthToken() => _client.clearAuthToken();

  // ─── Auth & Dashboard ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) =>
      _authService.login(email, password);

  Future<Map<String, dynamic>> register({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required int farmerGroupId,
    required String password,
    required String passwordConfirmation,
  }) =>
      _authService.register(
        farmName: farmName,
        name: name,
        email: email,
        phone: phone,
        farmerGroupId: farmerGroupId,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  Future<void> logout() => _authService.logout();

  Future<User?> getCurrentUser() => _authService.getCurrentUser();

  Future<Map<String, dynamic>> sendPasswordResetLink(String email) =>
      _authService.sendPasswordResetLink(email);

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) =>
      _authService.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  Future<DashboardData?> getDashboard() => _authService.getDashboard();

  // ─── Seasons ───────────────────────────────────────────────────────────────
  Future<List<Season>> getSeasons({String? search, String? status}) =>
      _seasonService.getSeasons(search: search, status: status);

  Future<Season?> getSeason(int id) => _seasonService.getSeason(id);

  Future<Map<String, dynamic>> createSeason({
    required String name,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) =>
      _seasonService.createSeason(
        name: name,
        startDate: startDate,
        endDate: endDate,
        status: status,
        targetKg: targetKg,
        notes: notes,
      );

  Future<Map<String, dynamic>> updateSeason(
    int id, {
    required String name,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) =>
      _seasonService.updateSeason(
        id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        status: status,
        targetKg: targetKg,
        notes: notes,
      );

  Future<Map<String, dynamic>> deleteSeason(int id) =>
      _seasonService.deleteSeason(id);

  // ─── Harvests ──────────────────────────────────────────────────────────────
  Future<List<Harvest>> getHarvests({int? seasonId}) =>
      _harvestService.getHarvests(seasonId: seasonId);

  Future<Harvest?> getHarvest(int id) => _harvestService.getHarvest(id);

  Future<Map<String, dynamic>> createHarvest({
    required int seasonId,
    required String harvestDate,
    required int quantity,
    required double weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) =>
      _harvestService.createHarvest(
        seasonId: seasonId,
        harvestDate: harvestDate,
        quantity: quantity,
        weightKg: weightKg,
        notes: notes,
        status: status,
        photoFile: photoFile,
      );

  Future<Map<String, dynamic>> updateHarvest(
    int id, {
    int? seasonId,
    String? harvestDate,
    int? quantity,
    double? weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) =>
      _harvestService.updateHarvest(
        id,
        seasonId: seasonId,
        harvestDate: harvestDate,
        quantity: quantity,
        weightKg: weightKg,
        notes: notes,
        status: status,
        photoFile: photoFile,
      );

  Future<Map<String, dynamic>> deleteHarvest(int id) =>
      _harvestService.deleteHarvest(id);

  // ─── Stock ─────────────────────────────────────────────────────────────────
  Future<StockData?> getStock() => _stockService.getStock();

  Future<Map<String, dynamic>> addStockTransaction({
    required String type,
    required int amount,
    String? notes,
  }) =>
      _stockService.addStockTransaction(
        type: type,
        amount: amount,
        notes: notes,
      );

  // ─── Sales ─────────────────────────────────────────────────────────────────
  Future<List<Sale>> getSales() => _saleService.getSales();

  Future<Sale?> getSale(int id) => _saleService.getSale(id);

  Future<Map<String, dynamic>> createSale({
    required int quantity,
    required int pricePerUnit,
    required String saleDate,
    required String buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) =>
      _saleService.createSale(
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        saleDate: saleDate,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        notes: notes,
        status: status,
        paymentStatus: paymentStatus,
        seasonId: seasonId,
      );

  Future<Map<String, dynamic>> updateSale(
    int id, {
    int? quantity,
    int? pricePerUnit,
    String? saleDate,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) =>
      _saleService.updateSale(
        id,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        saleDate: saleDate,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        notes: notes,
        status: status,
        paymentStatus: paymentStatus,
        seasonId: seasonId,
      );

  Future<Map<String, dynamic>> deleteSale(int id) =>
      _saleService.deleteSale(id);

  // ─── Costs ─────────────────────────────────────────────────────────────────
  Future<List<Cost>> getCosts({int? seasonId}) =>
      _costService.getCosts(seasonId: seasonId);

  Future<Map<String, dynamic>> createCost({
    required String date,
    int? seasonId,
    required String category,
    required double amount,
    String? notes,
  }) =>
      _costService.createCost(
        date: date,
        seasonId: seasonId,
        category: category,
        amount: amount,
        notes: notes,
      );

  Future<Map<String, dynamic>> updateCost(
    int id, {
    String? date,
    int? seasonId,
    String? category,
    double? amount,
    String? notes,
  }) =>
      _costService.updateCost(
        id,
        date: date,
        seasonId: seasonId,
        category: category,
        amount: amount,
        notes: notes,
      );

  Future<Map<String, dynamic>> deleteCost(int id) =>
      _costService.deleteCost(id);

  // ─── Reports ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfitLossReport({int? seasonId}) =>
      _reportService.getProfitLossReport(seasonId: seasonId);

  Future<List<dynamic>> getTargetVsActualReport() =>
      _reportService.getTargetVsActualReport();

  Future<List<int>?> downloadProfitLossReportPdf({int? seasonId}) =>
      _reportService.downloadProfitLossReportPdf(seasonId: seasonId);

  Future<List<int>?> downloadTargetVsActualReportPdf() =>
      _reportService.downloadTargetVsActualReportPdf();

  // ─── Super Admin ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSuperAdminDashboard() =>
      _superAdminService.getSuperAdminDashboard();

  Future<List<dynamic>> getSuperAdminUsers() =>
      _superAdminService.getSuperAdminUsers();

  Future<Map<String, dynamic>> createSuperAdminUser(
    Map<String, dynamic> userData,
  ) =>
      _superAdminService.createSuperAdminUser(userData);

  Future<Map<String, dynamic>> updateSuperAdminUser(
    int id,
    Map<String, dynamic> userData,
  ) =>
      _superAdminService.updateSuperAdminUser(id, userData);

  Future<Map<String, dynamic>> deleteSuperAdminUser(int id) =>
      _superAdminService.deleteSuperAdminUser(id);

  Future<Map<String, dynamic>> impersonateUser(int id) =>
      _superAdminService.impersonateUser(id);

  Future<Map<String, dynamic>?> getLandingContent() =>
      _superAdminService.getLandingContent();

  Future<Map<String, dynamic>> updateLandingContent(
    Map<String, String> landingData,
  ) =>
      _superAdminService.updateLandingContent(landingData);

  Future<List<dynamic>> getDashboardMenus() =>
      _superAdminService.getDashboardMenus();

  Future<Map<String, dynamic>> createDashboardMenu(
    Map<String, dynamic> menuData,
  ) =>
      _superAdminService.createDashboardMenu(menuData);

  Future<Map<String, dynamic>> updateDashboardMenu(
    int id,
    Map<String, dynamic> menuData,
  ) =>
      _superAdminService.updateDashboardMenu(id, menuData);

  Future<Map<String, dynamic>> deleteDashboardMenu(int id) =>
      _superAdminService.deleteDashboardMenu(id);

  Future<List<dynamic>> getFeedbacks() => _superAdminService.getFeedbacks();

  Future<Map<String, dynamic>> markFeedbackAsRead(int id) =>
      _superAdminService.markFeedbackAsRead(id);

  Future<Map<String, dynamic>> deleteFeedback(int id) =>
      _superAdminService.deleteFeedback(id);

  // ─── Settings, Notifications, Feedback, Chatbot ────────────────────────────
  Future<Map<String, dynamic>?> getSettings() => _miscService.getSettings();

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? farmName,
  }) =>
      _miscService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        farmName: farmName,
      );

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _miscService.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  Future<Map<String, dynamic>> deleteAccount() => _miscService.deleteAccount();

  Future<Map<String, dynamic>> updateWarehouseThresholds({
    required int minStock,
    required int maxStock,
  }) =>
      _miscService.updateWarehouseThresholds(
        minStock: minStock,
        maxStock: maxStock,
      );

  Future<Map<String, dynamic>> updateNotifications({
    required bool notifyLowStock,
    required bool notifyNewSale,
    required bool notifyCost,
  }) =>
      _miscService.updateNotifications(
        notifyLowStock: notifyLowStock,
        notifyNewSale: notifyNewSale,
        notifyCost: notifyCost,
      );

  Future<Map<String, dynamic>> getNotifications() =>
      _miscService.getNotifications();

  Future<bool> markNotificationsAsRead({int? notificationId}) =>
      _miscService.markNotificationsAsRead(notificationId: notificationId);

  Future<Map<String, dynamic>> sendFeedback(String message) =>
      _miscService.sendFeedback(message);

  Future<Map<String, dynamic>> sendChatMessage(String message) =>
      _miscService.sendChatMessage(message);

  // ─── Processed Products ─────────────────────────────────────────────────────
  Future<List<ProcessedProduct>> getFarmerProcessedProducts({
    int page = 1,
    String? search,
    String? status,
  }) =>
      _processedProductService.getFarmerProcessedProducts(
        page: page,
        search: search,
        status: status,
      );

  Future<List<ProcessedProduct>> getSuperAdminProcessedProducts({
    int page = 1,
    String? search,
    String? status,
    int? ownerId,
  }) =>
      _processedProductService.getSuperAdminProcessedProducts(
        page: page,
        search: search,
        status: status,
        ownerId: ownerId,
      );

  Future<List<ProcessedProduct>> getPublicCatalog({int page = 1, String? search}) =>
      _processedProductService.getPublicCatalog(page: page, search: search);

  Future<ProcessedProduct?> getProcessedProduct(int id) =>
      _processedProductService.getProcessedProduct(id);

  Future<Map<String, dynamic>> createProcessedProduct({
    required String name,
    required double price,
    int stock = 0,
    String? unit = 'pcs',
    String? description,
    String? status,
    XFile? photoFile,
  }) =>
      _processedProductService.createProcessedProduct(
        name: name,
        price: price,
        stock: stock,
        unit: unit,
        description: description,
        status: status,
        photoFile: photoFile,
      );

  Future<Map<String, dynamic>> updateProcessedProduct(
    int id, {
    String? name,
    double? price,
    int? stock,
    String? unit,
    String? description,
    String? status,
    XFile? photoFile,
  }) =>
      _processedProductService.updateProcessedProduct(
        id,
        name: name,
        price: price,
        stock: stock,
        unit: unit,
        description: description,
        status: status,
        photoFile: photoFile,
      );

  Future<bool> deleteProcessedProduct(int id) =>
      _processedProductService.deleteProcessedProduct(id);

  Future<bool> updateProductStatusBySuperAdmin(int id, String status) =>
      _processedProductService.updateStatusBySuperAdmin(id, status);

  // ─── Super Admin Aggregate Reports ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getFarmerProfitLossAggregate({
    String? startDate,
    String? endDate,
  }) =>
      _superAdminService.getFarmerProfitLossAggregate(
        startDate: startDate,
        endDate: endDate,
      );

  // ─── Super Admin Order Tracking ─────────────────────────────────────────────
  Future<List<OrderModel>> getSuperAdminOrders({
    String? status,
    String? search,
    int page = 1,
  }) =>
      _orderService.getSuperAdminOrders(
        status: status,
        search: search,
        page: page,
      );

  Future<OrderModel?> getSuperAdminOrderDetail(int id) =>
      _orderService.getSuperAdminOrderDetail(id);

  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) =>
      _orderService.updateOrderStatus(id, status);

  Future<Map<String, dynamic>> completeOrder(int id) =>
      _orderService.completeOrder(id);

  Future<Map<String, dynamic>> cancelOrder(int id) =>
      _orderService.cancelOrder(id);

  // ─── Farmer Groups (Poktan) ────────────────────────────────────────────────
  Future<List<FarmerGroup>> getActiveFarmerGroups() =>
      _farmerGroupService.getActiveFarmerGroups();

  Future<List<FarmerGroup>> getSuperAdminFarmerGroups() =>
      _farmerGroupService.getSuperAdminFarmerGroups();

  Future<Map<String, dynamic>?> getFarmerGroupDetail(int id) =>
      _farmerGroupService.getFarmerGroupDetail(id);

  Future<Map<String, dynamic>> createFarmerGroup(Map<String, dynamic> payload) =>
      _farmerGroupService.createFarmerGroup(payload);

  Future<Map<String, dynamic>> updateFarmerGroup(int id, Map<String, dynamic> payload) =>
      _farmerGroupService.updateFarmerGroup(id, payload);

  Future<Map<String, dynamic>> deleteFarmerGroup(int id) =>
      _farmerGroupService.deleteFarmerGroup(id);

  Future<Map<String, dynamic>> assignFarmerToPoktan(int userId, int farmerGroupId) =>
      _farmerGroupService.assignMember(userId, farmerGroupId);
}
