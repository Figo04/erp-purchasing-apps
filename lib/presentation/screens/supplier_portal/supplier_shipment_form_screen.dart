import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

class SupplierShipmentFormScreen extends ConsumerStatefulWidget {
  final String? poId;

  const SupplierShipmentFormScreen({super.key, this.poId});

  @override
  ConsumerState<SupplierShipmentFormScreen> createState() =>
      _SupplierShipmentFormScreenState();
}

class _SupplierShipmentFormScreenState
    extends ConsumerState<SupplierShipmentFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
