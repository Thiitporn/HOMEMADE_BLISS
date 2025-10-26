import 'package:cloud_firestore/cloud_firestore.dart';
class OrderStatus {
  static const String pending = 'pending'; // รอชำระเงิน/รอตรวจสอบ
  static const String paid = 'paid'; // ชำระเงินแล้ว/รอจัดส่ง
  static const String completed = 'completed'; // ส่งสำเร็จ
  static const String cancelled = 'cancelled'; // ยกเลิก
}

class OrderModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String address;
  final List<Map<String, dynamic>> items;
  final double total;
  final double discount;
  final double finalTotal;
  final String? coupon;
  final String slipUrl;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.discount,
    required this.finalTotal,
    required this.coupon,
    required this.slipUrl,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'phone': phone,
    'address': address,
    'items': items,
    'total': total,
    'discount': discount,
    'finalTotal': finalTotal,
    'coupon': coupon,
    'slipUrl': slipUrl,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    String _stringOrEmpty(dynamic value) => value == null ? '' : value.toString();

    final items = <Map<String, dynamic>>[];
    final rawItems = map['items'];
    if (rawItems is Iterable) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(
            raw.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      }
    }

    return OrderModel(
      id: _stringOrEmpty(map['id']),
      userId: _stringOrEmpty(map['userId']),
      name: _stringOrEmpty(map['name']),
      phone: _stringOrEmpty(map['phone']),
      address: _stringOrEmpty(map['address']),
      items: items,
      total: (map['total'] is num) ? (map['total'] as num).toDouble() : double.tryParse('${map['total']}') ?? 0,
      discount: (map['discount'] is num) ? (map['discount'] as num).toDouble() : double.tryParse('${map['discount']}') ?? 0,
      finalTotal: (map['finalTotal'] is num)
          ? (map['finalTotal'] as num).toDouble()
          : double.tryParse('${map['finalTotal']}') ?? 0,
      coupon: (map['coupon']?.toString().trim().isEmpty ?? true) ? null : map['coupon'].toString().trim(),
      slipUrl: _stringOrEmpty(map['slipUrl']),
      status: _stringOrEmpty(map['status']).isEmpty ? OrderStatus.pending : map['status'].toString(),
      createdAt: createdAt,
    );
  }
}
