import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _showImageUrlDialog() async {
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('วางลิงก์รูปภาพ'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'https://...'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'กรุณาวางลิงก์รูป';
                final url = value.trim();
                final isImage = (url.startsWith('http://') || url.startsWith('https://')) && (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png'));
                if (!isImage) return 'ลิงก์ต้องเป็นไฟล์รูป .jpg .jpeg .png';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final url = urlController.text.trim();
                  final displayName = await getMyDisplayName();
                  await _chatService.sendMessage(
                    chatId: widget.chatId,
                    senderUid: myUid,
                    text: url,
                    imageUrl: '',
                    ownerUid: ownerUid,
                    senderDisplayName: displayName,
                  );
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('ส่ง'),
            ),
          ],
        );
      },
    );
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
                    final text = data['text'] as String? ?? '';
                    // final imageUrl = data['imageUrl'] as String?;
                    final isImageLink = (text.startsWith('http://') || text.startsWith('https://')) && (text.endsWith('.jpg') || text.endsWith('.jpeg') || text.endsWith('.png'));
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
                            child: Text(
                              senderName,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF74512D), fontWeight: FontWeight.w600),
                            ),
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
                                  margin: const EdgeInsets.symmetric(vertical: 2.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // ปรับ padding กลางๆ
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFFD7CCC8) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(isMe ? 18 : 8),
                                      bottomRight: Radius.circular(isMe ? 8 : 18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: isImageLink
                                      ? GestureDetector(
                                          onTap: () async {
                                            await launchUrl(Uri.parse(text));
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(13),
                                            child: Image.network(
                                              text,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Text('ดูรูปไม่ได้', style: TextStyle(color: Colors.red, fontSize: 13)),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const SizedBox(
                                                  height: 95,
                                                  width: 95,
                                                  child: Center(child: CircularProgressIndicator()),
                                                );
                                              },
                                              height: 95,
                                              width: 95,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          text,
                                          style: const TextStyle(fontSize: 14, height: 1.22, color: Color(0xFF3E2723)),
                                          textAlign: TextAlign.left,
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
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
                  onPressed: _showImageUrlDialog,
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
