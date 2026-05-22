// App state provider — ERP for J3D SQ

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<StoreModel> _stores = [];
  List<TransactionModel> _transactions = [];
  List<ProductModel> _products = [];
  List<ContactModel> _contacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<StoreModel> get stores => _stores;
  List<TransactionModel> get transactions => _transactions;
  List<ProductModel> get products => _products;
  List<ContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Quick lookup map: productId -> ProductModel
  Map<String, ProductModel> get productsMap =>
      {for (final p in _products) p.id: p};

  AppState() {
    _init();
  }

  void _init() {
    _service.productsStream().listen((products) {
      _products = products;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error loading products: $e');
    });

    _service.storesStream().listen((stores) {
      _stores = stores;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error loading stores: $e');
      _isLoading = false;
      notifyListeners();
    });

    _service.transactionsStream().listen((txs) {
      _transactions = txs;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error loading transactions: $e');
    });

    _service.contactsStream().listen((contacts) {
      _contacts = contacts;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error loading contacts: $e');
    });
  }

  // ─── Search ──────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery) ||
            p.description.toLowerCase().contains(_searchQuery) ||
            p.category.label.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<StoreModel> get filteredStores {
    if (_searchQuery.isEmpty) return _stores;
    return _stores
        .where((s) =>
            s.name.toLowerCase().contains(_searchQuery) ||
            s.contactName.toLowerCase().contains(_searchQuery) ||
            s.address.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<ContactModel> get filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery) ||
            c.phone.contains(_searchQuery) ||
            c.email.toLowerCase().contains(_searchQuery) ||
            c.type.toLowerCase().contains(_searchQuery))
        .toList();
  }

  // ─── Product Operations ─────────────────────────────────

  Future<ProductModel> addProduct({
    required String name,
    required double price,
    required double productionCost,
    required int colorValue,
    String description = '',
    ProductCategory category = ProductCategory.llavero,
    CostBreakdown costBreakdown = const CostBreakdown(),
    double weightGrams = 0,
    int lowStockThreshold = 5,
  }) async {
    return await _service.addProduct(
      name: name,
      price: price,
      productionCost: productionCost,
      colorValue: colorValue,
      description: description,
      category: category,
      costBreakdown: costBreakdown,
      weightGrams: weightGrams,
      lowStockThreshold: lowStockThreshold,
    );
  }

  Future<void> updateProduct(String id, {
    String? name,
    double? price,
    double? productionCost,
    int? colorValue,
    String? description,
    String? categoryName,
    Map<String, dynamic>? costBreakdownMap,
    double? weightGrams,
    int? lowStockThreshold,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (price != null) updates['price'] = price;
    if (productionCost != null) updates['productionCost'] = productionCost;
    if (colorValue != null) updates['colorValue'] = colorValue;
    if (description != null) updates['description'] = description;
    if (categoryName != null) updates['category'] = categoryName;
    if (costBreakdownMap != null) updates['costBreakdown'] = costBreakdownMap;
    if (weightGrams != null) updates['weightGrams'] = weightGrams;
    if (lowStockThreshold != null) {
      updates['lowStockThreshold'] = lowStockThreshold;
    }
    if (updates.isNotEmpty) {
      await _service.updateProduct(id, updates);
    }
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Store Operations ────────────────────────────────────

  Future<StoreModel> addStore({
    required String name,
    required String contactName,
    required String address,
    required double commissionRate,
    String phone = '',
    String email = '',
    String notes = '',
  }) async {
    return await _service.addStore(
      name: name,
      contactName: contactName,
      address: address,
      commissionRate: commissionRate,
      phone: phone,
      email: email,
      notes: notes,
    );
  }

  Future<void> updateStore(String id, {
    String? name,
    String? contactName,
    String? address,
    double? commissionRate,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (contactName != null) updates['contactName'] = contactName;
    if (address != null) updates['address'] = address;
    if (commissionRate != null) updates['commissionRate'] = commissionRate;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (notes != null) updates['notes'] = notes;
    if (updates.isNotEmpty) {
      await _service.updateStore(id, updates);
    }
  }

  Future<void> deleteStore(String id) async {
    await _service.deleteStore(id);
  }

  StoreModel? getStoreById(String id) {
    try {
      return _stores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Contact Operations ──────────────────────────────────

  Future<ContactModel> addContact({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
    String type = 'cliente',
    String? linkedStoreId,
  }) async {
    return await _service.addContact(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      type: type,
      linkedStoreId: linkedStoreId,
    );
  }

  Future<void> updateContact(String id, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? type,
    String? linkedStoreId,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (address != null) updates['address'] = address;
    if (notes != null) updates['notes'] = notes;
    if (type != null) updates['type'] = type;
    if (linkedStoreId != null) updates['linkedStoreId'] = linkedStoreId;
    if (updates.isNotEmpty) {
      await _service.updateContact(id, updates);
    }
  }

  Future<void> deleteContact(String id) async {
    await _service.deleteContact(id);
  }

  // ─── Delivery Operations ─────────────────────────────────

  Future<void> addDelivery({
    required StoreModel store,
    required Map<String, int> items,
  }) async {
    await _service.addDelivery(
      store: store,
      items: items,
      productsMap: productsMap,
    );
  }

  // ─── Sale / Cobro Operations ─────────────────────────────

  Future<void> registerSale({
    required StoreModel store,
    required Map<String, int> currentStock,
  }) async {
    await _service.registerSale(
      store: store,
      currentStock: currentStock,
      productsMap: productsMap,
    );
  }

  // ─── Payment Operations ──────────────────────────────────

  Future<void> addPayment({
    required StoreModel store,
    required double amount,
    String? note,
  }) async {
    await _service.addPayment(store: store, amount: amount, note: note);
  }

  // ─── Delete Transaction ──────────────────────────────────

  Future<void> deleteTransaction(TransactionModel tx) async {
    await _service.deleteTransaction(tx);
  }

  // ─── Computed Values ─────────────────────────────────────

  double get totalInventoryValue {
    final pm = productsMap;
    return _stores.fold(0.0, (acc, s) => acc + s.inventoryValueWith(pm));
  }

  int get totalConsignment =>
      _stores.fold(0, (acc, s) => acc + s.totalStock);

  double get totalReceivable =>
      _stores.fold(0.0, (acc, s) => acc + s.balance);

  double get totalEstimatedProfit {
    final pm = productsMap;
    return _stores.fold(0.0, (acc, store) {
      double profit = 0;
      store.inventory.forEach((productId, stats) {
        final product = pm[productId];
        if (product != null && stats.sold > 0) {
          profit += product.margin * stats.sold;
        }
      });
      return acc + profit;
    });
  }

  int get totalUnitsSold =>
      _stores.fold(0, (acc, s) => acc + s.totalSold);

  double get averageMarginPercent {
    if (_products.isEmpty) return 0;
    final total = _products.fold(0.0, (acc, p) => acc + p.marginPercent);
    return total / _products.length;
  }

  /// Low stock alerts across all stores
  List<MapEntry<StoreModel, List<String>>> get lowStockAlerts {
    final pm = productsMap;
    final alerts = <MapEntry<StoreModel, List<String>>>[];
    for (final store in _stores) {
      final low = store.lowStockProducts(pm);
      if (low.isNotEmpty) {
        alerts.add(MapEntry(store, low));
      }
    }
    return alerts;
  }

  /// Total production cost invested
  double get totalProductionCost {
    final pm = productsMap;
    double cost = 0;
    for (final store in _stores) {
      store.inventory.forEach((productId, stats) {
        final product = pm[productId];
        if (product != null) {
          cost += product.effectiveCost * (stats.stock + stats.sold);
        }
      });
    }
    return cost;
  }

  /// Revenue collected (payments)
  double get totalPaymentsReceived {
    return _transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (acc, t) => acc + t.totalAmount);
  }

  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(20).toList();
  }

  List<TransactionModel> transactionsForStore(String storeId) {
    return _transactions.where((t) => t.storeId == storeId).toList();
  }

  /// Products by category
  Map<ProductCategory, List<ProductModel>> get productsByCategory {
    final map = <ProductCategory, List<ProductModel>>{};
    for (final p in _products) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  /// Contacts by type
  Map<String, List<ContactModel>> get contactsByType {
    final map = <String, List<ContactModel>>{};
    for (final c in _contacts) {
      map.putIfAbsent(c.type, () => []).add(c);
    }
    return map;
  }
}
