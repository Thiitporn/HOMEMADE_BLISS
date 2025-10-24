import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'dart:convert';

class OrdersController {
  final _ordersRef = FirebaseFirestore.instance.collection('orders');

  Future<void> createOrder(OrderModel order) async {
    final data = order.toMap();
    print('DEBUG: Order data to Firestore:');
    try {
      print(JsonEncoder.withIndent('  ').convert(data));
    } catch (_) {
      print(data);
    }
    await _ordersRef.doc(order.id).set(data);
  }

  Stream<List<OrderModel>> userOrders(String userId) {
    return _ordersRef.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((doc) => OrderModel.fromMap(doc.data())).toList(),
    );
  }

  Stream<List<OrderModel>> allOrders() {
    return _ordersRef.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((doc) => OrderModel.fromMap(doc.data())).toList(),
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _ordersRef.doc(orderId).update({'status': status});
  }
}
