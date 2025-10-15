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
    'createdAt': createdAt,
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    phone: map['phone'],
    address: map['address'],
    items: List<Map<String, dynamic>>.from(map['items'] ?? []),
    total: (map['total'] ?? 0).toDouble(),
    discount: (map['discount'] ?? 0).toDouble(),
    finalTotal: (map['finalTotal'] ?? 0).toDouble(),
    coupon: map['coupon'],
    slipUrl: map['slipUrl'] ?? '',
    status: map['status'] ?? OrderStatus.pending,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );
}
