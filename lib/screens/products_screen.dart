// Products CRUD screen — ERP J3D SQ v1.1

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/alerts.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        var products = state.products;

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q) ||
                  p.category.label.toLowerCase().contains(q))
              .toList();
        }

        // Filter by category
        if (_selectedCategory != null) {
          products = products
              .where((p) => p.category == _selectedCategory)
              .toList();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Productos')),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Category chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CategoryChip(
                      label: 'Todos',
                      icon: Icons.apps_rounded,
                      isSelected: _selectedCategory == null,
                      onTap: () =>
                          setState(() => _selectedCategory = null),
                    ),
                    ...ProductCategory.values.map((cat) => _CategoryChip(
                          label: cat.label,
                          icon: cat.icon,
                          isSelected: _selectedCategory == cat,
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          count: state.products
                              .where((p) => p.category == cat)
                              .length,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Product list
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined,
                                size: 64,
                                color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategory != null
                                  ? 'Sin resultados'
                                  : 'No hay productos registrados',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Intenta con otro término'
                                  : 'Toca el botón + para agregar uno',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: products.length,
                        itemBuilder: (context, i) {
                          return _ProductCard(product: products[i]);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showProductForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo'),
          ),
        );
      },
    );
  }

  void _showProductForm(BuildContext context, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProductFormSheet(product: product),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                count != null && count! > 0 ? '$label ($count)' : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final color = Color(product.colorValue);
    final margin = product.margin;
    final marginPct = product.marginPercent;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icon with category icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(product.category.icon,
                    color: color, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Costo: \$${product.effectiveCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const Text(' · ',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                        Expanded(
                          child: Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: margin >= 0
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+\$${margin.toStringAsFixed(0)} (${marginPct.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: margin >= 0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showActions(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary, size: 20),
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
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _ProductFormSheet(product: product),
                );
              },
            ),
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
    final confirmed = await showConfirmDelete(
      context,
      title: 'Eliminar Producto',
      message:
          '¿Estás seguro de eliminar "${product.name}"? Esto no afectará entregas o cobros ya registrados.',
    );
    if (confirmed && context.mounted) {
      try {
        await context.read<AppState>().deleteProduct(product.id);
        if (context.mounted) {
          showSuccess(context, '"${product.name}" eliminado correctamente');
        }
      } catch (e) {
        if (context.mounted) {
          showError(context, 'Error al eliminar: $e');
        }
      }
    }
  }
}

// ─── Product Form Sheet ─────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  const _ProductFormSheet({this.product});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  // Cost breakdown controllers
  late final TextEditingController _filamentCtrl;
  late final TextEditingController _filamentCostCtrl;
  late final TextEditingController _printTimeCtrl;
  late final TextEditingController _electricityCtrl;
  late final TextEditingController _laborCtrl;
  late final TextEditingController _laborCostCtrl;
  late final TextEditingController _extrasCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _thresholdCtrl;

  int _selectedColor = AppColors.productPalette[0];
  ProductCategory _selectedCategory = ProductCategory.llavero;
  bool _showCostBreakdown = false;
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _costCtrl = TextEditingController(
        text: p != null ? p.productionCost.toStringAsFixed(0) : '');

    final cb = p?.costBreakdown ?? const CostBreakdown();
    _filamentCtrl =
        TextEditingController(text: cb.filamentGrams.toStringAsFixed(0));
    _filamentCostCtrl =
        TextEditingController(text: cb.filamentCostPerKg.toStringAsFixed(0));
    _printTimeCtrl =
        TextEditingController(text: cb.printTimeMinutes.toStringAsFixed(0));
    _electricityCtrl = TextEditingController(
        text: cb.electricityCostPerHour.toStringAsFixed(0));
    _laborCtrl =
        TextEditingController(text: cb.laborMinutes.toStringAsFixed(0));
    _laborCostCtrl =
        TextEditingController(text: cb.laborCostPerHour.toStringAsFixed(0));
    _extrasCtrl =
        TextEditingController(text: cb.extraCosts.toStringAsFixed(0));
    _weightCtrl = TextEditingController(
        text: p != null ? p.weightGrams.toStringAsFixed(0) : '0');
    _thresholdCtrl = TextEditingController(
        text: '${p?.lowStockThreshold ?? 5}');

    _selectedColor = p?.colorValue ?? AppColors.productPalette[0];
    _selectedCategory = p?.category ?? ProductCategory.llavero;
    _showCostBreakdown = cb.totalCost > 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _filamentCtrl.dispose();
    _filamentCostCtrl.dispose();
    _printTimeCtrl.dispose();
    _electricityCtrl.dispose();
    _laborCtrl.dispose();
    _laborCostCtrl.dispose();
    _extrasCtrl.dispose();
    _weightCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  CostBreakdown get _breakdown => CostBreakdown(
        filamentGrams: double.tryParse(_filamentCtrl.text) ?? 0,
        filamentCostPerKg: double.tryParse(_filamentCostCtrl.text) ?? 300,
        printTimeMinutes: double.tryParse(_printTimeCtrl.text) ?? 0,
        electricityCostPerHour:
            double.tryParse(_electricityCtrl.text) ?? 3,
        laborMinutes: double.tryParse(_laborCtrl.text) ?? 0,
        laborCostPerHour: double.tryParse(_laborCostCtrl.text) ?? 50,
        extraCosts: double.tryParse(_extrasCtrl.text) ?? 0,
      );

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
              // Handle bar + close button
              ModalHeader(
                  title:
                      isEditing ? 'Editar Producto' : 'Nuevo Producto'),
              const SizedBox(height: 24),

            // Category selector
            const Text('Categoría',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Nombre',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'Ej. Llavero Económico'),
            ),
            const SizedBox(height: 16),

            const Text('Descripción (opcional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Ej. Llavero redondo con logo personalizado'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Precio Venta (\$)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: 'Ej. 45'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Costo Rápido (\$)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _costCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: 'Ej. 15'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cost breakdown toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showCostBreakdown = !_showCostBreakdown),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Calculadora de Costos 3D',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(
                      _showCostBreakdown
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            if (_showCostBreakdown) ...[
              const SizedBox(height: 16),
              _costRow('Filamento (g)', _filamentCtrl,
                  'Costo/kg (\$)', _filamentCostCtrl),
              const SizedBox(height: 10),
              _costRow('Tiempo impresión (min)', _printTimeCtrl,
                  'Electricidad \$/hr', _electricityCtrl),
              const SizedBox(height: 10),
              _costRow('Mano de obra (min)', _laborCtrl,
                  'Costo/hr M.O. (\$)', _laborCostCtrl),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Extras (\$)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _extrasCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Peso (g)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Live cost result
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Costo Calculado:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                    Text(
                      '\$${_breakdown.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Alert threshold
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alerta Stock Bajo',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _thresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '5',
                          suffixText: 'pzas',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Color',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.productPalette.map((cv) {
                final isSelected = _selectedColor == cv;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = cv),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(cv),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.text, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(cv).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            LoadingButton(
              isLoading: _isSaving,
              onPressed: _handleSave,
              label: isEditing ? 'Guardar Cambios' : 'Crear Producto',
              icon: isEditing
                  ? Icons.save_rounded
                  : Icons.add_circle_rounded,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }

  Widget _costRow(String label1, TextEditingController ctrl1, String label2,
      TextEditingController ctrl2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: ctrl1,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: ctrl2,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSave() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final cost = double.tryParse(_costCtrl.text.trim());

    if (name.isEmpty) {
      showWarning(context, 'El nombre del producto es obligatorio');
      return;
    }

    if (price == null || price <= 0) {
      showWarning(context, 'El precio debe ser mayor a \$0');
      return;
    }

    if (cost == null || cost < 0) {
      showWarning(context, 'El costo debe ser un número válido');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final state = context.read<AppState>();
      final cbMap = _showCostBreakdown ? _breakdown.toMap() : null;
      final desc = _descCtrl.text.trim();
      final weight = double.tryParse(_weightCtrl.text) ?? 0;
      final threshold = int.tryParse(_thresholdCtrl.text) ?? 5;

      if (isEditing) {
        await state.updateProduct(
          widget.product!.id,
          name: name,
          price: price,
          productionCost: cost,
          colorValue: _selectedColor,
          description: desc,
          categoryName: _selectedCategory.name,
          costBreakdownMap: cbMap,
          weightGrams: weight,
          lowStockThreshold: threshold,
        );
      } else {
        await state.addProduct(
          name: name,
          price: price,
          productionCost: cost,
          colorValue: _selectedColor,
          description: desc,
          category: _selectedCategory,
          costBreakdown:
              _showCostBreakdown ? _breakdown : const CostBreakdown(),
          weightGrams: weight,
          lowStockThreshold: threshold,
        );
      }

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        showSuccess(
          context,
          isEditing
              ? '"$name" actualizado correctamente'
              : '"$name" creado correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showError(context, 'Error al guardar: $e');
      }
    }
  }
}
