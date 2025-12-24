import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  final String id;
  final String assetCode;
  final String? productId;
  final String? productCode;
  final String name;
  final String categoryId;
  final String? categoryName;
  
  // ✅ CHANGED: ownership menggantikan assetCategory
  final String ownership; // milik_sendiri, milik_customer
  
  final String assetType; // mesin, sparepart
  final String status; // available, saleable, loanable, disposed, sold, borrowed, lent, returned
  final int quantity;
  
  // ✅ CHANGED: sourceType sekarang supplier atau manual
  final String sourceType; // supplier, manual
  
  final String? divisionId;
  final String? divisionName;
  final String? divisionCode;
  final double? purchasePrice;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // BEACUKAI IN
  final String? beacukaiDocIn;
  final DateTime? beacukaiTglIn;
  final String? beacukaiNoIn;
  final String? beacukaiNoAjuIn;
  
  // BEACUKAI OUT
  final String? beacukaiDocOut;
  final DateTime? beacukaiTglOut;
  final String? beacukaiNoOut;
  final String? beacukaiNoAjuOut;
  
  final String? lpbId;

  const AssetModel({
    required this.id,
    required this.assetCode,
    this.productId,
    this.productCode,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.ownership,
    required this.assetType,
    required this.status,
    required this.quantity,
    required this.sourceType,
    this.divisionId,
    this.divisionName,
    this.divisionCode,
    this.purchasePrice,
    this.assignedTo,
    this.assignedToName,
    this.assignedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.beacukaiDocIn,
    this.beacukaiTglIn,
    this.beacukaiNoIn,
    this.beacukaiNoAjuIn,
    this.beacukaiDocOut,
    this.beacukaiTglOut,
    this.beacukaiNoOut,
    this.beacukaiNoAjuOut,
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
      ownership: json['ownership'] as String? ?? 'milik_sendiri',
      assetType: json['asset_type'] as String? ?? 'mesin',
      status: json['status'] as String? ?? 'available',
      quantity: json['quantity'] as int? ?? 1,
      sourceType: json['source_type'] as String? ?? 'supplier',
      divisionId: json['division_id'] as String?,
      divisionName: json['division_name'] as String?,
      divisionCode: json['division_code'] as String?,
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
      beacukaiDocIn: json['beacukai_doc_in'] as String?,
      beacukaiTglIn: json['beacukai_tgl_in'] != null
          ? DateTime.parse(json['beacukai_tgl_in'] as String)
          : null,
      beacukaiNoIn: json['beacukai_no_in'] as String?,
      beacukaiNoAjuIn: json['beacukai_no_aju_in'] as String?,
      beacukaiDocOut: json['beacukai_doc_out'] as String?,
      beacukaiTglOut: json['beacukai_tgl_out'] != null
          ? DateTime.parse(json['beacukai_tgl_out'] as String)
          : null,
      beacukaiNoOut: json['beacukai_no_out'] as String?,
      beacukaiNoAjuOut: json['beacukai_no_aju_out'] as String?,
      lpbId: json['lpb_id'] as String?,
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'asset_code': assetCode,
      'product_id': productId,
      'name': name,
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
    String? ownership,
    String? assetType,
    String? status,
    int? quantity,
    String? sourceType,
    String? divisionId,
    String? divisionName,
    String? divisionCode,
    double? purchasePrice,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? beacukaiDocIn,
    DateTime? beacukaiTglIn,
    String? beacukaiNoIn,
    String? beacukaiNoAjuIn,
    String? beacukaiDocOut,
    DateTime? beacukaiTglOut,
    String? beacukaiNoOut,
    String? beacukaiNoAjuOut,
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
      ownership: ownership ?? this.ownership,
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      sourceType: sourceType ?? this.sourceType,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
      divisionCode: divisionCode ?? this.divisionCode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedDate: assignedDate ?? this.assignedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      beacukaiDocIn: beacukaiDocIn ?? this.beacukaiDocIn,
      beacukaiTglIn: beacukaiTglIn ?? this.beacukaiTglIn,
      beacukaiNoIn: beacukaiNoIn ?? this.beacukaiNoIn,
      beacukaiNoAjuIn: beacukaiNoAjuIn ?? this.beacukaiNoAjuIn,
      beacukaiDocOut: beacukaiDocOut ?? this.beacukaiDocOut,
      beacukaiTglOut: beacukaiTglOut ?? this.beacukaiTglOut,
      beacukaiNoOut: beacukaiNoOut ?? this.beacukaiNoOut,
      beacukaiNoAjuOut: beacukaiNoAjuOut ?? this.beacukaiNoAjuOut,
      lpbId: lpbId ?? this.lpbId,
    );
  }

  // ✅ UPDATED HELPERS
  bool get isMilikSendiri => ownership == 'milik_sendiri';
  bool get isMilikCustomer => ownership == 'milik_customer';
  bool get isFromSupplier => sourceType == 'supplier';
  bool get isManualEntry => sourceType == 'manual';

  // Status helpers
  bool get isAvailable => status == 'available';
  bool get isSaleable => status == 'saleable';
  bool get isLoanable => status == 'loanable';
  bool get isDisposed => status == 'disposed';
  bool get isSold => status == 'sold';
  bool get isBorrowed => status == 'borrowed';
  bool get isLent => status == 'lent';
  bool get isReturned => status == 'returned';

  bool get hasBeacukaiIn => beacukaiNoIn != null && beacukaiNoIn!.isNotEmpty;
  bool get hasBeacukaiOut => beacukaiNoOut != null && beacukaiNoOut!.isNotEmpty;

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

  /// Helper: Ownership display name
  String get ownershipDisplayName {
    switch (ownership) {
      case 'milik_sendiri':
        return 'Milik Sendiri';
      case 'milik_customer':
        return 'Milik Customer';
      default:
        return ownership;
    }
  }

  /// Helper: Status display name
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Available';
      case 'saleable':
        return 'Saleable';
      case 'loanable':
        return 'Loanable';
      case 'disposed':
        return 'Disposed';
      case 'sold':
        return 'Sold';
      case 'borrowed':
        return 'Borrowed';
      case 'lent':
        return 'Lent';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }

  /// Helper: Source display
  String get sourceDisplayName {
    switch (sourceType) {
      case 'supplier':
        return 'From Supplier (LPB)';
      case 'manual':
        return 'Manual Entry';
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
        ownership,
        assetType,
        status,
        quantity,
        sourceType,
        divisionId,
        divisionName,
        divisionCode,
        purchasePrice,
        assignedTo,
        assignedToName,
        assignedDate,
        notes,
        createdAt,
        updatedAt,
        beacukaiDocIn,
        beacukaiTglIn,
        beacukaiNoIn,
        beacukaiNoAjuIn,
        beacukaiDocOut,
        beacukaiTglOut,
        beacukaiNoOut,
        beacukaiNoAjuOut,
        lpbId,
      ];
}

// Asset Transaction Models tetap sama
class AssetTransactionModel extends Equatable {
  final String id;
  final String? inventoryId;
  final String? assetId;
  final String transactionType;
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

// Asset Loan History - TETAP SAMA (untuk internal tracking)
class AssetLoanHistoryModel extends Equatable {
  final String id;
  final String assetId;
  final String? assetCode;
  final String? assetName;
  final String loanType;
  final String? fromDivisionId;
  final String? fromDivisionName;
  final String? toDivisionId;
  final String? toDivisionName;
  final String? borrowedBy;
  final String? borrowedByName;
  final String? externalCompanyName;
  final String? externalCompanyAddress;
  final int quantity;
  final DateTime loanDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status;
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