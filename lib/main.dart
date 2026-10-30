import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCyezv6VO44lOP-wDRCNYuOHZ-wFtDycpk',
        appId: '1:152984908526:android:78031fe79787a96224b9ff',
        messagingSenderId: '152984908526',
        projectId: 'attendance-app-9ac46',
      ),
    );
  } catch (_) {}
  runApp(const MaterialApp(home: AdminAuth(), debugShowCheckedModeBanner: false));
}

class AdminAuth extends StatefulWidget {
  const AdminAuth({super.key});
  @override
  State<AdminAuth> createState() => _AdminAuthState();
}

class _AdminAuthState extends State<AdminAuth> {
  final _id = TextEditingController(), _pw = TextEditingController(), _org = TextEditingController();
  bool isReg = false, _load = false;

  Future<void> _sub() async {
    final id = _id.text.trim().toLowerCase(), pw = _pw.text.trim(), org = _org.text.trim();
    if (id.isEmpty || pw.isEmpty) return;
    setState(() => _load = true);
    final ref = FirebaseFirestore.instance.collection('admins').doc(id);
    final doc = await ref.get();
    if (isReg) {
      if (doc.exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आईडी पहले से पंजीकृत है!')));
      } else {
        await ref.set({'id': id, 'pw': pw, 'org': org.isEmpty ? 'राजकीय कोचिंग केंद्र' : org});
        _go(id, org.isEmpty ? 'राजकीय कोचिंग केंद्र' : org);
      }
    } else {
      if (doc.exists && doc.data()?['pw'] == pw) {
        _go(id, doc.data()?['org'] ?? 'राजकीय कोचिंग केंद्र');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('अमान्य विभागीय क्रेडेंशियल!')));
      }
    }
    if (mounted) setState(() => _load = false);
  }

  void _go(String id, String org) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(aId: id, org: org)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            const GovHeader(title: 'विभागीय अधिकृत लॉगिन पोर्टल'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, size: 40, color: Color(0xFF0D253F)),
                          const SizedBox(height: 6),
                          Text(isReg ? 'नवीन अधिकृत केंद्र पंजीकरण' : 'विभागीय अधिकारी लॉगिन', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D253F))),
                          const Divider(height: 20),
                          if (isReg) TextField(controller: _org, decoration: const InputDecoration(labelText: 'संस्था / केंद्र का नाम', border: OutlineInputBorder(), isDense: true)),
                          if (isReg) const SizedBox(height: 10),
                          TextField(controller: _id, decoration: const InputDecoration(labelText: 'विभागीय यूज़रनेम (ID)', border: OutlineInputBorder(), isDense: true)),
                          const SizedBox(height: 10),
                          TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'सुरक्षा पासवर्ड', border: OutlineInputBorder(), isDense: true)),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42)),
                            onPressed: _load ? null : _sub,
                            child: _load ? const CircularProgressIndicator(color: Colors.white) : Text(isReg ? 'पंजीकरण सुरक्षित करें' : 'सत्यापित करें एवं प्रवेश लें'),
                          ),
                          TextButton(onPressed: () => setState(() => isReg = !isReg), child: Text(isReg ? 'पोर्टल पर लॉगिन करें' : 'नवीन केंद्र का पंजीकरण करें')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final String aId, org;
  const Dashboard({super.key, required this.aId, required this.org});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(org, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D253F),
        actions: [IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminAuth())))],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 3, color: Colors.orange)),
              Expanded(child: Container(height: 3, color: Colors.white)),
              Expanded(child: Container(height: 3, color: Colors.green)),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF0D253F), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('अधिकृत कोड: $aId', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('दिनांक: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _tile(context, 'दैनिक बायोमेट्रिक उपस्थिति (UIDAI Face & SMS)', Icons.face, Colors.teal, AttMod(aId: aId, org: org)),
                _tile(context, 'राजस्व एवं शुल्क संधारण (Fee Receipt & SMS)', Icons.receipt_long, Colors.green.shade700, FeeMod(aId: aId, org: org)),
                _tile(context, 'शैक्षणिक मूल्यांकन एवं प्राप्तांक (Test Ledger)', Icons.assignment_turned_in, Colors.indigo, TestMod(aId: aId)),
                _tile(context, 'नवीन शिक्षार्थी नामांकन (Student Enrolment)', Icons.person_add_alt_1, Colors.blue.shade800, AddStdMod(aId: aId)),
                _tile(context, 'डिजिटल शिक्षार्थी रिकॉर्ड एवं पहचान पत्र (Dossier & ID)', Icons.badge, Colors.deepOrange, SearchMod(aId: aId, org: org)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext c, String t, IconData i, Color cl, Widget p) => Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: cl.withOpacity(0.15), child: Icon(i, color: cl, size: 22)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D253F))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
    ),
  );
}

