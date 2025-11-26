import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/repositories/tracking_repository.dart';
import 'package:erp_purchasing_apps/data/models/tracking_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository();
});

// ============================================
// DASHBOARD STATS MODEL
// ============================================

class DashboardStats {
  final int totalPR;
  final int totalPO;
  final int totalLPB;
  final int totalPayments;
  final int pendingPR;
  final int pendingPO;
  final int pendingPayments;
  final int overduePayments;
  final int lowStockItems;
  final int incomingShipments;
  final double totalSpending;

  DashboardStats({
    required this.totalPR,
    required this.totalPO,
    required this.totalLPB,
    required this.totalPayments,
    required this.pendingPR,
    required this.pendingPO,
    required this.pendingPayments,
    required this.overduePayments,
    required this.lowStockItems,
    required this.incomingShipments,
    required this.totalSpending,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPR: json['total_pr'] ?? 0,
      totalPO: json['total_po'] ?? 0,
      totalLPB: json['total_lpb'] ?? 0,
      totalPayments: json['total_payments'] ?? 0,
      pendingPR: json['pending_pr'] ?? 0,
      pendingPO: json['pending_po'] ?? 0,
      pendingPayments: json['pending_payments'] ?? 0,
      overduePayments: json['overdue_payments'] ?? 0,
      lowStockItems: json['low_stock_items'] ?? 0,
      incomingShipments: json['incoming_shipments'] ?? 0,
      totalSpending: (json['total_spending'] ?? 0).toDouble(),
    );
  }
}

// ============================================
// DASHBOARD STATS PROVIDER
// ============================================

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final apiService = ApiService();
  
  try {
    final response = await apiService.get(ApiEndpoints.dashboardStats);
    
    if (response.success && response.data != null) {
      return DashboardStats.fromJson(response.data);
    }
    
    // Fallback empty stats
    return DashboardStats(
      totalPR: 0,
      totalPO: 0,
      totalLPB: 0,
      totalPayments: 0,
      pendingPR: 0,
      pendingPO: 0,
      pendingPayments: 0,
      overduePayments: 0,
      lowStockItems: 0,
      incomingShipments: 0,
      totalSpending: 0,
    );
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
});

// ============================================
// DASHBOARD OVERVIEW PROVIDER
// ============================================

class DashboardOverview {
  final List<PurchaseFlowSummary> recentFlows;
  final List<ActivityLog> recentActivities;
  final Map<String, int> statusCounts;

  DashboardOverview({
    required this.recentFlows,
    required this.recentActivities,
    required this.statusCounts,
  });
}

final dashboardOverviewProvider = FutureProvider.autoDispose<DashboardOverview>((ref) async {
  final apiService = ApiService();
  
  try {
    final response = await apiService.get(ApiEndpoints.dashboardOverview);
    
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      
      return DashboardOverview(
        recentFlows: (data['recent_flows'] as List<dynamic>?)
                ?.map((e) => PurchaseFlowSummary.fromJson(e))
                .toList() ??
            [],
        recentActivities: (data['recent_activities'] as List<dynamic>?)
                ?.map((e) => ActivityLog.fromJson(e))
                .toList() ??
            [],
        statusCounts: Map<String, int>.from(data['status_counts'] ?? {}),
      );
    }
    
    return DashboardOverview(
      recentFlows: [],
      recentActivities: [],
      statusCounts: {},
    );
  } catch (e) {
    throw Exception('Failed to load dashboard overview: $e');
  }
});

// ============================================
// RECENT ACTIVITIES PROVIDER (Standalone)
// ============================================

final recentActivitiesProvider = FutureProvider.autoDispose<List<ActivityLog>>((ref) async {
  final repository = ref.read(trackingRepositoryProvider);
  
  try {
    final logs = await repository.getAllActivityLogs();
    // Return last 10
    return logs.take(10).toList();
  } catch (e) {
    return [];
  }
});

// ============================================
// PURCHASE FLOW SUMMARY PROVIDER
// ============================================

final purchaseFlowSummaryProvider = FutureProvider.autoDispose
    .family<List<PurchaseFlowSummary>, PurchaseFlowFilterParams>((ref, params) async {
  final repository = ref.read(trackingRepositoryProvider);
  
  return await repository.getPurchaseFlowSummary(
    divisionId: params.divisionId,
    processingType: params.processingType,
    overallStatus: params.overallStatus,
    fromDate: params.fromDate,
    toDate: params.toDate,
    search: params.search,
  );
});

class PurchaseFlowFilterParams {
  final String? divisionId;
  final String? processingType;
  final String? overallStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? search;

  PurchaseFlowFilterParams({
    this.divisionId,
    this.processingType,
    this.overallStatus,
    this.fromDate,
    this.toDate,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseFlowFilterParams &&
          runtimeType == other.runtimeType &&
          divisionId == other.divisionId &&
          processingType == other.processingType &&
          overallStatus == other.overallStatus &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          search == other.search;

  @override
  int get hashCode =>
      divisionId.hashCode ^
      processingType.hashCode ^
      overallStatus.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode ^
      search.hashCode;
}

// ============================================
// ITEM TRACKING SUMMARY PROVIDER
// ============================================

final itemTrackingSummaryProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.read(trackingRepositoryProvider);
  
  try {
    final items = await repository.getAllItemTracking();
    
    return {
      'total': items.length,
      'requested': items.where((i) => i.currentStage == 'requested').length,
      'ordered': items.where((i) => i.currentStage == 'ordered').length,
      'shipped': items.where((i) => i.currentStage == 'shipped').length,
      'received': items.where((i) => i.currentStage == 'received').length,
      'in_stock': items.where((i) => i.currentStage == 'in_stock').length,
      'complete': items.where((i) => i.isComplete).length,
    };
  } catch (e) {
    return {};
  }
});

// ============================================
// PERFORMANCE METRICS PROVIDER
// ============================================

class PerformanceMetrics {
  final double avgProcessingTime;
  final double completionRate;
  final int totalTransactions;
  final Map<String, dynamic> trends;

  PerformanceMetrics({
    required this.avgProcessingTime,
    required this.completionRate,
    required this.totalTransactions,
    required this.trends,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      avgProcessingTime: (json['avg_processing_time'] ?? 0).toDouble(),
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      trends: Map<String, dynamic>.from(json['trends'] ?? {}),
    );
  }
}

final performanceMetricsProvider = FutureProvider.autoDispose<PerformanceMetrics>((ref) async {
  final apiService = ApiService();
  
  try {
    final response = await apiService.get(ApiEndpoints.dashboardPerformance);
    
    if (response.success && response.data != null) {
      return PerformanceMetrics.fromJson(response.data);
    }
    
    return PerformanceMetrics(
      avgProcessingTime: 0,
      completionRate: 0,
      totalTransactions: 0,
      trends: {},
    );
  } catch (e) {
    throw Exception('Failed to load performance metrics: $e');
  }
});