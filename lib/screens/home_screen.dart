// Home / Dashboard screen — ERP J3D SQ v1.2

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'store_detail_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final sortedStores = List<StoreModel>.from(state.stores)
          ..sort((a, b) => b.totalSold.compareTo(a.totalSold));

        final lowStockAlerts = state.lowStockAlerts;

        // ── Compute analytics for insights ──
        final pm = state.productsMap;
        double totalRevenue = 0;
        double totalProdCost = 0;
        double totalPayments = state.totalPaymentsReceived;
        final productSales = <String, int>{};
        final storeSales = <String, double>{};
        final storeNamesMap = <String, String>{};

        for (final tx in state.transactions) {
          if (tx.type == TransactionType.sale) {
            totalRevenue += tx.totalAmount;
            storeSales[tx.storeId] =
                (storeSales[tx.storeId] ?? 0) + tx.totalAmount;
            storeNamesMap[tx.storeId] = tx.storeName;
            tx.items?.forEach((pid, qty) {
              productSales[pid] = (productSales[pid] ?? 0) + qty;
            });
          } else if (tx.type == TransactionType.delivery) {
            tx.items?.forEach((pid, qty) {
              final p = pm[pid];
              if (p != null) totalProdCost += p.effectiveCost * qty;
            });
          }
        }

        final netProfit = totalRevenue - totalProdCost;
        final roi = totalProdCost > 0
            ? (netProfit / totalProdCost) * 100
            : 0.0;

        // Top product
        String? topProductName;
        int topProductQty = 0;
        productSales.forEach((pid, qty) {
          if (qty > topProductQty) {
            topProductQty = qty;
            topProductName = pm[pid]?.name;
          }
        });

        // Top store
        String? topStoreName;
        double topStoreRev = 0;
        storeSales.forEach((sid, rev) {
          if (rev > topStoreRev) {
            topStoreRev = rev;
            topStoreName = storeNamesMap[sid];
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('J3D SQ'),
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                _DashboardHero(state: state, roi: roi, netProfit: netProfit),
                const SizedBox(height: 16),

                // ── Financial Insights ──
                _FinancialInsights(
                  totalRevenue: totalRevenue,
                  totalProdCost: totalProdCost,
                  totalPayments: totalPayments,
                  pendingBalance: state.totalReceivable,
                  topProductName: topProductName,
                  topProductQty: topProductQty,
                  topStoreName: topStoreName,
                  topStoreRev: topStoreRev,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActions(),
                const SizedBox(height: 24),

                // KPIs grid
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildKpiGrid(state),
                const SizedBox(height: 24),

                // Low stock alerts
                if (lowStockAlerts.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Alertas de Stock Bajo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...lowStockAlerts.map((alert) => _LowStockAlert(
                        store: alert.key,
                        productIds: alert.value,
                        productsMap: state.productsMap,
                      )),
                  const SizedBox(height: 24),
                ],

                // Top stores
                const Text(
                  'Tiendas Top',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),

                if (sortedStores.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.store_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'No hay tiendas registradas',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...sortedStores
                      .take(5)
                      .map((store) => _StoreListTile(store: store)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(AppState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Inventario',
                value: '\$${state.totalInventoryValue.toStringAsFixed(0)}',
                icon: Icons.wallet_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Margen Global',
                value: '\$${state.totalEstimatedProfit.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Por Cobrar',
                value: '\$${state.totalReceivable.toStringAsFixed(0)}',
                icon: Icons.attach_money_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pagos Recibidos',
                value: '\$${state.totalPaymentsReceived.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Unidades Vendidas',
                value: '${state.totalUnitsSold}',
                icon: Icons.sell_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Consignación',
                value: '${state.totalConsignment} pzas',
                icon: Icons.inventory_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Inversión Producción',
                value: '\$${state.totalProductionCost.toStringAsFixed(0)}',
                icon: Icons.precision_manufacturing_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Margen Promedio',
                value: '${state.averageMarginPercent.toStringAsFixed(1)}%',
                icon: Icons.percent_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Dashboard Hero Card ─────────────────────────────────────

class _DashboardHero extends StatelessWidget {
  final AppState state;
  final double roi;
  final double netProfit;
  const _DashboardHero({
    required this.state,
    required this.roi,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    final receivable = state.totalReceivable;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.view_in_ar_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'J3D SQ — ERP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Impresiones 3D · Llaveros',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roi >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ROI ${roi.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ganancia Neta',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '\$${netProfit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text('Pendiente',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(
                      '\$${receivable.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroChip(
                  icon: Icons.store_rounded,
                  label: '${state.stores.length} tiendas'),
              const SizedBox(width: 8),
              _HeroChip(
                  icon: Icons.category_rounded,
                  label: '${state.products.length} productos'),
              const SizedBox(width: 8),
              _HeroChip(
                  icon: Icons.contacts_rounded,
                  label: '${state.contacts.length} contactos'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────

// ─── Financial Insights ──────────────────────────────────────

class _FinancialInsights extends StatelessWidget {
  final double totalRevenue;
  final double totalProdCost;
  final double totalPayments;
  final double pendingBalance;
  final String? topProductName;
  final int topProductQty;
  final String? topStoreName;
  final double topStoreRev;

  const _FinancialInsights({
    required this.totalRevenue,
    required this.totalProdCost,
    required this.totalPayments,
    required this.pendingBalance,
    required this.topProductName,
    required this.topProductQty,
    required this.topStoreName,
    required this.topStoreRev,
  });

  @override
  Widget build(BuildContext context) {
    final collectedTotal = totalPayments + pendingBalance;
    final collectedPct =
        collectedTotal > 0 ? totalPayments / collectedTotal : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Insights Financieros',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cash collection progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cobrado vs Pendiente',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(
                '${(collectedPct * 100).toStringAsFixed(0)}% cobrado',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: collectedPct,
              backgroundColor: AppColors.warning.withOpacity(0.2),
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${totalPayments.toStringAsFixed(0)} cobrado',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.success),
              ),
              Text(
                '\$${pendingBalance.toStringAsFixed(0)} pendiente',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Top product & store
          Row(
            children: [
              if (topProductName != null)
                Expanded(
                  child: _InsightChip(
                    icon: Icons.star_rounded,
                    label: 'Top Producto',
                    value: '$topProductName ($topProductQty uds)',
                    color: AppColors.primary,
                  ),
                ),
              if (topProductName != null && topStoreName != null)
                const SizedBox(width: 8),
              if (topStoreName != null)
                Expanded(
                  child: _InsightChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'Top Tienda',
                    value: '$topStoreName (\$${topStoreRev.toStringAsFixed(0)})',
                    color: const Color(0xFFFFD700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.contacts_rounded,
            label: 'Contactos',
            color: const Color(0xFF00CEC9),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.calculate_rounded,
            label: 'Calculadora',
            color: const Color(0xFFFDAA5B),
            onTap: () => _showCostCalculator(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.bar_chart_rounded,
            label: 'Resumen',
            color: AppColors.primary,
            onTap: () {
              // Navigate to finances tab
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ve a la pestaña Finanzas')),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCostCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _QuickCostCalculator(),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
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

// ─── Quick Cost Calculator ───────────────────────────────────

class _QuickCostCalculator extends StatefulWidget {
  const _QuickCostCalculator();

  @override
  State<_QuickCostCalculator> createState() => _QuickCostCalculatorState();
}

class _QuickCostCalculatorState extends State<_QuickCostCalculator> {
  final _filamentCtrl = TextEditingController(text: '20');
  final _filamentCostCtrl = TextEditingController(text: '300');
  final _printTimeCtrl = TextEditingController(text: '60');
  final _electricityCtrl = TextEditingController(text: '3');
  final _laborCtrl = TextEditingController(text: '10');
  final _laborCostCtrl = TextEditingController(text: '50');
  final _extrasCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(text: '45');

  @override
  void dispose() {
    _filamentCtrl.dispose();
    _filamentCostCtrl.dispose();
    _printTimeCtrl.dispose();
    _electricityCtrl.dispose();
    _laborCtrl.dispose();
    _laborCostCtrl.dispose();
    _extrasCtrl.dispose();
    _priceCtrl.dispose();
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

  double get _price => double.tryParse(_priceCtrl.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Calculadora de Costos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Calcula el costo real de producción 3D',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: _CalcField(
                    label: 'Filamento (g)', ctrl: _filamentCtrl, onChanged: () => setState(() {})),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CalcField(
                    label: 'Costo/kg (\$)', ctrl: _filamentCostCtrl, onChanged: () => setState(() {})),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _CalcField(
                    label: 'Tiempo impresión (min)', ctrl: _printTimeCtrl, onChanged: () => setState(() {})),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CalcField(
                    label: 'Electricidad \$/hr', ctrl: _electricityCtrl, onChanged: () => setState(() {})),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _CalcField(
                    label: 'Mano de obra (min)', ctrl: _laborCtrl, onChanged: () => setState(() {})),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CalcField(
                    label: 'Costo/hr M.O. (\$)', ctrl: _laborCostCtrl, onChanged: () => setState(() {})),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _CalcField(
                    label: 'Costos Extra (\$)', ctrl: _extrasCtrl, onChanged: () => setState(() {})),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CalcField(
                    label: 'Precio Venta (\$)', ctrl: _priceCtrl, onChanged: () => setState(() {})),
              ),
            ]),
            const SizedBox(height: 24),

            // Results
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _ResultRow('Filamento', '\$${_breakdown.filamentCost.toStringAsFixed(2)}'),
                  _ResultRow('Electricidad', '\$${_breakdown.electricityCost.toStringAsFixed(2)}'),
                  _ResultRow('Mano de obra', '\$${_breakdown.laborCost.toStringAsFixed(2)}'),
                  if (_breakdown.extraCosts > 0)
                    _ResultRow('Extras', '\$${_breakdown.extraCosts.toStringAsFixed(2)}'),
                  const Divider(color: Colors.white30, height: 20),
                  _ResultRow('COSTO TOTAL', '\$${_breakdown.totalCost.toStringAsFixed(2)}',
                      isBold: true),
                  if (_price > 0) ...[
                    const SizedBox(height: 8),
                    _ResultRow('Margen',
                        '\$${(_price - _breakdown.totalCost).toStringAsFixed(2)} (${((_price - _breakdown.totalCost) / _price * 100).toStringAsFixed(1)}%)',
                        isBold: true,
                        color: (_price - _breakdown.totalCost) >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CalcField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  const _CalcField(
      {required this.label, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _ResultRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              )),
          Text(value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ─── Low Stock Alert ─────────────────────────────────────────

class _LowStockAlert extends StatelessWidget {
  final StoreModel store;
  final List<String> productIds;
  final Map<String, ProductModel> productsMap;
  const _LowStockAlert(
      {required this.store,
      required this.productIds,
      required this.productsMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  productIds.map((id) {
                    final p = productsMap[id];
                    final stock = store.inventory[id]?.stock ?? 0;
                    return '${p?.name ?? "?"} ($stock pzas)';
                  }).join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(storeId: store.id),
              ),
            ),
            child: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Store List Tile ─────────────────────────────────────────

class _StoreListTile extends StatelessWidget {
  final StoreModel store;
  const _StoreListTile({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreDetailScreen(storeId: store.id),
        ),
      ),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${store.totalStock} stock · ${store.totalSold} vendidas',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${store.balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: store.balance > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
                const Text(
                  'por cobrar',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
