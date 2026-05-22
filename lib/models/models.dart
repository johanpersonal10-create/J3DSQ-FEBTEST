// Data models for J3D SQ — ERP for 3D printing business

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Product Categories ─────────────────────────────────────

enum ProductCategory {
  llavero('Llavero', Icons.key_rounded),
  figura('Figura', Icons.extension_rounded),
  maceta('Maceta', Icons.local_florist_rounded),
  organizador('Organizador', Icons.inventory_2_rounded),
  decoracion('Decoración', Icons.palette_rounded),
  personalizado('Personalizado', Icons.auto_awesome_rounded),
  otro('Otro', Icons.widgets_rounded);

  final String label;
  final IconData icon;
  const ProductCategory(this.label, this.icon);
}

// ─── Cost Breakdown for 3D Printing ─────────────────────────

class CostBreakdown {
  final double filamentGrams;
  final double filamentCostPerKg;
  final double printTimeMinutes;
  final double electricityCostPerHour;
  final double laborMinutes;
  final double laborCostPerHour;
  final double extraCosts;

  const CostBreakdown({
    this.filamentGrams = 0,
    this.filamentCostPerKg = 300,
    this.printTimeMinutes = 0,
    this.electricityCostPerHour = 3,
    this.laborMinutes = 0,
    this.laborCostPerHour = 50,
    this.extraCosts = 0,
  });

  double get filamentCost => (filamentGrams / 1000) * filamentCostPerKg;
  double get electricityCost =>
      (printTimeMinutes / 60) * electricityCostPerHour;
  double get laborCost => (laborMinutes / 60) * laborCostPerHour;
  double get totalCost =>
      filamentCost + electricityCost + laborCost + extraCosts;

  Map<String, dynamic> toMap() => {
        'filamentGrams': filamentGrams,
        'filamentCostPerKg': filamentCostPerKg,
        'printTimeMinutes': printTimeMinutes,
        'electricityCostPerHour': electricityCostPerHour,
        'laborMinutes': laborMinutes,
        'laborCostPerHour': laborCostPerHour,
        'extraCosts': extraCosts,
      };

  factory CostBreakdown.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CostBreakdown();
    return CostBreakdown(
      filamentGrams: (map['filamentGrams'] as num?)?.toDouble() ?? 0,
      filamentCostPerKg:
          (map['filamentCostPerKg'] as num?)?.toDouble() ?? 300,
      printTimeMinutes:
          (map['printTimeMinutes'] as num?)?.toDouble() ?? 0,
      electricityCostPerHour:
          (map['electricityCostPerHour'] as num?)?.toDouble() ?? 3,
      laborMinutes: (map['laborMinutes'] as num?)?.toDouble() ?? 0,
      laborCostPerHour:
          (map['laborCostPerHour'] as num?)?.toDouble() ?? 50,
      extraCosts: (map['extraCosts'] as num?)?.toDouble() ?? 0,
    );
  }

  CostBreakdown copyWith({
    double? filamentGrams,
    double? filamentCostPerKg,
    double? printTimeMinutes,
    double? electricityCostPerHour,
    double? laborMinutes,
    double? laborCostPerHour,
    double? extraCosts,
  }) {
    return CostBreakdown(
      filamentGrams: filamentGrams ?? this.filamentGrams,
      filamentCostPerKg: filamentCostPerKg ?? this.filamentCostPerKg,
      printTimeMinutes: printTimeMinutes ?? this.printTimeMinutes,
      electricityCostPerHour:
          electricityCostPerHour ?? this.electricityCostPerHour,
      laborMinutes: laborMinutes ?? this.laborMinutes,
      laborCostPerHour: laborCostPerHour ?? this.laborCostPerHour,
      extraCosts: extraCosts ?? this.extraCosts,
    );
  }
}

// ─── Product Model ──────────────────────────────────────────

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double productionCost;
  final int colorValue;
  final ProductCategory category;
  final CostBreakdown costBreakdown;
  final double weightGrams;
  final String? imageUrl;
  final int lowStockThreshold;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.productionCost,
    this.colorValue = 0xFF6C5CE7,
    this.category = ProductCategory.llavero,
    this.costBreakdown = const CostBreakdown(),
    this.weightGrams = 0,
    this.imageUrl,
    this.lowStockThreshold = 5,
    this.createdAt,
  });

  double get margin => price - effectiveCost;
  double get marginPercent => price > 0 ? (margin / price) * 100 : 0;
  double get effectiveCost =>
      costBreakdown.totalCost > 0 ? costBreakdown.totalCost : productionCost;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'productionCost': productionCost,
        'colorValue': colorValue,
        'category': category.name,
        'costBreakdown': costBreakdown.toMap(),
        'weightGrams': weightGrams,
        'imageUrl': imageUrl,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      productionCost: (map['productionCost'] as num?)?.toDouble() ?? 0,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF6C5CE7,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ProductCategory.llavero,
      ),
      costBreakdown: CostBreakdown.fromMap(
          map['costBreakdown'] as Map<String, dynamic>?),
      weightGrams: (map['weightGrams'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    double? productionCost,
    int? colorValue,
    ProductCategory? category,
    CostBreakdown? costBreakdown,
    double? weightGrams,
    String? imageUrl,
    int? lowStockThreshold,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      productionCost: productionCost ?? this.productionCost,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      weightGrams: weightGrams ?? this.weightGrams,
      imageUrl: imageUrl ?? this.imageUrl,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
    );
  }
}

