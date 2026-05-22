// Deliveries (Entregas) screen

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../helpers/alerts.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DeliveriesScreen extends StatelessWidget {
  const DeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final deliveries = state.transactions
            .where((t) => t.type == TransactionType.delivery)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Entregas')),
          body: deliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay entregas registradas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deliveries.length,
                  itemBuilder: (context, i) {
                    final d = deliveries[i];
                    return _DeliveryCard(
                      delivery: d,
                      isLast: i == deliveries.length - 1,
                      productsMap: state.productsMap,
                    );
                  },
                ),
          floatingActionButton: state.stores.isEmpty || state.products.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showDeliveryForm(context, state),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva Entrega'),
                ),
        );
      },
    );
  }

  void _showDeliveryForm(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DeliveryFormSheet(
        stores: state.stores,
        products: state.products,
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final TransactionModel delivery;
  final bool isLast;
  final Map<String, ProductModel> productsMap;

  const _DeliveryCard({
    required this.delivery,
    required this.isLast,
    required this.productsMap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'es').format(delivery.date);
    final totalQty = delivery.items?.values.fold(0, (a, b) => a + b) ?? 0;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 80 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot + line
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 70,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            delivery.storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showActions(context),
                          child: const Icon(Icons.more_vert_rounded,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _DeliveryChip(
                            label: '$totalQty pzas', color: AppColors.primary),
                        if (delivery.items != null)
                          ...delivery.items!.entries.map((e) {
                            final product = productsMap[e.key];
                            final color = product != null
                                ? Color(product.colorValue)
                                : AppColors.textSecondary;
                            final label = product != null
                                ? '${e.value}× ${product.name}'
                                : '${e.value}× ?';
                            return _DeliveryChip(label: label, color: color);
                          }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
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
              title: const Text('Eliminar Entrega',
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
    final confirmed = await showConfirmDelete(
      context,
      title: 'Eliminar Entrega',
      message:
          'Se revertirá el stock entregado a la tienda. ¿Continuar?',
    );
    if (confirmed && context.mounted) {
      try {
        await context.read<AppState>().deleteTransaction(delivery);
        if (context.mounted) {
          showSuccess(context, 'Entrega eliminada correctamente');
        }
      } catch (e) {
        if (context.mounted) {
          showError(context, 'Error al eliminar: $e');
        }
      }
    }
  }
}

class _DeliveryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DeliveryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeliveryFormSheet extends StatefulWidget {
  final List<StoreModel> stores;
  final List<ProductModel> products;
  const _DeliveryFormSheet({required this.stores, required this.products});

  @override
  State<_DeliveryFormSheet> createState() => _DeliveryFormSheetState();
}

class _DeliveryFormSheetState extends State<_DeliveryFormSheet> {
  StoreModel? _selectedStore;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    if (widget.stores.isNotEmpty) _selectedStore = widget.stores.first;
    _controllers = {
      for (final p in widget.products)
        p.id: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalQty {
    return _controllers.values.fold(
        0, (sum, c) => sum + (int.tryParse(c.text) ?? 0));
  }

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
              const ModalHeader(title: 'Nueva Entrega'),
              const SizedBox(height: 24),

            // Store selector
            const Text('Tienda',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StoreModel>(
                  value: _selectedStore,
                  isExpanded: true,
                  items: widget.stores
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (s) => setState(() => _selectedStore = s),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quantity per product
            ...widget.products.map((product) {
              final ctrl = _controllers[product.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuantityInput(
                  label: '${product.name} (\$${product.price.toStringAsFixed(0)})',
                  color: Color(product.colorValue),
                  controller: ctrl,
                  onChanged: () => setState(() {}),
                ),
              );
            }),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Total: $_totalQty piezas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _totalQty > 0 && _selectedStore != null
                    ? _handleSave
                    : null,
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Registrar Entrega'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }

  void _handleSave() async {
    final items = <String, int>{};
    _controllers.forEach((productId, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;
      if (qty > 0) items[productId] = qty;
    });

    if (items.isEmpty || _selectedStore == null) {
      showWarning(context, 'Selecciona al menos 1 pieza para entregar');
      return;
    }

    try {
      await context.read<AppState>().addDelivery(
            store: _selectedStore!,
            items: items,
          );

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        showSuccess(context,
            'Entrega de $_totalQty pzas a ${_selectedStore!.name} registrada');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error al registrar entrega: $e');
      }
    }
  }
}

class _QuantityInput extends StatelessWidget {
  final String label;
  final Color color;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _QuantityInput({
    required this.label,
    required this.color,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          // Quick buttons
          GestureDetector(
            onTap: () {
              final v = int.tryParse(controller.text) ?? 0;
              if (v > 0) {
                controller.text = '${v - 1}';
                onChanged();
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: const Text('-',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          GestureDetector(
            onTap: () {
              final v = int.tryParse(controller.text) ?? 0;
              controller.text = '${v + 1}';
              onChanged();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text('+',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ),
          ),
        ],
      ),
    );
  }
}
