import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> chatStream(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages').orderBy('timestamp').snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderUid': senderUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
