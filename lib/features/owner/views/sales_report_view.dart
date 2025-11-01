import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesReportView extends StatefulWidget {
  const SalesReportView({super.key});

  @override
  State<SalesReportView> createState() => _SalesReportViewState();
}

enum _ReportRange {
  sevenDays('7 วันล่าสุด'),
  fourteenDays('14 วันล่าสุด'),
  thirtyDays('30 วันล่าสุด');

  const _ReportRange(this.label);

  final String label;
}

enum _TrendGrouping {
  daily('รายวัน'),
  weekly('รายสัปดาห์'),
  monthly('รายเดือน');

  const _TrendGrouping(this.label);

  final String label;
}

class _ProductSalesData {
  _ProductSalesData({
    required this.id,
    required this.name,
    double revenue = 0,
    double quantity = 0,
  })  : revenue = revenue,
        quantity = quantity;

  final String id;
  final String name;
  double revenue;
  double quantity;
}

class _TrendPoint {
  const _TrendPoint({
    required this.period,
    required this.label,
    required this.revenue,
  });

  final DateTime period;
  final String label;
  final double revenue;
}

class _PaymentSummary {
  const _PaymentSummary({
    required this.orderId,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  final String orderId;
  final double amount;
  final String status;
  final DateTime? createdAt;
}

class _SalesReportViewState extends State<SalesReportView> {
  _ReportRange _range = _ReportRange.sevenDays;
  String _selectedStatus = 'all';
  _TrendGrouping _trendGrouping = _TrendGrouping.daily;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_range) {
      case _ReportRange.sevenDays:
        return now.subtract(const Duration(days: 7));
      case _ReportRange.fourteenDays:
        return now.subtract(const Duration(days: 14));
      case _ReportRange.thirtyDays:
        return now.subtract(const Duration(days: 30));
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream(
    DateTime startDate,
  ) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .snapshots();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
        return const Color(0xFF6B705C);
      case 'pending':
        return const Color(0xFFB08968);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFD62828);
      case 'shipping':
      case 'delivering':
        return const Color(0xFF81B29A);
      default:
        return const Color(0xFF77736C);
    }
  }

  String _statusLabel(String status) {
    if (status == 'all') {
      return 'ทั้งหมด';
    }
    return _statusLabels[status] ?? status;
  }

  static const Map<String, String> _statusLabels = {
    'pending': 'รอดำเนินการ',
    'paid': 'ชำระเงินแล้ว',
    'shipping': 'กำลังจัดส่ง',
    'delivering': 'กำลังจัดส่ง',
    'completed': 'สำเร็จ',
    'cancelled': 'ยกเลิก',
    'rejected': 'ปฏิเสธ',
    'unknown': 'ไม่ทราบสถานะ',
  };

  Map<String, _ProductSalesData> _buildProductAggregates(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = <String, _ProductSalesData>{};
    for (final doc in docs) {
      final data = doc.data();
      final items = data['items'];
      if (items is! List) continue;
      for (final raw in items) {
        if (raw is! Map) continue;
        final item = raw.map((key, value) => MapEntry(key.toString(), value));
        final id = (item['id'] ?? item['productId'] ?? item['name'] ?? doc.id)
            .toString();
        final name = (item['name'] ?? 'ไม่ระบุชื่อสินค้า').toString();
        final quantityRaw = item['quantity'];
        final quantity = quantityRaw is num
            ? quantityRaw.toDouble()
            : double.tryParse(quantityRaw?.toString() ?? '') ?? 0;
        final unitPrice = _toDouble(
          item['price'] ?? item['finalPrice'] ?? item['subTotal'],
        );
        final lineTotal = unitPrice * quantity;
        final entry = result.putIfAbsent(
          id,
          () => _ProductSalesData(id: id, name: name),
        );
        entry.revenue += lineTotal;
        entry.quantity += quantity;
      }
    }
    return result;
  }

  List<_TrendPoint> _buildTrendData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    _TrendGrouping grouping,
  ) {
    final totals = <DateTime, double>{};
    for (final doc in docs) {
      final data = doc.data();
      final createdRaw = data['createdAt'];
      DateTime? created;
      if (createdRaw is Timestamp) {
        created = createdRaw.toDate();
      } else if (createdRaw is DateTime) {
        created = createdRaw;
      }
      if (created == null) continue;
      final key = _groupKey(created, grouping);
      final revenue = _toDouble(
        data['finalTotal'] ?? data['total'] ?? data['totalPrice'],
      );
      totals.update(key, (value) => value + revenue, ifAbsent: () => revenue);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (entry) => _TrendPoint(
            period: entry.key,
            label: _trendLabel(entry.key, grouping),
            revenue: entry.value,
          ),
        )
        .toList();
  }

  DateTime _groupKey(DateTime date, _TrendGrouping grouping) {
    switch (grouping) {
      case _TrendGrouping.daily:
        return DateTime(date.year, date.month, date.day);
      case _TrendGrouping.weekly:
        final diff = date.weekday - DateTime.monday;
        final startOfWeek = date.subtract(Duration(days: diff < 0 ? 6 : diff));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case _TrendGrouping.monthly:
        return DateTime(date.year, date.month);
    }
  }

  String _trendLabel(DateTime date, _TrendGrouping grouping) {
    switch (grouping) {
      case _TrendGrouping.daily:
        return '${date.day}/${date.month}';
      case _TrendGrouping.weekly:
        return 'ส. ${date.day}/${date.month}';
      case _TrendGrouping.monthly:
        final shortYear = date.year % 100;
        return '${date.month}/$shortYear';
    }
  }

  bool _isPaidStatus(String status) {
    const paidStatuses = {
      'paid',
      'completed',
      'shipping',
      'delivering',
      'preparing',
    };
    return paidStatuses.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startDate = _startDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EC),
      appBar: AppBar(
        title: const Text('รายงานยอดขาย'),
        backgroundColor: const Color(0xFFF6F2EC),
        foregroundColor: const Color(0xFF3C3A37),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBF7F0), Color(0xFFEDE6DE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ภาพรวมยอดขาย',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF3C3A37),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ข้อมูลตั้งแต่ ${_formatDate(startDate)} ถึงวันนี้',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A746D),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _ReportRange.values.map((range) {
                      final selected = range == _range;
                      return ChoiceChip(
                        label: Text(range.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _range = range),
                        backgroundColor: const Color(0xFFEDE7DF),
                        selectedColor: const Color(0xFF6B705C),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              selected ? Colors.white : const Color(0xFF514C47),
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ordersStream(startDate),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filteredDocs =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                double totalRevenue = 0;
                final Map<String, int> statusCounts = {};

                for (final doc in docs) {
                  final data = doc.data();
                  final createdRaw = data['createdAt'];
                  DateTime? created;
                  if (createdRaw is Timestamp) {
                    created = createdRaw.toDate();
                  } else if (createdRaw is DateTime) {
                    created = createdRaw;
                  }
                  if (created == null || created.isBefore(startDate)) {
                    continue;
                  }

                  filteredDocs.add(doc);

                  final revenue = _toDouble(
                    data['finalTotal'] ?? data['total'] ?? data['totalPrice'],
                  );
                  totalRevenue += revenue;

                  final status = data['status']?.toString() ?? 'unknown';
                  statusCounts.update(
                    status,
                    (value) => value + 1,
                    ifAbsent: () => 1,
                  );
                }

                final totalOrders = filteredDocs.length;
                final totalStatusCount = statusCounts.values.fold<int>(
                  0,
                  (sum, value) => sum + value,
                );
                final filterEntries = <String, int>{
                  'all': totalOrders,
                  ...statusCounts,
                };
                final visibleFilters = filterEntries.entries
                    .where((entry) => entry.key == 'all' || entry.value > 0)
                    .toList();
                final displayDocs = _selectedStatus == 'all'
                    ? filteredDocs
                    : filteredDocs
                        .where((doc) =>
                            (doc.data()['status']?.toString() ?? 'unknown') ==
                            _selectedStatus)
                        .toList();
                final emptyOrdersMessage = _selectedStatus == 'all'
                    ? 'ไม่มีคำสั่งซื้อในช่วงเวลาที่เลือก'
                    : 'ไม่มีคำสั่งซื้อในสถานะนี้';

                final productAggregatesMap =
                    _buildProductAggregates(filteredDocs);
                final productAggregates = productAggregatesMap.values
                    .where((product) => product.revenue > 0)
                    .toList()
                  ..sort(
                    (a, b) => b.revenue.compareTo(a.revenue),
                  );
                _ProductSalesData? highestProduct;
                for (final product in productAggregates) {
                  if (product.revenue > 0) {
                    highestProduct = product;
                    break;
                  }
                }
                _ProductSalesData? lowestProduct;
                for (final product in productAggregates.reversed) {
                  if (product.revenue > 0) {
                    lowestProduct = product;
                    break;
                  }
                }
                final topProduct = highestProduct;
                final bottomProduct = lowestProduct;

                final trendPoints =
                    _buildTrendData(filteredDocs, _trendGrouping);

                final paidOrders = filteredDocs
                    .where((doc) =>
                        _isPaidStatus(doc.data()['status']?.toString() ?? ''))
                    .toList();
                final unpaidOrders = filteredDocs
                    .where((doc) =>
                        !_isPaidStatus(doc.data()['status']?.toString() ?? ''))
                    .toList();

                List<_PaymentSummary> _mapOrders(
                  List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
                ) {
                  return orders.map((doc) {
                    final data = doc.data();
                    final createdRaw = data['createdAt'];
                    DateTime? created;
                    if (createdRaw is Timestamp) {
                      created = createdRaw.toDate();
                    } else if (createdRaw is DateTime) {
                      created = createdRaw;
                    }
                    final amount = _toDouble(
                      data['finalTotal'] ??
                          data['total'] ??
                          data['totalPrice'],
                    );
                    final status = data['status']?.toString() ?? 'unknown';
                    return _PaymentSummary(
                      orderId: doc.id,
                      amount: amount,
                      status: status,
                      createdAt: created,
                    );
                  }).toList();
                }

                final paidSummaries = _mapOrders(paidOrders);
                final unpaidSummaries = _mapOrders(unpaidOrders);

                final totalPaid = paidSummaries.fold<double>(
                  0,
                  (sum, order) => sum + order.amount,
                );
                final totalUnpaid = unpaidSummaries.fold<double>(
                  0,
                  (sum, order) => sum + order.amount,
                );

                final overviewMetrics = [
                  _MetricTileData(
                    title: 'ยอดขายรวม',
                    value: '฿${totalRevenue.toStringAsFixed(2)}',
                    description: 'ช่วงเวลาที่เลือก',
                    icon: Icons.payments_outlined,
                    gradient: const [Color(0xFFDED2C4), Color(0xFFF6EFE7)],
                  ),
                  _MetricTileData(
                    title: 'คำสั่งซื้อทั้งหมด',
                    value: '$totalOrders',
                    description: 'รวมทุกสถานะ',
                    icon: Icons.receipt_long_outlined,
                    gradient: const [Color(0xFFC9E3F9), Color(0xFFE8F3FF)],
                  ),
                  _MetricTileData(
                    title: 'ชำระเงินแล้ว',
                    value: '${paidOrders.length}',
                    description: 'นับออเดอร์ที่จ่ายแล้ว',
                    icon: Icons.verified_outlined,
                    gradient: const [Color(0xFFD9C6F4), Color(0xFFF1E7FF)],
                  ),
                  _MetricTileData(
                    title: 'รอการชำระ',
                    value: '${unpaidOrders.length}',
                    description: 'ต้องติดตามเพิ่มเติม',
                    icon: Icons.pending_actions_outlined,
                    gradient: const [Color(0xFFD4EFD8), Color(0xFFEFFAEF)],
                  ),
                ];

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: const Color(0xFF6B705C),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _SectionCard(
                        title: 'ภาพรวมยอดขาย',
                        subtitle:
                            'ข้อมูลตั้งแต่ ${_formatDate(startDate)} ถึงวันนี้',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _ReportRange.values.map((range) {
                                final selected = range == _range;
                                return ChoiceChip(
                                  label: Text(range.label),
                                  selected: selected,
                                  onSelected: (_) => setState(() {
                                    _range = range;
                                  }),
                                  backgroundColor: const Color(0xFFEDE7DF),
                                  selectedColor: const Color(0xFF6B705C),
                                  labelStyle:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF514C47),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            _OverviewMetrics(metrics: overviewMetrics),
                          ],
                        ),
                      ),
                      _SectionCard(
                        title: 'สถานะคำสั่งซื้อ',
                        child: statusCounts.isEmpty
                            ? const _EmptyPlaceholder(
                                message: 'ยังไม่มีคำสั่งซื้อในช่วงเวลานี้',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: visibleFilters.map((entry) {
                                        final status = entry.key;
                                        final isSelected =
                                            status == _selectedStatus;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Text(
                                              '${_statusLabel(status)} (${entry.value})',
                                            ),
                                            selected: isSelected,
                                            onSelected: (_) => setState(() {
                                              _selectedStatus = status;
                                            }),
                                            backgroundColor:
                                                const Color(0xFFF3EEE9),
                                            selectedColor:
                                                const Color(0xFF6B705C),
                                            labelStyle: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF514C47),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...statusCounts.entries.map((entry) {
                                    final color = _statusColor(entry.key);
                                    final ratio = totalStatusCount == 0
                                        ? 0.0
                                        : entry.value / totalStatusCount;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _StatusSummaryTile(
                                        label: _statusLabel(entry.key),
                                        count: entry.value,
                                        ratio: ratio,
                                        color: color,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                      ),
                      _SectionCard(
                        title: 'ยอดขายแยกตามสินค้า',
                        child: productAggregates.isEmpty
                            ? const _EmptyPlaceholder(
                                message: 'ยังไม่มีข้อมูลยอดขายสินค้าในช่วงนี้',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final cards = <Widget>[];
                                      if (topProduct != null) {
                                        cards.add(
                                          _ProductHighlightCard(
                                            title: 'สินค้าขายดี',
                                            product: topProduct,
                                            accent: const Color(0xFF6B705C),
                                          ),
                                        );
                                      }
                                      if (bottomProduct != null &&
                                          bottomProduct.id !=
                                              topProduct?.id) {
                                        cards.add(
                                          _ProductHighlightCard(
                                            title: 'สินค้าควรผลักดันเพิ่ม',
                                            product: bottomProduct,
                                            accent: const Color(0xFFB08968),
                                          ),
                                        );
                                      }
                                      if (cards.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                    final width = constraints.maxWidth;
                    final columns = width >= 720
                      ? 3
                      : width >= 340
                        ? 2
                        : 1;
                                      const spacing = 16.0;
                                      final itemWidth = columns == 1
                                          ? width
                                          : (width - spacing * (columns - 1)) /
                                              columns;
                                      return Wrap(
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children: cards
                                            .map(
                                              (card) => SizedBox(
                                                width: columns == 1
                                                    ? width
                                                    : itemWidth,
                                                child: card,
                                              ),
                                            )
                                            .toList(),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDFBF8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE9E1D8),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'รายละเอียดสินค้า (Top 5)',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF3C3A37),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...productAggregates
                                            .take(5)
                                            .map(
                                              (product) => _ProductBar(
                                                data: product,
                                                maxRevenue:
                                                    productAggregates.first
                                                        .revenue,
                                              ),
                                            )
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      _SectionCard(
                        title: 'แนวโน้มยอดขาย',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _TrendGrouping.values.map((grouping) {
                                final selected = grouping == _trendGrouping;
                                return ChoiceChip(
                                  label: Text(grouping.label),
                                  selected: selected,
                                  onSelected: (_) => setState(() {
                                    _trendGrouping = grouping;
                                  }),
                                  backgroundColor: const Color(0xFFF3EEE9),
                                  selectedColor: const Color(0xFF6B705C),
                                  labelStyle:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF514C47),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            _SalesTrendChart(points: trendPoints),
                          ],
                        ),
                      ),
                      _SectionCard(
                        title: 'สถานะการชำระเงิน',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PaymentStatusSummary(
                              title: 'ชำระเงินแล้ว',
                              amount: totalPaid,
                              orders: paidSummaries,
                              accentColor: const Color(0xFF6B705C),
                              emptyMessage: 'ยังไม่มีออเดอร์ที่ชำระแล้ว',
                            ),
                            const SizedBox(height: 16),
                            _PaymentStatusSummary(
                              title: 'รอการชำระ',
                              amount: totalUnpaid,
                              orders: unpaidSummaries,
                              accentColor: const Color(0xFFB08968),
                              emptyMessage: 'ยอดขายที่ยังไม่ได้รับการชำระว่างอยู่',
                            ),
                          ],
                        ),
                      ),
                      _SectionCard(
                        title: 'คำสั่งซื้อทั้งหมด',
                        child: displayDocs.isEmpty
                            ? _EmptyPlaceholder(message: emptyOrdersMessage)
                            : Column(
                                children: List.generate(displayDocs.length,
                                    (index) {
                                  final doc = displayDocs[index];
                                  final data = doc.data();
                                  final createdRaw = data['createdAt'];
                                  DateTime? created;
                                  if (createdRaw is Timestamp) {
                                    created = createdRaw.toDate();
                                  } else if (createdRaw is DateTime) {
                                    created = createdRaw;
                                  }
                                  final status =
                                      data['status']?.toString() ?? 'unknown';
                                  final finalTotal = _toDouble(
                                    data['finalTotal'] ??
                                        data['total'] ??
                                        data['totalPrice'],
                                  );
                                  final isLast =
                                      index == displayDocs.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 12,
                                    ),
                                    child: _OrderTile(
                                      orderId: doc.id,
                                      statusLabel:
                                          _statusLabels[status] ?? status,
                                      statusColor: _statusColor(status),
                                      createdText: created == null
                                          ? null
                                          : _formatDate(created),
                                      total: finalTotal,
                                    ),
                                  );
                                }),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9E1D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF3C3A37),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A746D),
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
  color: const Color(0xFFF8F2ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E1D8)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF7A746D),
        ),
      ),
    );
  }
}

