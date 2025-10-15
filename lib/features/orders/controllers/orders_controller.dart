import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrdersController {
  final _ordersRef = FirebaseFirestore.instance.collection('orders');

  Future<void> createOrder(OrderModel order) async {
    await _ordersRef.doc(order.id).set(order.toMap());
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
