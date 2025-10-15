import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'chat_service.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  final String peerName;
  const ChatView({required this.chatId, required this.peerName, Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  static const String ownerUid = 'homemade_bliss_owner';
  static const String ownerDisplayName = 'Admin homemade1';

  Future<String> getMyDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'ลูกค้า';
    if (user.uid == ownerUid) return ownerDisplayName;
    // Always fetch from Firestore users collection
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final firestoreName = doc.data()?['displayName'];
    if (firestoreName != null && firestoreName.toString().trim().isNotEmpty) {
      return firestoreName;
    }
    return user.displayName?.isNotEmpty == true ? user.displayName! : 'ลูกค้า';
  }

  void _pickAndSendImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
      if (picked == null) return;
      final file = File(picked.path);
      final fileSize = await file.length();
      // Warn if file > 5MB
      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไฟล์รูปภาพใหญ่เกิน 5MB กรุณาเลือกไฟล์ที่เล็กกว่านี้')));
        return;
      }
      final fileName = '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('chat_images/$fileName');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final snapshot = await ref.putFile(file);
        final url = await snapshot.ref.getDownloadURL();
        final displayName = await getMyDisplayName();
        await _chatService.sendMessage(
          chatId: widget.chatId,
          senderUid: myUid,
          text: '',
          imageUrl: url,
          ownerUid: ownerUid,
          senderDisplayName: displayName,
        );
      } on FirebaseException catch (e) {
        String msg = 'อัปโหลดรูปไม่สำเร็จ';
        if (e.code == 'canceled') msg = 'ยกเลิกการอัปโหลด';
        else if (e.code == 'quota-exceeded') msg = 'พื้นที่จัดเก็บเต็ม กรุณาติดต่อผู้ดูแลระบบ';
        else if (e.code == 'unauthorized') msg = 'ไม่มีสิทธิ์อัปโหลด กรุณาเข้าสู่ระบบใหม่';
        else if (e.message != null) msg += ': ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดขณะเลือกรูปภาพ')));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }
  final _controller = TextEditingController();
  final _chatService = ChatService();
  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF74512D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFAF8F6F),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(widget.peerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
  backgroundColor: const Color(0xFFF9F8F6), // Minimal off-white
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.chatStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[docs.length - 1 - i].data();
                    final senderUid = data['senderUid'] as String?;
                    final senderName = senderUid == ownerUid
                        ? ownerDisplayName
                        : (data['senderDisplayName'] as String? ?? 'ลูกค้า');
                    final isMe = senderUid == myUid;
                    final text = data['text'] as String?;
                    final imageUrl = data['imageUrl'] as String?;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: isMe ? 32 : 0,
                              right: isMe ? 0 : 32,
                              bottom: 2,
                            ),
                            child: Text(senderName, style: const TextStyle(fontSize: 12, color: Color(0xFF74512D), fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: CircleAvatar(radius: 16, backgroundColor: Color(0xFFAF8F6F), child: Icon(Icons.person, color: Colors.white, size: 18)),
                                ),
                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  padding: imageUrl != null ? const EdgeInsets.all(2) : const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFFD7CCC8) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(imageUrl, width: 180, height: 180, fit: BoxFit.cover),
                                        )
                                      : Text(text ?? '', style: const TextStyle(fontSize: 15)),
                                ),
                              ),
                              if (isMe)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: CircleAvatar(radius: 16, backgroundColor: Color(0xFFAF8F6F), child: Icon(Icons.person, color: Colors.white, size: 18)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF74512D)),
                  onPressed: _pickAndSendImage,
                  tooltip: 'แนบรูปภาพ',
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFAF8F6F), width: 1),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'ส่งข้อความ...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF74512D)),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      final displayName = await getMyDisplayName();
                      await _chatService.sendMessage(
                        chatId: widget.chatId,
                        senderUid: myUid,
                        text: text,
                        imageUrl: '',
                        ownerUid: ownerUid,
                        senderDisplayName: displayName,
                      );
                      _controller.clear();
                    }
                  },
                  tooltip: 'ส่งข้อความ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