class _MetricTileData {
  const _MetricTileData({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.description,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? description;
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics({required this.metrics});

  final List<_MetricTileData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 16.0;
        final columns = availableWidth >= 320 ? 2 : 1;
        final itemWidth = columns == 1
            ? availableWidth
            : (availableWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            final tileWidth = columns == 1 ? availableWidth : itemWidth;
            return SizedBox(
              width: tileWidth,
              child: _MetricTile(data: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: const Color(0xFF3C3A37),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2F2B28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF514C47),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            softWrap: true,
          ),
          if (data.description != null) ...[
            const SizedBox(height: 6),
            Text(
              data.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A746D),
              ),
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusSummaryTile extends StatelessWidget {
  const _StatusSummaryTile({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int count;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ratio.clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3C3A37),
                  ),
                ),
              ),
              Text(
                '$count ออเดอร์',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A746D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHighlightCard extends StatelessWidget {
  const _ProductHighlightCard({
    required this.title,
    required this.product,
    required this.accent,
  });

  final String title;
  final _ProductSalesData product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C3A37),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ยอดขาย ฿${product.revenue.toStringAsFixed(2)} • ${product.quantity.toStringAsFixed(0)} ชิ้น',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7A746D),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.orderId,
    required this.statusLabel,
    required this.statusColor,
    required this.total,
    this.createdText,
  });

  final String orderId;
  final String statusLabel;
  final Color statusColor;
  final double total;
  final String? createdText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E1D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ออเดอร์ #$orderId',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3C3A37),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (createdText != null) ...[
            const SizedBox(height: 10),
            Text(
              createdText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A746D),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'ยอดสุทธิ ฿${total.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C3A37),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBar extends StatelessWidget {
  const _ProductBar({
    required this.data,
    required this.maxRevenue,
  });

  final _ProductSalesData data;
  final double maxRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxRevenue <= 0 ? 0.0 : data.revenue / maxRevenue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF3C3A37),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '฿${data.revenue.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A746D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1ECE6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6B705C),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.quantity.toStringAsFixed(0)} ชิ้น',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF96918B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'ยังไม่มีข้อมูลยอดขายในช่วงนี้',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A746D),
            ),
          ),
        ),
      );
    }

    final displayPoints = points.length > 12
        ? points.sublist(points.length - 12)
        : points;
    final maxValue = displayPoints.fold<double>(
      0,
      (value, point) => math.max(value, point.revenue),
    );

    if (maxValue <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'กำลังรอข้อมูลยอดขายเพิ่มเติม',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A746D),
            ),
          ),
        ),
      );
    }

    final totalRevenue = displayPoints.fold<double>(
      0,
      (sum, point) => sum + point.revenue,
    );
    final averageRevenue = totalRevenue / displayPoints.length;
    final firstRevenue = displayPoints.first.revenue;
    final latestPoint = displayPoints.last;
    final revenueDelta = latestPoint.revenue - firstRevenue;
    final revenueTrendPercentage = firstRevenue <= 0
        ? null
        : ((revenueDelta / firstRevenue) * 100).clamp(-999, 999);
    final trendIsPositive = revenueDelta >= 0;
    final trendColor = trendIsPositive
        ? const Color(0xFF4A7856)
        : const Color(0xFFD35D4A);

    List<_TrendPoint> buildAxisPoints() {
      if (displayPoints.length <= 6) {
        return displayPoints;
      }
      const count = 6;
      final step = (displayPoints.length - 1) / (count - 1);
      final result = <_TrendPoint>[];
      for (var i = 0; i < count; i++) {
        final index = (i * step).round().clamp(0, displayPoints.length - 1);
        final candidate = displayPoints[index];
        if (result.isNotEmpty && result.last.label == candidate.label) {
          continue;
        }
        result.add(candidate);
      }
      if (result.length < 2) {
        result.add(displayPoints.last);
      }
      return result;
    }

    Widget buildStatTile({
      required String title,
      required String value,
      String? caption,
      Color? accent,
    }) {
      final baseColor = accent ?? const Color(0xFF6B705C);
      final titleColor = Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor;
      final captionColor = Color.lerp(baseColor, Colors.black, 0.6) ?? baseColor;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: baseColor.withOpacity(0.12),
          border: Border.all(color: baseColor.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2F2B28),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: captionColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final axisPoints = buildAxisPoints();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isTwoColumn = maxWidth >= 360;
        final tileWidth = isTwoColumn ? (maxWidth - 12) / 2 : maxWidth;

        final statTiles = <Widget>[
          SizedBox(
            width: tileWidth,
            child: buildStatTile(
              title: 'ยอดขายรวม',
              value: '฿${totalRevenue.toStringAsFixed(0)}',
              caption: '${displayPoints.length} ช่วงเวลา',
              accent: const Color(0xFF6B705C),
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: buildStatTile(
              title: 'เฉลี่ยต่อช่วง',
              value: '฿${averageRevenue.toStringAsFixed(0)}',
              caption: 'ล่าสุด ${latestPoint.label}',
              accent: const Color(0xFFB08968),
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: buildStatTile(
              title: trendIsPositive ? 'แนวโน้มเพิ่มขึ้น' : 'แนวโน้มลดลง',
              value: '฿${revenueDelta.abs().toStringAsFixed(0)}',
              caption: revenueTrendPercentage == null
                  ? null
                  : '${trendIsPositive ? '+' : '-'}${revenueTrendPercentage.abs().toStringAsFixed(1)}%',
              accent: trendColor,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: statTiles,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 2.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFDFBF8), Color(0xFFF7F0E8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: CustomPaint(
                    painter: _SalesTrendPainter(
                      points: displayPoints,
                      lineColor: const Color(0xFF6B705C),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 18,
              child: Row(
                children: axisPoints.map((point) {
                  return Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          point.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6D645D),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  const _SalesTrendPainter({
    required this.points,
    required this.lineColor,
  });

  final List<_TrendPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      final y = size.height * 0.6;
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawCircle(Offset(size.width, y), 4, Paint()..color = lineColor);
      return;
    }

    final maxRevenue = points.fold<double>(
      0,
      (current, point) => math.max(current, point.revenue),
    );
    final minRevenue = points.fold<double>(
      double.infinity,
      (current, point) => math.min(current, point.revenue),
    );
    final range = (maxRevenue - minRevenue).abs() < 0.01
        ? 1.0
        : maxRevenue - minRevenue;

    final fillPath = Path();
    final linePath = Path();
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = stepX * i;
      final normalized = ((point.revenue - minRevenue) / range)
          .clamp(0.0, 1.0);
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withOpacity(0.26),
          lineColor.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE3DBCF)
      ..strokeWidth = 1;
    const gridLines = 3;
    for (var i = 1; i <= gridLines; i++) {
      final dy = size.height * (i / (gridLines + 1));
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    final latestPoint = points.last;
    final latestIndex = points.length - 1;
    final latestX = stepX * latestIndex;
    final latestNormalized = ((latestPoint.revenue - minRevenue) / range)
        .clamp(0.0, 1.0);
    final latestY = size.height - (latestNormalized * size.height);

    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(Offset(latestX, latestY), 4, dotPaint);
    canvas.drawCircle(
      Offset(latestX, latestY),
      8,
      Paint()..color = lineColor.withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    return true;
  }
}

class _PaymentStatusSummary extends StatelessWidget {
  const _PaymentStatusSummary({
    required this.title,
    required this.amount,
    required this.orders,
    required this.accentColor,
    required this.emptyMessage,
  });

  final String title;
  final double amount;
  final List<_PaymentSummary> orders;
  final Color accentColor;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3C3A37),
                ),
              ),
            ),
            Text(
              'รวม ฿${amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A746D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A746D),
              ),
            ),
          )
        else
          Column(
            children: orders.take(5).map((order) {
              final created = order.createdAt;
              final createdText = created == null
                  ? '-'
                  : '${created.day}/${created.month}/${created.year}';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAE2D9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderId}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3C3A37),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            createdText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF96918B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        order.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '฿${order.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3C3A37),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