// ─── Inventory Stats ────────────────────────────────────────

class InventoryStats {
  final int stock;
  final int sold;

  const InventoryStats({this.stock = 0, this.sold = 0});

  Map<String, dynamic> toMap() => {'stock': stock, 'sold': sold};

  factory InventoryStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const InventoryStats();
    return InventoryStats(
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sold: (map['sold'] as num?)?.toInt() ?? 0,
    );
  }

  InventoryStats copyWith({int? stock, int? sold}) {
    return InventoryStats(
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
    );
  }
}

// ─── Store Model ────────────────────────────────────────────

class StoreModel {
  final String id;
  final String name;
  final String contactName;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final double commissionRate;
  final int totalDelivered;
  final int totalSold;
  final double balance;
  final Map<String, InventoryStats> inventory;
  final DateTime? createdAt;

  StoreModel({
    required this.id,
    required this.name,
    required this.contactName,
    this.phone = '',
    this.email = '',
    required this.address,
    this.notes = '',
    required this.commissionRate,
    this.totalDelivered = 0,
    this.totalSold = 0,
    this.balance = 0,
    Map<String, InventoryStats>? inventory,
    this.createdAt,
  }) : inventory = inventory ?? {};

  int get totalStock =>
      inventory.values.fold(0, (acc, s) => acc + s.stock);

  int get totalSoldUnits =>
      inventory.values.fold(0, (acc, s) => acc + s.sold);

  double inventoryValueWith(Map<String, ProductModel> products) {
    double value = 0;
    inventory.forEach((productId, stats) {
      final product = products[productId];
      if (product != null) {
        value += stats.stock * product.price;
      }
    });
    return value;
  }

  List<String> lowStockProducts(Map<String, ProductModel> products) {
    final result = <String>[];
    inventory.forEach((productId, stats) {
      final product = products[productId];
      if (product != null &&
          stats.stock > 0 &&
          stats.stock <= product.lowStockThreshold) {
        result.add(productId);
      }
    });
    return result;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'commissionRate': commissionRate,
        'totalDelivered': totalDelivered,
        'totalSold': totalSold,
        'balance': balance,
        'inventory': inventory.map((k, v) => MapEntry(k, v.toMap())),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory StoreModel.fromMap(String id, Map<String, dynamic> map) {
    final invMap = map['inventory'] as Map<String, dynamic>? ?? {};
    final inventory = <String, InventoryStats>{};
    invMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        inventory[key] = InventoryStats.fromMap(value);
      }
    });

    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      contactName: map['contactName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      commissionRate:
          (map['commissionRate'] as num?)?.toDouble() ?? 20,
      totalDelivered:
          (map['totalDelivered'] as num?)?.toInt() ?? 0,
      totalSold: (map['totalSold'] as num?)?.toInt() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      inventory: inventory,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  StoreModel copyWith({
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? commissionRate,
    int? totalDelivered,
    int? totalSold,
    double? balance,
    Map<String, InventoryStats>? inventory,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      commissionRate: commissionRate ?? this.commissionRate,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      totalSold: totalSold ?? this.totalSold,
      balance: balance ?? this.balance,
      inventory: inventory ?? this.inventory,
      createdAt: createdAt,
    );
  }
}

// ─── Contact Model ──────────────────────────────────────────

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String type; // 'cliente', 'proveedor', 'tienda'
  final String? linkedStoreId;
  final DateTime? createdAt;

  ContactModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.type = 'cliente',
    this.linkedStoreId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'type': type,
        'linkedStoreId': linkedStoreId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory ContactModel.fromMap(String id, Map<String, dynamic> map) {
    return ContactModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      type: map['type'] ?? 'cliente',
      linkedStoreId: map['linkedStoreId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  ContactModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? type,
    String? linkedStoreId,
  }) {
    return ContactModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      linkedStoreId: linkedStoreId ?? this.linkedStoreId,
      createdAt: createdAt,
    );
  }
}

// ─── Transaction Types ──────────────────────────────────────

enum TransactionType { delivery, sale, payment }

// ─── Transaction Model ──────────────────────────────────────

class TransactionModel {
  final String id;
  final String storeId;
  final String storeName;
  final TransactionType type;
  final DateTime date;
  final double totalAmount;
  final String? note;
  final Map<String, int>? items;

  TransactionModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.type,
    required this.date,
    required this.totalAmount,
    this.note,
    this.items,
  });

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'storeName': storeName,
        'type': type.name,
        'date': Timestamp.fromDate(date),
        'totalAmount': totalAmount,
        'note': note,
        'items': items,
      };

  factory TransactionModel.fromMap(
      String id, Map<String, dynamic> map) {
    final itemsRaw = map['items'] as Map<String, dynamic>?;
    return TransactionModel(
      id: id,
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TransactionType.delivery,
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount:
          (map['totalAmount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      items:
          itemsRaw?.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}
