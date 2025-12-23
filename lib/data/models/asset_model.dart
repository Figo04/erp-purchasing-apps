import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  final String id;
  final String assetCode;
  final String? productId;
  final String? productCode;
  final String name;
  final String categoryId;
  final String? categoryName;
  final String assetCategory; // pending, loanable, saleable, disposed
  final String assetType; // mesin, sparepart
  final String? status; // available, borrowed, lent, sold, returned (NULL if disposed)
  final int quantity;
  final String sourceType; // supplier, external
  final String? divisionId;
  final String? divisionName;
  final String? divisionCode;
  final String? externalSourceId;
  final String? externalCompanyName;
  final double? purchasePrice;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // BEACUKAI FIELDS
  final String? beacukaiDoc;
  final DateTime? beacukaiTgl;
  final String? beacukaiNo;
  final String? beacukaiNoAju;
  final String? lpbId;

  const AssetModel({
    required this.id,
    required this.assetCode,
    this.productId,
    this.productCode,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.assetCategory,
    required this.assetType,
    required this.status,
    required this.quantity,
    required this.sourceType,
    this.divisionId,
    this.divisionName,
    this.divisionCode,
    this.externalSourceId,
    this.externalCompanyName,
    this.purchasePrice,
    this.assignedTo,
    this.assignedToName,
    this.assignedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.beacukaiDoc,
    this.beacukaiTgl,
    this.beacukaiNo,
    this.beacukaiNoAju,
    this.lpbId,
  });

  /// From JSON (Backend Response)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      assetCode: json['asset_code'] as String,
      productId: json['product_id'] as String?,
      productCode: json['product_code'] as String?,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      assetCategory: json['asset_category'] as String? ?? 'loanable',
      assetType: json['asset_type'] as String? ?? 'mesin',
      status: json['status'] as String? ?? 'available',
      quantity: json['quantity'] as int? ?? 1,
      sourceType: json['source_type'] as String? ?? 'supplier',
      divisionId: json['division_id'] as String?,
      divisionName: json['division_name'] as String?,
      divisionCode: json['division_code'] as String?,
      externalSourceId: json['external_source_id'] as String?,
      externalCompanyName: json['external_company_name'] as String?,
      purchasePrice: json['purchase_price'] != null
          ? double.parse(json['purchase_price'].toString())
          : null,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      beacukaiDoc: json['beacukai_doc'] as String?,
      beacukaiTgl: json['beacukai_tgl'] != null
          ? DateTime.parse(json['beacukai_tgl'] as String)
          : null,
      beacukaiNo: json['beacukai_no'] as String?,
      beacukaiNoAju: json['beacukai_no_aju'] as String?,
      lpbId: json['lpb_id'] as String?,
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'asset_code': assetCode,
      'product_id': productId,
      'name': name,
      'asset_category': assetCategory,
      'asset_type': assetType,
      'quantity': quantity,
      'division_id': divisionId,
      'purchase_price': purchasePrice,
      'notes': notes,
    };
  }

  /// Copy with
  AssetModel copyWith({
    String? id,
    String? assetCode,
    String? productId,
    String? productCode,
    String? name,
    String? categoryId,
    String? categoryName,
    String? assetCategory,
    String? assetType,
    String? status,
    int? quantity,
    String? sourceType,
    String? divisionId,
    String? divisionName,
    String? divisionCode,
    String? externalSourceId,
    String? externalCompanyName,
    double? purchasePrice,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? beacukaiDoc,
    DateTime? beacukaiTgl,
    String? beacukaiNo,
    String? beacukaiNoAju,
    String? lpbId,
  }) {
    return AssetModel(
      id: id ?? this.id,
      assetCode: assetCode ?? this.assetCode,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      assetCategory: assetCategory ?? this.assetCategory,
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      sourceType: sourceType ?? this.sourceType,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
      divisionCode: divisionCode ?? this.divisionCode,
      externalSourceId: externalSourceId ?? this.externalSourceId,
      externalCompanyName: externalCompanyName ?? this.externalCompanyName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedDate: assignedDate ?? this.assignedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      beacukaiDoc: beacukaiDoc ?? this.beacukaiDoc,
      beacukaiTgl: beacukaiTgl ?? this.beacukaiTgl,
      beacukaiNo: beacukaiNo ?? this.beacukaiNo,
      beacukaiNoAju: beacukaiNoAju ?? this.beacukaiNoAju,
      lpbId: lpbId ?? this.lpbId,
    );
  }


  /// Helper: Check if has status
  bool get hasStatus => status != null && status!.isNotEmpty;

  /// Helper: Check if asset is borrowed/lent
  bool get isBorrowed => status == 'borrowed';
  bool get isLent => status == 'lent';
  bool get isReturned => status == 'returned';

  /// Helper: Check if asset is available
  bool get isAvailable => status == 'available';

  /// Helper: Check if from external source
  bool get isFromExternal => sourceType == 'external';

  /// Helper: Check if has beacukai
  bool get hasBeacukai => beacukaiNo != null && beacukaiNo!.isNotEmpty;

  /// Helper: Check if asset category is pending
  bool get isPending => assetCategory == 'pending';

  /// Helper: Check if asset is disposed
  bool get isDisposed => assetCategory == 'disposed';


  /// Helper: Asset Type display name
  String get assetTypeDisplayName {
    switch (assetType) {
      case 'mesin':
        return 'Mesin';
      case 'sparepart':
        return 'Sparepart';
      default:
        return assetType;
    }
  }

  /// Helper: Category display name
  String get categoryDisplayName {
    switch (assetCategory) {
      case 'loanable':
        return 'Loanable';
      case 'saleable':
        return 'Saleable';
      case 'pending':
        return 'Pending Classification';
      case 'disposed':
        return 'Disposed';
      default:
        return assetCategory;
    }
  }

  /// Helper: Status display name
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Available';
      case 'borrowed':
        return 'Borrowed';
      case 'lent':
        return 'Lent';
      case 'sold':
        return 'Sold';
      case 'returned':
        return 'Returned';
      case 'maintenance':
        return 'Maintenance'; // Keep for backward compatibility
      default:
        return status!;
    }
  }

  /// Helper: Source display
  String get sourceDisplayName {
    switch (sourceType) {
      case 'supplier':
        return 'Supplier';
      case 'external':
        return externalCompanyName ?? 'External';
      default:
        return sourceType;
    }
  }

  @override
  List<Object?> get props => [
        id,
        assetCode,
        productId,
        productCode,
        name,
        categoryId,
        categoryName,
        assetCategory,
        assetType,
        status,
        quantity,
        sourceType,
        divisionId,
        divisionName,
        divisionCode,
        externalSourceId,
        externalCompanyName,
        purchasePrice,
        assignedTo,
        assignedToName,
        assignedDate,
        notes,
        createdAt,
        updatedAt,
        beacukaiDoc,
        beacukaiTgl,
        beacukaiNo,
        beacukaiNoAju,
        lpbId,
      ];
}

