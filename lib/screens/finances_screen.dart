import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../helpers/alerts.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

final _cur = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
final _dt = DateFormat('dd/MM/yy HH:mm');

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});
  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  int _range = 3;
  bool _historyOpen = false;

  List<TransactionModel> _filter(List<TransactionModel> all) {
    if (_range == 3) return all;
    final now = DateTime.now();
    final start = _range == 0
        ? DateTime(now.year, now.month, now.day)
        : _range == 1
            ? now.subtract(const Duration(days: 7))
            : DateTime(now.year, now.month);
    return all.where((t) => t.date.isAfter(start)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final txAll = _filter(state.transactions);
    final pm = state.productsMap;

    double grossSales = 0, commissions = 0, prodCost = 0;
    double collected = 0;
    int unitsSold = 0, unitsDelivered = 0;
    final prodRevenue = <String, double>{};
    final prodUnits = <String, int>{};
    final storeRevenue = <String, double>{};
    final catRevenue = <String, double>{};

    for (final tx in txAll) {
      switch (tx.type) {
        case TransactionType.sale:
          grossSales += tx.totalAmount;
          final store =
              state.stores.where((s) => s.id == tx.storeId).firstOrNull;
          final rate = store?.commissionRate ?? 20;
          commissions += tx.totalAmount * rate / 100;
          if (tx.items != null) {
            tx.items!.forEach((pid, qty) {
              unitsSold += qty;
              final p = pm[pid];
              if (p != null) {
                prodCost += p.effectiveCost * qty;
                prodRevenue[pid] = (prodRevenue[pid] ?? 0) + p.price * qty;
                prodUnits[pid] = (prodUnits[pid] ?? 0) + qty;
                catRevenue[p.category.label] =
                    (catRevenue[p.category.label] ?? 0) + p.price * qty;
              }
            });
          }
          storeRevenue[tx.storeId] =
              (storeRevenue[tx.storeId] ?? 0) + tx.totalAmount;
          break;
        case TransactionType.delivery:
          if (tx.items != null) {
            tx.items!.forEach((_, qty) => unitsDelivered += qty);
          }
          break;
        case TransactionType.payment:
          collected += tx.totalAmount;
          break;
      }
    }

    final netSales = grossSales - commissions;
    final netProfit = netSales - prodCost;
    final roi = prodCost > 0 ? (netProfit / prodCost) * 100 : 0.0;
    final pending = state.totalReceivable;
    final incomePerUnit = unitsSold > 0 ? netSales / unitsSold : 0.0;

    final topProducts = prodRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxProdRev =
        topProducts.isNotEmpty ? topProducts.first.value : 1.0;

    final topStores = storeRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final catEntries = catRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedTx = List<TransactionModel>.from(txAll)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Finanzas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _timeFilterRow(),
          const SizedBox(height: 12),
          _profitHero(netProfit, roi),
          const SizedBox(height: 16),
          _kpiGrid(grossSales, commissions, netSales, prodCost, collected,
              pending, unitsSold, unitsDelivered, incomePerUnit),
          const SizedBox(height: 20),
          _cashFlowCard(collected, pending),
          const SizedBox(height: 20),
          if (topProducts.isNotEmpty) ...[
            _sectionTitle('Rentabilidad por Producto', Icons.insights_rounded),
            const SizedBox(height: 8),
            ...topProducts.take(10).map((e) {
              final p = pm[e.key];
              if (p == null) return const SizedBox.shrink();
              final units = prodUnits[e.key] ?? 0;
              return _productCard(p, e.value, units, maxProdRev);
            }),
            const SizedBox(height: 20),
          ],
          if (catEntries.isNotEmpty) ...[
            _sectionTitle('Por Categoria', Icons.category_rounded),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: catEntries.map((e) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(e.key[0],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  label: Text('${e.key}: ${_cur.format(e.value)}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (topStores.isNotEmpty) ...[
            _sectionTitle('Ranking Tiendas', Icons.store_rounded),
            const SizedBox(height: 8),
            ...topStores.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              final store =
                  state.stores.where((s) => s.id == e.key).firstOrNull;
              final name = store?.name ?? e.key;
              final icon = idx == 0
                  ? Icons.emoji_events_rounded
                  : idx == 1
                      ? Icons.military_tech_rounded
                      : Icons.storefront_rounded;
              final color = idx == 0
                  ? const Color(0xFFFFD700)
                  : idx == 1
                      ? const Color(0xFFC0C0C0)
                      : AppColors.textSecondary;
              return _storeCard(name, e.value, icon, color);
            }),
            const SizedBox(height: 20),
          ],
          _costStructureCard(prodCost, commissions, unitsSold, roi),
          const SizedBox(height: 20),
          _historySection(sortedTx, pm, state),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _timeFilterRow() {
    const labels = ['Hoy', 'Semana', 'Mes', 'Todos'];
    return Row(
      children: List.generate(4, (i) {
        final sel = _range == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _range = i),
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: sel ? null : Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textSecondary)),
            ),
          ),
        );
      }),
    );
  }

  Widget _profitHero(double net, double roi) {
    final pos = net >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pos
              ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ganancia Neta',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        pos
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 14),
                    const SizedBox(width: 4),
                    Text('ROI ${roi.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_cur.format(net),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _kpiGrid(double gross, double comm, double netS, double cost,
      double coll, double pend, int sold, int deliv, double ipu) {
    Widget kpi(String label, String value, IconData ic, Color c) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, size: 18, color: c),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(children: [
      Row(children: [
        Expanded(child: kpi('Venta Bruta', _cur.format(gross),
            Icons.point_of_sale_rounded, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Comisiones', _cur.format(comm),
            Icons.percent_rounded, AppColors.warning)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Neto Ventas', _cur.format(netS),
            Icons.trending_up_rounded, AppColors.success)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: kpi('Costo Prod', _cur.format(cost),
            Icons.precision_manufacturing_rounded, AppColors.danger)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Cobrado', _cur.format(coll),
            Icons.payments_rounded, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Por Cobrar', _cur.format(pend),
            Icons.schedule_rounded, AppColors.warning)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: kpi('Uds Vendidas', '$sold',
            Icons.shopping_bag_rounded, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Uds Entregadas', '$deliv',
            Icons.local_shipping_rounded, AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: kpi('Ing/Unidad', _cur.format(ipu),
            Icons.analytics_rounded, AppColors.primary)),
      ]),
    ]);
  }

  Widget _cashFlowCard(double collected, double pending) {
    final total = collected + pending;
    final pct = total > 0 ? collected / total : 0.0;
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
          const Text('Flujo de Efectivo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.warning.withOpacity(0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cobrado: ${_cur.format(collected)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success)),
              Text('Pendiente: ${_cur.format(pending)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _productCard(
      ProductModel p, double revenue, int units, double maxRev) {
    final barW = maxRev > 0 ? revenue / maxRev : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Text('${p.marginPercent.toStringAsFixed(0)}% margen',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barW,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(p.colorValue)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$units uds',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(_cur.format(revenue),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeCard(String name, double rev, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600))),
        Text(_cur.format(rev),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _costStructureCard(
      double prodCost, double commissions, int unitsSold, double roi) {
    final total = prodCost + commissions;
    final prodPct = total > 0 ? (prodCost / total * 100).round() : 0;
    final commPct = total > 0 ? (commissions / total * 100).round() : 0;
    final avgCost = unitsSold > 0 ? prodCost / unitsSold : 0.0;
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
          Row(children: [
            const Icon(Icons.precision_manufacturing_rounded,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Estructura de Costos',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700))),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roi >= 0
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ROI ${roi.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: roi >= 0
                          ? AppColors.success
                          : AppColors.danger)),
            ),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(children: [
              Expanded(
                  flex: prodPct.clamp(1, 100),
                  child: Container(height: 10, color: AppColors.danger)),
              Expanded(
                  flex: commPct.clamp(1, 100),
                  child: Container(height: 10, color: AppColors.warning)),
            ]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 10, height: 10, color: AppColors.danger),
                const SizedBox(width: 4),
                Text('Produccion $prodPct%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
              Row(children: [
                Container(
                    width: 10, height: 10, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('Comisiones $commPct%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Text('Costo promedio/unidad: ${_cur.format(avgCost)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _historySection(List<TransactionModel> txs,
      Map<String, ProductModel> pm, AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _historyOpen = !_historyOpen),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.history_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Historial de Transacciones (${txs.length})',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700))),
              Icon(
                  _historyOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textSecondary),
            ]),
          ),
        ),
        if (_historyOpen) ...[
          const Divider(height: 1, color: AppColors.border),
          if (txs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sin transacciones',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...txs.take(50).map((tx) => _txTile(tx, pm, state)),
        ],
      ]),
    );
  }

  Widget _txTile(TransactionModel tx, Map<String, ProductModel> pm,
      AppState state) {
    IconData icon;
    Color color;
    switch (tx.type) {
      case TransactionType.payment:
        icon = Icons.payments_rounded;
        color = AppColors.primary;
        break;
      case TransactionType.delivery:
        icon = Icons.inventory_2_rounded;
        color = AppColors.textSecondary;
        break;
      case TransactionType.sale:
        icon = Icons.point_of_sale_rounded;
        color = AppColors.success;
        break;
    }

    String detail = '';
    if (tx.items != null && tx.items!.isNotEmpty) {
      detail = tx.items!.entries.map((e) {
        final name = pm[e.key]?.name ?? e.key;
        return '${e.value}x $name';
      }).join(', ');
    } else if (tx.note != null && tx.note!.isNotEmpty) {
      detail = tx.note!;
    }

    return InkWell(
      onLongPress: () async {
        final confirm = await showConfirmDelete(
          context,
          title: 'Eliminar transaccion',
          message:
              'Se revertira esta transaccion de ${tx.storeName}. Continuar?',
        );
        if (confirm && mounted) {
          try {
            await state.deleteTransaction(tx);
            if (mounted) showSuccess(context, 'Transaccion eliminada');
          } catch (e) {
            if (mounted) showError(context, 'Error: $e');
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.storeName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '${tx.type == TransactionType.payment ? "-" : ""}${_cur.format(tx.totalAmount)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tx.type == TransactionType.payment
                          ? AppColors.primary
                          : AppColors.textSecondary)),
              Text(_dt.format(tx.date),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ]),
      ),
    );
  }
}
