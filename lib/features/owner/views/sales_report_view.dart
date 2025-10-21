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

class _SalesReportViewState extends State<SalesReportView> {
  _ReportRange _range = _ReportRange.sevenDays;
  String _selectedStatus = 'all';

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

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: const Color(0xFF6B705C),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              title: 'ยอดขายรวม',
                              value: '฿${totalRevenue.toStringAsFixed(2)}',
                              icon: Icons.payments_outlined,
                              iconBackground: const Color(0xFF6B705C),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SummaryTile(
                              title: 'จำนวนคำสั่งซื้อ',
                              value: '$totalOrders',
                              icon: Icons.receipt_long_outlined,
                              iconBackground: const Color(0xFFB08968),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'สถานะคำสั่งซื้อ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF3C3A37),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (statusCounts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE3DAD1)),
                          ),
                          child: const Text('ยังไม่มีคำสั่งซื้อในช่วงเวลานี้'),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: visibleFilters.map((entry) {
                                  final status = entry.key;
                                  final isSelected = status == _selectedStatus;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        '${_statusLabel(status)} (${entry.value})',
                                      ),
                                      selected: isSelected,
                                      onSelected: (_) => setState(
                                        () => _selectedStatus = status,
                                      ),
                                      backgroundColor: const Color(0xFFF0ECE6),
                                      selectedColor: const Color(0xFF6B705C),
                                      labelStyle:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF514C47),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF6B705C)
                                              : Colors.transparent,
                                        ),
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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE9E1D8),
                                  ),
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
                                            _statusLabel(entry.key),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3C3A37),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${entry.value} ออเดอร์',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: const Color(0xFF7A746D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor:
                                            const Color(0xFFF1ECE6),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'คำสั่งซื้อทั้งหมด',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF3C3A37),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (displayDocs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9E1D8)),
                          ),
                          child: Text(emptyOrdersMessage),
                        )
                      else
                        ...displayDocs.map((doc) {
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
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE9E1D8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ออเดอร์ #${doc.id}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
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
                                        color: _statusColor(status)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        _statusLabels[status] ?? status,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (created != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _formatDate(created),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF7A746D),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  'ยอดสุทธิ ฿${finalTotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF3C3A37),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E1D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7A746D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C3A37),
            ),
          ),
        ],
      ),
    );
  }
}
