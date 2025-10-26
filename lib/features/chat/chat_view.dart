import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_service.dart';
import '../../common/dialog_utils.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  final String peerName;
  final bool isOwner;
  final String? ownerUid;
  final String? ownerDisplayName;

  const ChatView({
    required this.chatId,
    required this.peerName,
    this.isOwner = false,
    this.ownerUid,
    this.ownerDisplayName,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  static const String _legacyOwnerUid = 'homemade_bliss_owner';
  final _controller = TextEditingController();
  final _chatService = ChatService();
  String myUid = '';
  bool _isOwner = false;
  String? _ownerUid;
  String? _ownerDisplayName;
  bool _contextReady = false;

  Future<String> getMyDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'ลูกค้า';
    if (_isOwner) return _ownerDisplayName ?? 'ร้านค้า';
    // Always fetch from Firestore users collection
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final firestoreName = doc.data()?['displayName'];
    if (firestoreName != null && firestoreName.toString().trim().isNotEmpty) {
      return firestoreName;
    }
    return user.displayName?.isNotEmpty == true ? user.displayName! : 'ลูกค้า';
  }

  @override
  void initState() {
    super.initState();
    myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _isOwner = widget.isOwner;
    _ownerUid = widget.ownerUid;
    _ownerDisplayName = widget.ownerDisplayName;
    _initializeContext();
  }

  Future<void> _initializeContext() async {
    final user = FirebaseAuth.instance.currentUser;
    String? ownerUid = _ownerUid;
    String? ownerDisplayName = _ownerDisplayName;
    bool isOwner = _isOwner;

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final chatData = chatDoc.data();
    if (chatData != null) {
      ownerUid ??= (chatData['ownerUid'] as String?)?.trim();
      ownerDisplayName ??= chatData['ownerDisplayName'] as String?;
    }

    if (user != null) {
      myUid = user.uid;
      if (!isOwner) {
        if (ownerUid != null && ownerUid == user.uid) {
          isOwner = true;
        } else {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
          if (role == 'owner') {
            isOwner = true;
          }
          ownerDisplayName ??= userDoc.data()?['displayName'] as String?;
        }
      } else {
        ownerDisplayName ??= user.displayName;
      }
    }

    ownerDisplayName ??= 'ร้านค้า';

    if ((ownerUid == null || ownerUid.isEmpty) && isOwner && myUid.isNotEmpty) {
      ownerUid = myUid;
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
        {
          'ownerUid': ownerUid,
          'ownerDisplayName': ownerDisplayName,
        },
        SetOptions(merge: true),
      );
    }

    if (!mounted) return;
    setState(() {
      _ownerUid = ownerUid;
      _ownerDisplayName = ownerDisplayName;
      _isOwner = isOwner;
      _contextReady = true;
    });
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
                    ownerUid: _resolveOwnerUidForUpdate(),
                    senderDisplayName: displayName,
                  );
                  if (_isOwner && _ownerUid != myUid && myUid.isNotEmpty && mounted) {
                    setState(() => _ownerUid = myUid);
                  }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: _isOwner ? 'ลบแชทถาวร' : 'ซ่อนบทสนทนา',
            onPressed: _contextReady ? _handleDeleteChat : null,
          ),
        ],
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
          final isOwnerSender = senderUid != null && senderUid == (_ownerUid ?? _legacyOwnerUid);
          final senderName = isOwnerSender
            ? (_ownerDisplayName ?? 'ร้านค้า')
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
                        ownerUid: _resolveOwnerUidForUpdate(),
                        senderDisplayName: displayName,
                      );
                      if (_isOwner && _ownerUid != myUid && myUid.isNotEmpty && mounted) {
                        setState(() => _ownerUid = myUid);
                      }
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

  String _resolveOwnerUidForUpdate() {
    if (_ownerUid != null && _ownerUid!.isNotEmpty) {
      return _ownerUid!;
    }
    if (_isOwner && myUid.isNotEmpty) {
      return myUid;
    }
    return _legacyOwnerUid;
  }

  Future<void> _handleDeleteChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_isOwner && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนลบแชท')),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      _isOwner ? 'ลบแชท' : 'ซ่อนบทสนทนา',
      _isOwner
          ? 'การลบนี้จะลบข้อความทั้งหมดถาวร ต้องการดำเนินการต่อหรือไม่?'
          : 'แชทนี้จะถูกซ่อนจากรายการของคุณ และจะแสดงอีกครั้งเมื่อร้านค้าตอบใหม่ ต้องการดำเนินการหรือไม่?',
    );
    if (!confirmed || !mounted) return;

    try {
      if (_isOwner) {
        await _chatService.hardDeleteChat(widget.chatId);
        if (!mounted) return;
        Navigator.of(context).pop('deleted');
      } else {
        final uid = user!.uid;
        await _chatService.archiveChat(chatId: widget.chatId, userUid: uid);
        if (!mounted) return;
        Navigator.of(context).pop('archived');
      }
    } catch (e) {
      if (!mounted) return;
      final message = _isOwner ? 'ไม่สามารถลบแชทได้: $e' : 'ไม่สามารถซ่อนแชทได้: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
