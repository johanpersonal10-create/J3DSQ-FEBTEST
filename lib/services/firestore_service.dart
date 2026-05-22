// Firestore service for J3D SQ

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ─────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _storesCol =>
      _db.collection('tiendas');

  CollectionReference<Map<String, dynamic>> get _transactionsCol =>
      _db.collection('transacciones');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _db.collection('productos');

  CollectionReference<Map<String, dynamic>> get _contactsCol =>
      _db.collection('contactos');

  // ─── Products ─────────────────────────────────────────────

  /// Real-time stream of all products
  Stream<List<ProductModel>> productsStream() {
    return _productsCol.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList());
  }

  /// Add a new product
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
    final product = ProductModel(
      id: '',
      name: name,
      description: description,
      price: price,
      productionCost: productionCost,
      colorValue: colorValue,
      category: category,
      costBreakdown: costBreakdown,
      weightGrams: weightGrams,
      lowStockThreshold: lowStockThreshold,
    );
    final docRef = await _productsCol.add(product.toMap());
    return ProductModel.fromMap(docRef.id, product.toMap());
  }

  /// Update an existing product
  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    await _productsCol.doc(id).update(updates);
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _productsCol.doc(id).delete();
  }

  // ─── Stores ──────────────────────────────────────────────

  /// Real-time stream of all stores
  Stream<List<StoreModel>> storesStream() {
    return _storesCol.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => StoreModel.fromMap(d.id, d.data())).toList());
  }

  /// Add a new store
  Future<StoreModel> addStore({
    required String name,
    required String contactName,
    required String address,
    required double commissionRate,
    String phone = '',
    String email = '',
    String notes = '',
  }) async {
    final store = StoreModel(
      id: '',
      name: name,
      contactName: contactName,
      address: address,
      commissionRate: commissionRate,
      phone: phone,
      email: email,
      notes: notes,
    );
    final docRef = await _storesCol.add(store.toMap());
    return StoreModel.fromMap(docRef.id, store.toMap());
  }

  /// Update an existing store's basic fields
  Future<void> updateStore(String id, Map<String, dynamic> updates) async {
    await _storesCol.doc(id).update(updates);
  }

  /// Delete a store and its transactions
  Future<void> deleteStore(String id) async {
    final txSnap =
        await _transactionsCol.where('storeId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in txSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_storesCol.doc(id));
    await batch.commit();
  }

  /// Update the full store document (used after inventory changes)
  Future<void> setStore(StoreModel store) async {
    await _storesCol.doc(store.id).set(store.toMap());
  }

  // ─── Transactions ────────────────────────────────────────

  /// Real-time stream of all transactions
  Stream<List<TransactionModel>> transactionsStream() {
    return _transactionsCol
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TransactionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Add a delivery — increases stock for a store
  Future<void> addDelivery({
    required StoreModel store,
    required Map<String, int> items, // productId -> quantity
    required Map<String, ProductModel> productsMap,
  }) async {
    final totalQty = items.values.fold(0, (a, b) => a + b);
    double totalAmount = 0;
    items.forEach((productId, qty) {
      final product = productsMap[productId];
      if (product != null) {
        totalAmount += product.price * qty;
      }
    });

    // Update store inventory
    final newInventory = Map<String, InventoryStats>.from(store.inventory);
    items.forEach((productId, qty) {
      final current = newInventory[productId] ?? const InventoryStats();
      newInventory[productId] = current.copyWith(stock: current.stock + qty);
    });

    final updatedStore = store.copyWith(
      totalDelivered: store.totalDelivered + totalQty,
      inventory: newInventory,
    );

    // Batch: update store + add transaction
    final batch = _db.batch();
    batch.set(_storesCol.doc(store.id), updatedStore.toMap());
    batch.set(
        _transactionsCol.doc(),
        TransactionModel(
          id: '',
          storeId: store.id,
          storeName: store.name,
          type: TransactionType.delivery,
          date: DateTime.now(),
          totalAmount: totalAmount,
          items: items,
        ).toMap());
    await batch.commit();
  }

  /// Register a sale (cobro) using the consignment logic
  /// [currentStock] is the actual count remaining for each product
  Future<void> registerSale({
    required StoreModel store,
    required Map<String, int> currentStock, // productId -> what's on shelf now
    required Map<String, ProductModel> productsMap,
  }) async {
    final newInventory = Map<String, InventoryStats>.from(store.inventory);
    int totalSoldUnits = 0;
    double totalSaleAmount = 0;
    final soldItems = <String, int>{};

    for (final entry in store.inventory.entries) {
      final productId = entry.key;
      final prev = entry.value;
      final nowStock = currentStock[productId] ?? prev.stock;
      final soldQty = prev.stock - nowStock;

      if (soldQty > 0) {
        final product = productsMap[productId];
        final price = product?.price ?? 0;

        soldItems[productId] = soldQty;
        totalSoldUnits += soldQty;
        totalSaleAmount += soldQty * price;

        newInventory[productId] = prev.copyWith(
          stock: nowStock,
          sold: prev.sold + soldQty,
        );
      }
    }

    if (totalSoldUnits == 0) return;

    // Apply commission: store keeps commission, we get the rest
    final commissionAmount =
        totalSaleAmount * (store.commissionRate / 100);
    final amountReceivable = totalSaleAmount - commissionAmount;

    final updatedStore = store.copyWith(
      totalSold: store.totalSold + totalSoldUnits,
      balance: store.balance + amountReceivable,
      inventory: newInventory,
    );

    final batch = _db.batch();
    batch.set(_storesCol.doc(store.id), updatedStore.toMap());
    batch.set(
        _transactionsCol.doc(),
        TransactionModel(
          id: '',
          storeId: store.id,
          storeName: store.name,
          type: TransactionType.sale,
          date: DateTime.now(),
          totalAmount: amountReceivable,
          items: soldItems,
          note:
              'Comisión ${store.commissionRate.toStringAsFixed(1)}%: -\$${commissionAmount.toStringAsFixed(2)}',
        ).toMap());
    await batch.commit();
  }

  /// Register a payment received from a store
  Future<void> addPayment({
    required StoreModel store,
    required double amount,
    String? note,
  }) async {
    final updatedBalance =
        (store.balance - amount).clamp(0.0, double.infinity);

    final batch = _db.batch();
    batch.update(_storesCol.doc(store.id), {'balance': updatedBalance});
    batch.set(
        _transactionsCol.doc(),
        TransactionModel(
          id: '',
          storeId: store.id,
          storeName: store.name,
          type: TransactionType.payment,
          date: DateTime.now(),
          totalAmount: amount,
          note: note,
        ).toMap());
    await batch.commit();
  }

  // ─── Delete Transaction (with reversal) ──────────────────

  /// Delete a transaction and reverse its effect on the store
  Future<void> deleteTransaction(TransactionModel tx) async {
    // Fetch the current store document
    final storeDoc = await _storesCol.doc(tx.storeId).get();
    if (!storeDoc.exists) {
      // Store already deleted, just remove the transaction
      await _transactionsCol.doc(tx.id).delete();
      return;
    }

    final store = StoreModel.fromMap(storeDoc.id, storeDoc.data()!);
    final batch = _db.batch();

    switch (tx.type) {
      case TransactionType.delivery:
        // Reverse: subtract delivered quantities from inventory
        final newInventory = Map<String, InventoryStats>.from(store.inventory);
        int reversedQty = 0;
        tx.items?.forEach((productId, qty) {
          final current = newInventory[productId] ?? const InventoryStats();
          final newStock = (current.stock - qty).clamp(0, 999999);
          newInventory[productId] = current.copyWith(stock: newStock);
          reversedQty += qty;
        });
        final updatedStore = store.copyWith(
          totalDelivered:
              (store.totalDelivered - reversedQty).clamp(0, 999999),
          inventory: newInventory,
        );
        batch.set(_storesCol.doc(store.id), updatedStore.toMap());
        break;

      case TransactionType.sale:
        // Reverse: add sold quantities back to stock, reduce sold count, reduce balance
        final newInventory = Map<String, InventoryStats>.from(store.inventory);
        int reversedQty = 0;
        tx.items?.forEach((productId, qty) {
          final current = newInventory[productId] ?? const InventoryStats();
          newInventory[productId] = current.copyWith(
            stock: current.stock + qty,
            sold: (current.sold - qty).clamp(0, 999999),
          );
          reversedQty += qty;
        });
        final newBalance =
            (store.balance - tx.totalAmount).clamp(0.0, double.infinity);
        final updatedStore = store.copyWith(
          totalSold: (store.totalSold - reversedQty).clamp(0, 999999),
          balance: newBalance,
          inventory: newInventory,
        );
        batch.set(_storesCol.doc(store.id), updatedStore.toMap());
        break;

      case TransactionType.payment:
        // Reverse: add payment amount back to balance
        final updatedStore = store.copyWith(
          balance: store.balance + tx.totalAmount,
        );
        batch.set(_storesCol.doc(store.id), updatedStore.toMap());
        break;
    }

    batch.delete(_transactionsCol.doc(tx.id));
    await batch.commit();
  }

  // ─── Contacts ────────────────────────────────────────────

  /// Real-time stream of all contacts
  Stream<List<ContactModel>> contactsStream() {
    return _contactsCol.orderBy('name').snapshots().map((snap) =>
        snap.docs
            .map((d) => ContactModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Add a new contact
  Future<ContactModel> addContact({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
    String type = 'cliente',
    String? linkedStoreId,
  }) async {
    final contact = ContactModel(
      id: '',
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      type: type,
      linkedStoreId: linkedStoreId,
    );
    final docRef = await _contactsCol.add(contact.toMap());
    return ContactModel.fromMap(docRef.id, contact.toMap());
  }

  /// Update an existing contact
  Future<void> updateContact(
      String id, Map<String, dynamic> updates) async {
    await _contactsCol.doc(id).update(updates);
  }

  /// Delete a contact
  Future<void> deleteContact(String id) async {
    await _contactsCol.doc(id).delete();
  }
}
