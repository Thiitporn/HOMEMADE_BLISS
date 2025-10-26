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
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.collection('messages').add(msgData);
    final chatUpdate = {
      'lastMessage': imageUrl.isNotEmpty ? '[รูปภาพ]' : text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    };
    if (ownerUid != null) {
      chatUpdate['ownerUid'] = ownerUid;
    }
    if (ownerUid != null && senderUid == ownerUid) {
      chatUpdate['hiddenFor'] = FieldValue.delete();
    } else {
      chatUpdate['hiddenFor'] = FieldValue.arrayRemove([senderUid]);
    }
    chatUpdate['archivedAt'] = FieldValue.delete();
    await chatRef.set(chatUpdate, SetOptions(merge: true));
  }

  Future<void> archiveChat({required String chatId, required String userUid}) async {
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.set(
      {
        'hiddenFor': FieldValue.arrayUnion([userUid]),
        'archivedAt': {userUid: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
  }

  Future<void> hardDeleteChat(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesSnapshot = await chatRef.collection('messages').get();
    final batch = _db.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);
    await batch.commit();
  }
}
