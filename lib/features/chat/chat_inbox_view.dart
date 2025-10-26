import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemade_bliss/util/theme/theme.dart';
import 'chat_view.dart';

class ChatInboxView extends StatelessWidget {
  const ChatInboxView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final owner = FirebaseAuth.instance.currentUser;
  const legacyOwnerUid = 'homemade_bliss_owner';
  final ownerUid = owner?.uid ?? legacyOwnerUid;
  final ownerFilters = {ownerUid, legacyOwnerUid}.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อความลูกค้า', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
  backgroundColor: const Color(0xFFF8F2ED),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: (ownerFilters.length == 1
                ? FirebaseFirestore.instance
                    .collection('chats')
                    .where('ownerUid', isEqualTo: ownerFilters.first)
                : FirebaseFirestore.instance
                    .collection('chats')
                    .where('ownerUid', whereIn: ownerFilters))
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีแชทจากลูกค้า'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final chatId = docs[i].id;
              final lastMsg = data['lastMessage'] ?? '';
              final lastTime = (data['lastTimestamp'] as Timestamp?)?.toDate();
              final customerName = data['customerName'] ?? 'ลูกค้า';
              final profileUrl = data['customerProfileUrl'] as String?;
              final unreadCount = data['unreadCount'] ?? 0;
              return Card(
                elevation: 1.5,
                margin: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final currentOwner = FirebaseAuth.instance.currentUser;
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatView(
                          chatId: chatId,
                          peerName: customerName,
                          isOwner: true,
                          ownerUid: currentOwner?.uid,
                          ownerDisplayName: currentOwner?.displayName,
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (result == 'deleted') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ลบแชทแล้ว')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFAF8F6F),
                          backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                          child: profileUrl == null || profileUrl.isEmpty
                              ? Text(
                                  customerName.isNotEmpty ? customerName[0] : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: kPrimaryColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (lastTime != null)
                              Text(
                                '${lastTime.hour}:${lastTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: kPrimaryColor, fontWeight: FontWeight.w600),
                              ),
                            const SizedBox(height: 6),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: kPrimaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
