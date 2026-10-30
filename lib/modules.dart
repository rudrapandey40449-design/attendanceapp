import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';

class FeeMod extends StatelessWidget {
  final String aId, org;
  const FeeMod({super.key, required this.aId, required this.org});

  void _showReceipt(BuildContext context, String name, String roll, String m, String date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0D253F), width: 2), borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  gradient: const RadialGradient(colors: [Color(0xFF2A5298), Color(0xFF07192C)]),
                ),
                child: const Center(child: Icon(Icons.workspace_premium, color: Colors.amber, size: 22)),
              ),
              const SizedBox(height: 4),
              Text(org, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Text('राजकीय डिजिटल शुल्क प्राप्ति रसीद', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const Divider(thickness: 1.5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('रसीद सं.:', style: TextStyle(fontSize: 11)), Text('REC-$roll-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('शिक्षार्थी:', style: TextStyle(fontSize: 11)), Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('अनुक्रमांक:', style: TextStyle(fontSize: 11)), Text(roll, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('सत्र / माह:', style: TextStyle(fontSize: 11)), Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('भुगतान समय:', style: TextStyle(fontSize: 11)), Text(date, style: const TextStyle(fontSize: 10))]),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade50,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 6), Text('शुल्क प्राप्त एवं सत्यापित ✔', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))],
                ),
              ),
              const SizedBox(height: 8),
              const Text('संस्थान संपर्क सूत्र: 7393899011', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = DateFormat('MMMM yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text('राजस्व संधारण ($m)'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').doc(aId).collection('students').snapshots(),
        builder: (ctx, s1) {
          if (!s1.hasData) return const Center(child: CircularProgressIndicator());
          final stds = s1.data!.docs;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('admins').doc(aId).collection('fees').where('month', isEqualTo: m).snapshots(),
            builder: (ctx, s2) {
              final feeMap = {for (var d in (s2.data?.docs ?? [])) d['roll'].toString(): d.data() as Map<String, dynamic>};
              return ListView.builder(
                itemCount: stds.length,
                itemBuilder: (c, i) {
                  final r = stds[i]['roll'].toString();
                  final item = feeMap[r];
                  final isP = item != null && item['isPaid'] == true;
                  final pDate = item?['paidOn'] ?? '';
                  final phone = (stds[i].data() as Map<String, dynamic>)['phone'] ?? '';
                  final sName = stds[i]['name'] ?? '';
                  return Card(
                    child: ListTile(
                      title: Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('अनुक्रमांक: $r | स्थिति: ${isP ? "जमा ✔ (Receipt Sent)" : "बकाया ✖"}', style: TextStyle(color: isP ? Colors.green.shade700 : Colors.red, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isP) IconButton(icon: const Icon(Icons.print, color: Color(0xFF0D253F), size: 20), onPressed: () => _showReceipt(context, sName, r, m, pDate)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isP ? Colors.green.shade700 : Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              final dt = DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
                              final newStatus = !isP;
                              FirebaseFirestore.instance.collection('admins').doc(aId).collection('fees').doc('$m-$r').set({
                                'month': m, 'roll': r, 'isPaid': newStatus, 'paidOn': newStatus ? dt : null
                              });
                              if (newStatus && phone.isNotEmpty) {
                                sendGovCloudSMS(context, phone, 'राजकीय कोचिंग ($org): प्रिय अभिभावक, शिक्षार्थी $sName (अनुक्रमांक: $r) का माह $m का मासिक शुल्क प्राप्त हुआ। रसीद सं: REC-$r। संपर्क सूत्र: 7393899011');
                              }
                            },
                            child: Text(isP ? 'Paid ✔' : 'Due ✖', style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TestMod extends StatefulWidget {
  final String aId;
  const TestMod({super.key, required this.aId});
  @override
  State<TestMod> createState() => _TestModState();
}

class _TestModState extends State<TestMod> {
  final _t = TextEditingController(text: 'मासिक मूल्यांकन'), _sub = TextEditingController(text: 'Science'), _tot = TextEditingController(text: '50');
  final Map<String, TextEditingController> _m = {};

  String _calcGrade(double pct) {
    if (pct >= 85) return 'A+';
    if (pct >= 70) return 'A';
    if (pct >= 55) return 'B';
    if (pct >= 33) return 'C';
    return 'F (अनुत्तीर्ण)';
  }

  void _showMarkDialog(BuildContext context, String sName, String roll, String exam, String sub, String obtained, String total, String pct, String grade) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.assessment, color: Color(0xFF0D253F)),
            const SizedBox(width: 8),
            Text('$sName की मार्कशीट', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(dense: true, title: const Text('परीक्षा'), trailing: Text(exam, style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(dense: true, title: const Text('विषय'), trailing: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(dense: true, title: const Text('प्राप्तांक / पूर्णांक'), trailing: Text('$obtained / $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            ListTile(dense: true, title: const Text('प्रतिशत'), trailing: Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
            ListTile(dense: true, title: const Text('ग्रेड एवं परिणाम'), trailing: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: grade.startsWith('F') ? Colors.red : Colors.green.shade700))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('शैक्षणिक मूल्यांकन एवं रिपोर्ट कार्ड'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          for (var d in docs) { _m.putIfAbsent(d['roll'].toString(), () => TextEditingController(text: '0')); }
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _t, decoration: const InputDecoration(labelText: 'परीक्षा नाम', border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
                    const SizedBox(width: 6),
                    Expanded(child: TextField(controller: _sub, decoration: const InputDecoration(labelText: 'विषय', border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
                    const SizedBox(width: 6),
                    SizedBox(width: 75, child: TextField(controller: _tot, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'पूर्णांक', border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final r = docs[i]['roll'].toString();
                    final sName = docs[i]['name'] ?? '';
                    final phone = (docs[i].data() as Map<String, dynamic>)['phone'] ?? '';
                    final marks = double.tryParse(_m[r]?.text.trim() ?? '0') ?? 0;
                    final total = double.tryParse(_tot.text.trim()) ?? 50;
                    final pct = total > 0 ? ((marks / total) * 100).toStringAsFixed(1) : '0';
                    final grade = _calcGrade(double.tryParse(pct) ?? 0);
                    final isPass = (double.tryParse(pct) ?? 0) >= 33;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('$sName (रोल: $r)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('प्रतिशत: $pct% | ग्रेड: $grade (${isPass ? "उत्तीर्ण" : "अनुत्तीर्ण"})', style: TextStyle(color: isPass ? Colors.green.shade700 : Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _m[r],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(labelText: 'प्राप्तांक', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye, color: Color(0xFF0D253F), size: 20),
                                onPressed: () => _showMarkDialog(context, sName, r, _t.text.trim(), _sub.text.trim(), _m[r]?.text.trim() ?? '0', _tot.text.trim(), pct, grade),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('मूल्यांकन सुरक्षित करें एवं अभिभावकों को SMS भेजें'),
                  onPressed: () async {
                    final b = FirebaseFirestore.instance.batch();
                    final curDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
                    final totVal = _tot.text.trim();
                    final subVal = _sub.text.trim();
                    final testVal = _t.text.trim();

                    for (var doc in docs) {
                      final r = doc['roll'].toString();
                      final sName = doc['name'] ?? '';
                      final phone = (doc.data() as Map<String, dynamic>)['phone'] ?? '';
                      final obtained = _m[r]?.text.trim() ?? '0';
                      final marksNum = double.tryParse(obtained) ?? 0;
                      final totNum = double.tryParse(totVal) ?? 50;
                      final pctStr = totNum > 0 ? ((marksNum / totNum) * 100).toStringAsFixed(1) : '0';
                      final gradeStr = _calcGrade(double.tryParse(pctStr) ?? 0);

                      b.set(FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('tests').doc('$testVal-$r'), {
                        'test': testVal, 'sub': subVal, 'tot': totVal, 'marks': obtained, 'pct': pctStr, 'grade': gradeStr, 'roll': r, 'date': curDate,
                      });

                      if (phone.isNotEmpty) {
                        sendGovCloudSMS(context, phone, 'राजकीय कोचिंग: प्रिय अभिभावक, शिक्षार्थी $sName का $testVal ($subVal) का परिणाम: प्राप्तांक $obtained/$totVal ($pctStr%), ग्रेड: $gradeStr।');
                      }
                    }
                    await b.commit();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('मूल्यांकन रिपोर्ट सुरक्षित एवं प्रेषित हो गई! ✔')));
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class SearchMod extends StatefulWidget {
  final String aId, org;
  const SearchMod({super.key, required this.aId, required this.org});
  @override
  State<SearchMod> createState() => _SearchModState();
}

class _SearchModState extends State<SearchMod> {
  final _s = TextEditingController();
  String? _roll;

  void _showIDCard(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 300,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0D253F), width: 2), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFF07192C),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 1.5),
                        gradient: const RadialGradient(colors: [Color(0xFF2A5298), Color(0xFF07192C)]),
                      ),
                      child: const Center(child: Icon(Icons.workspace_premium, color: Colors.amber, size: 16)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.org, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Row(children: [Expanded(child: Container(height: 2.5, color: Colors.orange)), Expanded(child: Container(height: 2.5, color: Colors.white)), Expanded(child: Container(height: 2.5, color: Colors.green))]),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 26, backgroundColor: Color(0xFF0D253F), child: Icon(Icons.person, size: 30, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('अनुक्रमांक: ${d['roll']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12)),
                    const Divider(height: 14),
                    Text('कक्षा: ${d['class']} | पिता: ${d['father']}', style: const TextStyle(fontSize: 10)),
                    Text('दूरभाष: ${d['phone']}', style: const TextStyle(fontSize: 10)),
                    Text('स्थान: ${d['address']}', style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)), child: const Text('अधिकृत शिक्षार्थी पहचान पत्र ✔', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('डिजिटल शिक्षार्थी डोजियर'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'विभागीय अनुक्रमांक दर्ज करें', border: OutlineInputBorder(), isDense: true))),
                IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _roll = _s.text.trim())),
              ],
            ),
            if (_roll != null && _roll!.isNotEmpty)
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').doc(_roll).snapshots(),
                  builder: (ctx, s1) {
                    if (!s1.hasData || !s1.data!.exists) return const Center(child: Text('अभिलेख उपलब्ध नहीं है।'));
                    final d = s1.data!.data() as Map<String, dynamic>;
                    return ListView(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${d['name']} (रोल: ${d['roll']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size(60, 30)),
                                      icon: const Icon(Icons.badge, size: 14),
                                      label: const Text('ID Card', style: TextStyle(fontSize: 10)),
                                      onPressed: () => _showIDCard(context, d),
                                    ),
                                  ],
                                ),
                                const Divider(height: 10),
                                Text('कक्षा: ${d['class']} | पिता: ${d['father']}\nमोबाइल: ${d['phone']} | पता: ${d['address']}', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').where('roll', isEqualTo: _roll).snapshots(),
                          builder: (ctx, att) {
                            final docs = att.data?.docs ?? [];
                            int pres = docs.where((e) => e['status'] == 'Present').length;
                            final tot = docs.length;
                            final pct = tot > 0 ? ((pres / tot) * 100).toStringAsFixed(1) : '0';
                            return Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('कुल उपस्थिति: $tot दिवस | उपस्थित: $pres | निरंतरता: $pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('tests').where('roll', isEqualTo: _roll).snapshots(),
                          builder: (ctx, ts) {
                            final tDocs = ts.data?.docs ?? [];
                            return Column(
                              children: tDocs.map((doc) {
                                final dMap = doc.data() as Map<String, dynamic>;
                                final g = dMap['grade'] ?? '-';
                                final p = dMap['pct'] ?? '-';
                                return Card(
                                  child: ListTile(
                                    title: Text('${doc['test']} - ${doc['sub']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    subtitle: Text('प्रतिशत: $p% | ग्रेड: $g', style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                                    trailing: Text('${doc['marks']} / ${doc['tot']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
