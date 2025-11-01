import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/dialog_utils.dart';

class CouponsManagementView extends StatefulWidget {
  const CouponsManagementView({super.key});

  @override
  State<CouponsManagementView> createState() => _CouponsManagementViewState();
}

class _CouponsManagementViewState extends State<CouponsManagementView> {
  Future<void> _showAddCouponSheet(BuildContext context) async {
    final codeCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    final usageLimitCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();
    
    String discountType = 'percentage'; // percentage or fixed
    DateTime? expiryDate;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('เพิ่มคูปองส่วนลด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(labelText: 'รหัสคูปอง'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกรหัสคูปอง' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionCtrl,
                        decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: discountType,
                        decoration: const InputDecoration(labelText: 'ประเภทส่วนลด'),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('เปอร์เซ็นต์ (%)')),
                          DropdownMenuItem(value: 'fixed', child: Text('จำนวนเงิน (บาท)')),
                        ],
                        onChanged: (value) => setState(() => discountType = value!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: discountCtrl,
                        decoration: InputDecoration(
                          labelText: discountType == 'percentage' ? 'ส่วนลด (%)' : 'ส่วนลด (บาท)',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (double.tryParse(v ?? '') == null) ? 'กรุณากรอกจำนวนส่วนลด' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minOrderCtrl,
                        decoration: const InputDecoration(labelText: 'ยอดขั้นต่ำ (บาท)'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usageLimitCtrl,
                        decoration: const InputDecoration(labelText: 'จำนวนครั้งที่ใช้ได้'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('วันหมดอายุ'),
                        subtitle: Text(expiryDate != null 
                          ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                          : 'ไม่มีวันหมดอายุ'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => expiryDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('บันทึกคูปอง'),
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              'บันทึกคูปอง',
                              'คุณต้องการบันทึกคูปองนี้หรือไม่?',
                            );
                            if (!confirmed) return;
                            if (!formKey.currentState!.validate()) return;
                            
                            await FirebaseFirestore.instance.collection('coupons').add({
                              'code': codeCtrl.text.trim().toUpperCase(),
                              'description': descriptionCtrl.text.trim(),
                              'discountType': discountType,
                              'discountValue': double.parse(discountCtrl.text.trim()),
                              'minOrderAmount': double.parse(minOrderCtrl.text.trim()),
                              'usageLimit': int.parse(usageLimitCtrl.text.trim()),
                              'usedCount': 0,
                              'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
                              'isActive': true,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            
                            if (mounted) Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color lightBorder = const Color(0xFFD7CCC8);
    final Color mediumBrown = const Color(0xFF8D6E63);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EF),
        elevation: 0,
        title: Text('จัดการคูปองส่วนลด', style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: darkBrown),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีคูปองส่วนลด\nกดปุ่ม + เพื่อเพิ่มคูปอง'));
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final code = (data['code'] ?? '') as String;
              final description = (data['description'] ?? '') as String;
              final discountType = (data['discountType'] ?? 'percentage') as String;
              final discountValue = (data['discountValue'] ?? 0).toDouble();
              final minOrderAmount = (data['minOrderAmount'] ?? 0).toDouble();
              final usageLimit = (data['usageLimit'] ?? 0) as int;
              final usedCount = (data['usedCount'] ?? 0) as int;
              final isActive = (data['isActive'] ?? true) as bool;
              final expiryTimestamp = data['expiryDate'] as Timestamp?;
              
              String discountText = discountType == 'percentage' 
                  ? '${discountValue.toInt()}%'
                  : '฿${discountValue.toStringAsFixed(0)}';
              
              String expiryText = expiryTimestamp != null
                  ? 'หมดอายุ: ${expiryTimestamp.toDate().day}/${expiryTimestamp.toDate().month}/${expiryTimestamp.toDate().year}'
                  : 'ไม่มีวันหมดอายุ';
              
              bool isExpired = expiryTimestamp != null && expiryTimestamp.toDate().isBefore(DateTime.now());
              bool isExhausted = usedCount >= usageLimit;
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightBorder),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive && !isExpired && !isExhausted ? mediumBrown : Colors.grey,
                    child: const Icon(Icons.discount, color: Colors.white),
                  ),
                  title: Text(code, style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty) Text(description),
                      Text('ส่วนลด: $discountText'),
                      if (minOrderAmount > 0) Text('ยอดขั้นต่ำ: ฿${minOrderAmount.toStringAsFixed(0)}'),
                      Text('ใช้แล้ว: $usedCount/$usageLimit ครั้ง'),
                      Text(expiryText, style: TextStyle(
                        color: isExpired ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                      )),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'toggle') {
                        await FirebaseFirestore.instance
                            .collection('coupons')
                            .doc(doc.id)
                            .update({'isActive': !isActive});
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          'ลบคูปอง',
                          'คุณต้องการลบคูปองนี้จริงหรือไม่?',
                        );
                        if (!confirmed) return;
                        await FirebaseFirestore.instance
                            .collection('coupons')
                            .doc(doc.id)
                            .delete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? 'ปิดใช้งาน' : 'เปิดใช้งาน'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('ลบ'),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mediumBrown,
        foregroundColor: Colors.white,
        onPressed: () => _showAddCouponSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มคูปอง'),
      ),
    );
  }
}