class AddStdMod extends StatefulWidget {
  final String aId;
  const AddStdMod({super.key, required this.aId});
  @override
  State<AddStdMod> createState() => _AddStdModState();
}

class _AddStdModState extends State<AddStdMod> {
  final _n = TextEditingController(), _r = TextEditingController(), _p = TextEditingController(), _f = TextEditingController(), _c = TextEditingController(), _a = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('शिक्षार्थी नामांकन पंजिका'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _n, decoration: const InputDecoration(labelText: 'शिक्षार्थी का पूरा नाम *', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _r, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'विभागीय अनुक्रमांक (Roll No) *', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'अभिभावक का दूरभाष (मोबाइल) *', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _f, decoration: const InputDecoration(labelText: 'पिता / संरक्षक का नाम', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _c, decoration: const InputDecoration(labelText: 'प्रवेशित कक्षा / संवर्ग (उदा. 11th Science)', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _a, decoration: const InputDecoration(labelText: 'स्थाई पता', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42)),
            onPressed: () async {
              if (_n.text.isNotEmpty && _r.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').doc(_r.text.trim()).set({
                  'name': _n.text.trim(), 'roll': _r.text.trim(), 'phone': _p.text.trim(), 'father': _f.text.trim(), 'class': _c.text.trim().isEmpty ? '11th' : _c.text.trim(), 'address': _a.text.trim(), 'regDate': DateFormat('dd-MM-yyyy').format(DateTime.now()),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('अभिलेख राष्ट्रीय डेटाबेस में सुरक्षित करें'),
          )
        ],
      ),
    );
  }
}

class AttMod extends StatefulWidget {
  final String aId, org;
  const AttMod({super.key, required this.aId, required this.org});
  @override
  State<AttMod> createState() => _AttModState();
}

class _AttModState extends State<AttMod> {
  DateTime _dt = DateTime.now();
  final Map<String, bool> _st = {}, _face = {};
  String get _dKey => DateFormat('yyyy-MM-dd').format(_dt);

  Future<void> _scanUIDAI(String roll, String name) async {
    final bool? verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FaceScanDialog(stdName: name),
    );
    if (verified == true) {
      setState(() { _face[roll] = true; _st[roll] = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('बायोमेट्रिक उपस्थिति सत्यापन'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Text('अभिलेख तिथि: $_dKey', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    final p = await showDatePicker(context: context, initialDate: _dt, firstDate: DateTime(2025), lastDate: DateTime.now());
                    if (p != null) setState(() => _dt = p);
                  },
                  child: const Text('तिथि बदलें'),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').snapshots(),
              builder: (ctx, s1) {
                if (!s1.hasData) return const Center(child: CircularProgressIndicator());
                final stds = s1.data!.docs;
                if (stds.isEmpty) return const Center(child: Text('कोई शिक्षार्थी पंजीकृत नहीं है।'));
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').where('date', isEqualTo: _dKey).snapshots(),
                  builder: (ctx, s2) {
                    if (s2.hasData) {
                      for (
                        