/// Asset Transaction Model (shared with Inventory)
class AssetTransactionModel extends Equatable {
  final String id;
  final String? inventoryId;
  final String? assetId;
  final String transactionType; // in, out, transfer, adjustment
  final int quantity;
  final String? fromLocation;
  final String? toLocation;
  final String? referenceType;
  final String? referenceId;
  final String performedBy;
  final String? performedByName;
  final String? notes;
  final DateTime createdAt;

  const AssetTransactionModel({
    required this.id,
    this.inventoryId,
    this.assetId,
    required this.transactionType,
    required this.quantity,
    this.fromLocation,
    this.toLocation,
    this.referenceType,
    this.referenceId,
    required this.performedBy,
    this.performedByName,
    this.notes,
    required this.createdAt,
  });

  factory AssetTransactionModel.fromJson(Map<String, dynamic> json) {
    return AssetTransactionModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String?,
      assetId: json['asset_id'] as String?,
      transactionType: json['transaction_type'] as String,
      quantity: json['quantity'] as int,
      fromLocation: json['from_location'] as String?,
      toLocation: json['to_location'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      performedBy: json['performed_by'] as String,
      performedByName: json['performed_by_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        inventoryId,
        assetId,
        transactionType,
        quantity,
        fromLocation,
        toLocation,
        referenceType,
        referenceId,
        performedBy,
        performedByName,
        notes,
        createdAt,
      ];
}

/// Asset Loan History Model - NEW
class AssetLoanHistoryModel extends Equatable {
  final String id;
  final String assetId;
  final String? assetCode;
  final String? assetName;
  final String loanType; // internal, external

  // Internal loan
  final String? fromDivisionId;
  final String? fromDivisionName;
  final String? toDivisionId;
  final String? toDivisionName;
  final String? borrowedBy;
  final String? borrowedByName;

  // External loan
  final String? externalCompanyName;
  final String? externalCompanyAddress;

  final int quantity;
  final DateTime loanDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status; // ongoing, returned, overdue
  final String? loanDocumentUrl;
  final String? returnDocumentUrl;
  final String? notes;
  final String createdBy;
  final String? createdByName;
  final String? returnedBy;
  final String? returnedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? daysOverdue;

  const AssetLoanHistoryModel({
    required this.id,
    required this.assetId,
    this.assetCode,
    this.assetName,
    required this.loanType,
    this.fromDivisionId,
    this.fromDivisionName,
    this.toDivisionId,
    this.toDivisionName,
    this.borrowedBy,
    this.borrowedByName,
    this.externalCompanyName,
    this.externalCompanyAddress,
    required this.quantity,
    required this.loanDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.loanDocumentUrl,
    this.returnDocumentUrl,
    this.notes,
    required this.createdBy,
    this.createdByName,
    this.returnedBy,
    this.returnedByName,
    required this.createdAt,
    required this.updatedAt,
    this.daysOverdue,
  });

  factory AssetLoanHistoryModel.fromJson(Map<String, dynamic> json) {
    return AssetLoanHistoryModel(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      assetCode: json['asset_code'] as String?,
      assetName: json['asset_name'] as String?,
      loanType: json['loan_type'] as String,
      fromDivisionId: json['from_division_id'] as String?,
      fromDivisionName: json['from_division_name'] as String?,
      toDivisionId: json['to_division_id'] as String?,
      toDivisionName: json['to_division_name'] as String?,
      borrowedBy: json['borrowed_by'] as String?,
      borrowedByName: json['borrowed_by_name'] as String?,
      externalCompanyName: json['external_company_name'] as String?,
      externalCompanyAddress: json['external_company_address'] as String?,
      quantity: json['quantity'] as int,
      loanDate: DateTime.parse(json['loan_date'] as String),
      expectedReturnDate: json['expected_return_date'] != null
          ? DateTime.parse(json['expected_return_date'] as String)
          : null,
      actualReturnDate: json['actual_return_date'] != null
          ? DateTime.parse(json['actual_return_date'] as String)
          : null,
      status: json['status'] as String,
      loanDocumentUrl: json['loan_document_url'] as String?,
      returnDocumentUrl: json['return_document_url'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String?,
      returnedBy: json['returned_by'] as String?,
      returnedByName: json['returned_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      daysOverdue: json['days_overdue'] as int?,
    );
  }

  bool get isOngoing => status == 'ongoing';
  bool get isReturned => status == 'returned';
  bool get isOverdue =>
      status == 'overdue' || (daysOverdue != null && daysOverdue! > 0);
  bool get isInternal => loanType == 'internal';
  bool get isExternal => loanType == 'external';

  @override
  List<Object?> get props => [
        id,
        assetId,
        loanType,
        quantity,
        loanDate,
        status,
        createdAt,
      ];
}
