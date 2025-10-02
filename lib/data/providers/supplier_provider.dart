import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/supplier_model.dart';
import 'package:erp_purchasing_apps/data/repositories/supplier_repository.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

final supplierListProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  return await repo.getAllSuppliers();
});

final activeSupplierListProvider =
    FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  return await repo.getActiveSuppliers();
});
