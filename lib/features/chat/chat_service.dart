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
    String imageUrl = '',
    String? ownerUid,
    String? senderDisplayName,
  }) async {
    final msgData = {
      'senderUid': senderUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'imageUrl': imageUrl,
      if (senderDisplayName != null) 'senderDisplayName': senderDisplayName,
    };
    await _db.collection('chats').doc(chatId).collection('messages').add(msgData);
    final chatUpdate = {
      'lastMessage': imageUrl.isNotEmpty ? '[รูปภาพ]' : text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    };
    if (ownerUid != null) {
      chatUpdate['ownerUid'] = ownerUid;
    }
    await _db.collection('chats').doc(chatId).set(chatUpdate, SetOptions(merge: true));
  }
}
