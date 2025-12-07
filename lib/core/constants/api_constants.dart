class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // ============================================
  // AUTH ENDPOINTS
  // ============================================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // ============================================
  // MASTER DATA ENDPOINTS
  // ============================================

  /// Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static const String categoryTree = '/categories/tree';

  /// Products
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static String productsBySupplier(String supplierId) => '/products/supplier/$supplierId';

  /// Suppliers
  static const String suppliers = '/suppliers';
  static String supplierById(String id) => '/suppliers/$id';

  /// Divisions
  static const String divisions = '/divisions';
  static String divisionById(String id) => '/divisions/$id';

  /// Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // ============================================
  // ASSESSMENT ENDPOINTS
  // ============================================

  /// Product Assessment
  static const String productAssessments = '/assessments/products';
  static String productAssessmentById(String id) => '/assessments/products/$id';
  static String verifyProductAssessment(String id) =>
      '/assessments/products/$id/verify';
  static String approveProductAssessment(String id) =>
      '/assessments/products/$id/approve';
  static String rejectProductAssessment(String id) =>
      '/assessments/products/$id/reject';

  /// Supplier Assessment
  static const String supplierAssessments = '/assessments/suppliers';
  static String supplierAssessmentById(String id) =>
      '/assessments/suppliers/$id';
  static String verifySupplierAssessment(String id) =>
      '/assessments/suppliers/$id/verify';
  static String approveSupplierAssessment(String id) =>
      '/assessments/suppliers/$id/approve';
  static String rejectSupplierAssessment(String id) =>
      '/assessments/suppliers/$id/reject';

  // ============================================
  // PURCHASE FLOW ENDPOINTS
  // ============================================

  /// Purchase Requisition (PR)
  static const String purchaseRequisitions = '/purchase-requisitions';
  static String prById(String id) => '/purchase-requisitions/$id';
  static String approvePR(String id) => '/purchase-requisitions/$id/approve';
  static String rejectPR(String id) => '/purchase-requisitions/$id/reject';
  static String closePR(String id) => '/purchase-requisitions/$id/close';

  /// Purchase Order (PO)
  static const String purchaseOrders = '/purchase-orders';
  static String poById(String id) => '/purchase-orders/$id';
  static String approvePO(String id) => '/purchase-orders/$id/approve';
  static String cancelPO(String id) => '/purchase-orders/$id/cancel';
  static const String prGroupings = '/purchase-orders/helpers/pr-groupings';

  /// Shipment
  static const String shipments = '/shipments';
  static String shipmentById(String id) => '/shipments/$id';
  static String shipmentsByPO(String poId) => '/shipments/po/$poId';
  static const String scanQR = '/shipments/scan-qr';
  static String regenerateQR(String id) => '/shipments/$id/regenerate-qr';

  /// LPB (Laporan Penerimaan Barang)
  static const String lpbs = '/lpbs';
  static String lpbById(String id) => '/lpbs/$id';
  static String lpbsByPO(String poId) => '/lpbs/po/$poId';
  static String createLPBFromShipment(String shipmentId) =>
      '/lpbs/from-shipment/$shipmentId';
  static String completeLPB(String id) => '/lpbs/$id/complete';

  // ============================================
  // PAYMENT ENDPOINTS
  // ============================================
  static const String payments = '/payments';
  static String paymentById(String id) => '/payments/$id';
  static const String unpaidLPBsGrouped = '/payments/unpaid-lpbs/grouped';
  static String unpaidLPBsBySupplier(String supplierId) =>
      '/payments/unpaid-lpbs/supplier/$supplierId';
  static String processPayment(String id) => '/payments/$id/process';
  static String verifyPayment(String id) => '/payments/$id/verify';
  static String cancelPayment(String id) => '/payments/$id/cancel';

  // ============================================
  // WAREHOUSE/INVENTORY ENDPOINTS
  // ============================================

  /// Inventory
  static const String inventory = '/inventory';
  static String inventoryById(String id) => '/inventory/$id';
  static String adjustInventory(String id) => '/inventory/$id/adjust';
  static String inventoryTransactions(String id) =>
      '/inventory/$id/transactions';

  /// Assets
  static const String assets = '/assets';
  static String assetById(String id) => '/assets/$id';
  static String assignAsset(String id) => '/assets/$id/assign';
  static String assetTransactions(String id) => '/assets/$id/transactions';

  // ============================================
  // TRACKING & HISTORY ENDPOINTS
  // ============================================

  /// Document Tracking
  static const String documentTracking = '/tracking/documents';
  static String documentTrackingById(String id) => '/tracking/documents/$id';
  static String trackingTimeline(String prId) => '/tracking/timeline/$prId';

  /// Activity Logs
  static const String activityLogs = '/tracking/activities';
  static String userActivityHistory(String userId) =>
      '/tracking/activities/user/$userId';

  /// Item Tracking
  static const String itemTracking = '/tracking/items';
  static String itemTrackingById(String id) => '/tracking/items/$id';
  static String itemTrackingByProduct(String productId) =>
      '/tracking/items/product/$productId';

  /// Purchase Flow Summary
  static const String purchaseFlowSummary = '/tracking/flow/summary';
  static String flowDetailsByPR(String prId) => '/tracking/flow/pr/$prId';

  // ============================================
  // DASHBOARD ENDPOINTS
  // ============================================
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardActivities = '/dashboard/activities';
  static const String dashboardItems = '/dashboard/items';
  static const String dashboardPerformance = '/dashboard/performance';
  static const String dashboardTrends = '/dashboard/trends';

  // ============================================
  // SUPPLIER PORTAL ENDPOINTS
  // ============================================

  /// Supplier POs
  static const String supplierPOs = '/supplier/pos';
  static String supplierPOById(String id) => '/supplier/pos/$id';

  /// Supplier Shipments
  static const String supplierShipments = '/supplier/shipments';
  static String supplierShipmentById(String id) => '/supplier/shipments/$id';

  // ============================================
  // UTILITY ENDPOINTS
  // ============================================
  static const String health = '/health';
  static const String ping = '/ping';
}

/// API Query Parameter Keys
class ApiQueryKeys {
  ApiQueryKeys._();

  // Common
  static const String page = 'page';
  static const String pageSize = 'page_size';
  static const String search = 'search';
  static const String sort = 'sort';
  static const String order = 'order';

  // Filters
  static const String status = 'status';
  static const String role = 'role';
  static const String divisionId = 'division_id';
  static const String categoryId = 'category_id';
  static const String supplierId = 'supplier_id';
  static const String year = 'year';
  static const String isActive = 'is_active';
  static const String processingType = 'processing_type';
}
