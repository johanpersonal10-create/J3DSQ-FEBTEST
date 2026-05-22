// Store detail screen with dynamic products & cobros logic

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/alerts.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class StoreDetailScreen extends StatelessWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final store = state.getStoreById(storeId);
        if (store == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tienda')),
            body: const Center(child: Text('Tienda no encontrada')),
          );
        }

        final storeTxs = state.transactionsForStore(storeId);

        return Scaffold(
          appBar: AppBar(
            title: Text(store.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info card
                _StoreInfoCard(store: store),
                const SizedBox(height: 24),

                // Inventory section
                if (store.inventory.isNotEmpty) ...[
                  const Text(
                    'Inventario por Producto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic product inventory cards
                  ...store.inventory.entries.map((entry) {
                    final product = state.getProductById(entry.key);
                    return _InventoryCard(
                      product: product,
                      productId: entry.key,
                      stats: entry.value,
                    );
                  }),
                ],

                if (store.inventory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        const Text(
                          'Sin inventario',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const Text(
                          'Registra una entrega para agregar stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Cobro button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: store.totalStock > 0
                        ? () => _showCobroDialog(context, store, state)
                        : null,
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Registrar Cobro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentDialog(context, store),
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Registrar Pago Recibido'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),

                // Transaction history section
                if (storeTxs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _StoreTransactionHistory(
                    transactions: storeTxs,
                    productsMap: state.productsMap,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCobroDialog(
      BuildContext context, StoreModel store, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CobroSheet(store: store, productsMap: state.productsMap),
    );
  }

  void _showPaymentDialog(BuildContext context, StoreModel store) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => GestureDetector(
        onTap: () => FocusScope.of(ctx).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModalHeader(title: 'Registrar Pago'),
              const SizedBox(height: 8),
              Text(
                'Saldo pendiente: \$${store.balance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text('Monto (\$)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0.00'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Nota (opcional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    hintText: 'Ej. Pago parcial efectivo'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      showWarning(ctx, 'Ingresa un monto válido mayor a \$0');
                      return;
                    }
                    try {
                      await context.read<AppState>().addPayment(
                            store: store,
                            amount: amount,
                            note: noteCtrl.text.trim().isNotEmpty
                                ? noteCtrl.text.trim()
                                : null,
                          );
                      if (ctx.mounted) {
                        FocusScope.of(ctx).unfocus();
                        Navigator.pop(ctx);
                      }
                      if (context.mounted) {
                        showSuccess(context,
                            'Pago de \$${amount.toStringAsFixed(2)} registrado');
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        showError(ctx, 'Error al registrar pago: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Guardar Pago'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Store Info Header Card ──────────────────────────────────

class _StoreInfoCard extends StatelessWidget {
  final StoreModel store;
  const _StoreInfoCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contacto',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(store.contactName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Saldo Pendiente',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '\$${store.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: store.balance > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.address,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Comisión ${store.commissionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          // Contact actions
          if (store.phone.isNotEmpty || store.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (store.phone.isNotEmpty) ...[
                  Expanded(
                    child: _ContactActionBtn(
                      icon: Icons.phone_rounded,
                      label: 'Llamar',
                      color: AppColors.success,
                      onTap: () async {
                        final uri = Uri.parse('tel:${store.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContactActionBtn(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        final phone = store.phone.replaceAll(RegExp(r'[^\d]'), '');
                        final uri = Uri.parse('https://wa.me/$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                ],
                if (store.email.isNotEmpty) ...[
                  if (store.phone.isNotEmpty) const SizedBox(width: 8),
                  Expanded(
                    child: _ContactActionBtn(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      color: AppColors.primary,
                      onTap: () async {
                        final uri = Uri.parse('mailto:${store.email}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Notes
          if (store.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.notes,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inventory Card per Product ────────────────────────────

class _InventoryCard extends StatelessWidget {
  final ProductModel? product;
  final String productId;
  final InventoryStats stats;

  const _InventoryCard({
    required this.product,
    required this.productId,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        product != null ? Color(product!.colorValue) : AppColors.textSecondary;
    final name = product?.name ?? 'Producto eliminado';
    final price = product?.price ?? 0;
    final subtotal = stats.sold * price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'En Stock',
                        value: '${stats.stock}',
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Vendidos',
                        value: '${stats.sold}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

// ─── Store Transaction History ─────────────────────────────

class _StoreTransactionHistory extends StatefulWidget {
  final List<TransactionModel> transactions;
  final Map<String, ProductModel> productsMap;
  const _StoreTransactionHistory({
    required this.transactions,
    required this.productsMap,
  });

  @override
  State<_StoreTransactionHistory> createState() =>
      _StoreTransactionHistoryState();
}

class _StoreTransactionHistoryState extends State<_StoreTransactionHistory> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Historial de Tienda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.transactions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppColors.border),
                ...widget.transactions.map(
                    (tx) => _StoreTxTile(tx: tx, productsMap: widget.productsMap)),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _StoreTxTile extends StatelessWidget {
  final TransactionModel tx;
  final Map<String, ProductModel> productsMap;
  const _StoreTxTile({required this.tx, required this.productsMap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yy').format(tx.date);
    final isPayment = tx.type == TransactionType.payment;
    final isDelivery = tx.type == TransactionType.delivery;

    IconData icon;
    Color color;
    String prefix;
    String typeLabel;

    if (isPayment) {
      icon = Icons.payments_rounded;
      color = AppColors.primary;
      prefix = '+';
      typeLabel = 'Pago';
    } else if (isDelivery) {
      icon = Icons.inventory_2_rounded;
      color = AppColors.textSecondary;
      prefix = '';
      typeLabel = 'Entrega';
    } else {
      icon = Icons.point_of_sale_rounded;
      color = AppColors.success;
      prefix = '+';
      typeLabel = 'Cobro';
    }

    return GestureDetector(
      onLongPress: () => _showDeleteOption(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Text(
                      tx.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix\$${tx.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDelivery ? AppColors.textSecondary : color,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteOption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: AppColors.danger),
              title: const Text('Eliminar',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    String message;
    switch (tx.type) {
      case TransactionType.delivery:
        message = 'Se revertirá el stock entregado. ¿Continuar?';
        break;
      case TransactionType.sale:
        message = 'Se revertirán las ventas y el saldo pendiente. ¿Continuar?';
        break;
      case TransactionType.payment:
        message = 'Se revertirá el pago al saldo pendiente. ¿Continuar?';
        break;
    }

    final confirmed = await showConfirmDelete(
      context,
      title: 'Eliminar Transacción',
      message: message,
    );
    if (confirmed && context.mounted) {
      try {
        await context.read<AppState>().deleteTransaction(tx);
        if (context.mounted) {
          showSuccess(context, 'Transacción eliminada correctamente');
        }
      } catch (e) {
        if (context.mounted) {
          showError(context, 'Error al eliminar: $e');
        }
      }
    }
  }
}

// ─── Cobro Sheet (Dynamic Products) ───────────────────────────

class _CobroSheet extends StatefulWidget {
  final StoreModel store;
  final Map<String, ProductModel> productsMap;
  const _CobroSheet({required this.store, required this.productsMap});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  // Controllers: productId -> controller for "¿Cuántos QUEDAN?"
  late final Map<String, TextEditingController> _controllers;
  bool _showSummary = false;

  // Calculated values
  Map<String, int> _soldByProduct = {};
  double _totalSale = 0;
  double _commission = 0;
  double _toReceive = 0;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final entry in widget.store.inventory.entries) {
      if (entry.value.stock > 0) {
        _controllers[entry.key] =
            TextEditingController(text: '${entry.value.stock}');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final inv = widget.store.inventory;
    _soldByProduct = {};
    _totalSale = 0;

    bool hasError = false;

    for (final entry in _controllers.entries) {
      final productId = entry.key;
      final prevStock = inv[productId]?.stock ?? 0;
      final current = int.tryParse(entry.value.text) ?? prevStock;

      if (current > prevStock) {
        hasError = true;
        showWarning(context,
            'La existencia no puede ser mayor al stock registrado');
        return;
      }
      if (current < 0) {
        hasError = true;
        showWarning(context, 'La existencia no puede ser negativa');
        return;
      }

      final soldQty = prevStock - current;
      if (soldQty > 0) {
        _soldByProduct[productId] = soldQty;
        final product = widget.productsMap[productId];
        _totalSale += soldQty * (product?.price ?? 0);
      }
    }

    if (hasError) return;

    setState(() {
      _commission =
          _totalSale * (widget.store.commissionRate / 100);
      _toReceive = _totalSale - _commission;
      _showSummary = true;
    });
  }

  void _confirm() async {
    final currentStock = <String, int>{};
    for (final entry in _controllers.entries) {
      currentStock[entry.key] = int.tryParse(entry.value.text) ?? 0;
    }

    try {
      await context.read<AppState>().registerSale(
            store: widget.store,
            currentStock: currentStock,
          );

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        showSuccess(context,
            'Cobro de \$${_toReceive.toStringAsFixed(2)} registrado');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al registrar cobro: $e');
      }
    }
  }

  int get _totalSold =>
      _soldByProduct.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModalHeader(title: 'Registrar Cobro'),
              const SizedBox(height: 8),
              const Text(
                '¿Cuántas piezas QUEDAN en existencia?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

            // Input per product with stock
            ..._controllers.entries.map((entry) {
              final productId = entry.key;
              final product = widget.productsMap[productId];
              final color = product != null
                  ? Color(product.colorValue)
                  : AppColors.textSecondary;
              final label = product?.name ?? 'Producto';
              final stock = widget.store.inventory[productId]?.stock ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExistenciaInput(
                  label: label,
                  color: color,
                  stockAnterior: stock,
                  controller: entry.value,
                ),
              );
            }),

            const SizedBox(height: 24),

            if (!_showSummary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Calcular'),
                ),
              ),

            // Summary
            if (_showSummary) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Resumen del Cobro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._soldByProduct.entries.map((e) {
                      final product = widget.productsMap[e.key];
                      final name = product?.name ?? '?';
                      final price = product?.price ?? 0;
                      return _SummaryRow(
                        label: '${e.value} × \$${price.toStringAsFixed(0)} ($name)',
                        value: '\$${(e.value * price).toStringAsFixed(0)}',
                      );
                    }),

                    const Divider(color: Colors.white30, height: 24),

                    _SummaryRow(
                      label: 'Venta Total',
                      value: '\$${_totalSale.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label:
                          'Comisión (${widget.store.commissionRate.toStringAsFixed(1)}%)',
                      value: '-\$${_commission.toStringAsFixed(2)}',
                      isNegative: true,
                    ),

                    const Divider(color: Colors.white30, height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'A Recibir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '\$${_toReceive.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _showSummary = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Modificar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _totalSold > 0 ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmar Cobro'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }
}

class _ExistenciaInput extends StatelessWidget {
  final String label;
  final Color color;
  final int stockAnterior;
  final TextEditingController controller;

  const _ExistenciaInput({
    required this.label,
    required this.color,
    required this.stockAnterior,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Stock actual: $stockAnterior',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isNegative ? Colors.white60 : Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isNegative ? Colors.white60 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
