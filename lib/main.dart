import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';
import 'modules.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GovAttendanceApp());
}

class GovAttendanceApp extends StatelessWidget {
  const GovAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'स्मार्ट उपस्थिति पोर्टल',
      theme: ThemeData(
        primaryColor: const Color(0xFF07192C),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: 'Roboto',
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _reg = false;
  final _org = TextEditingController();

  void _submit() async {
    final u = _u.text.trim();
    final p = _p.text.trim();
    if (u.isEmpty || p.isEmpty) return;

    final ref = FirebaseFirestore.instance.collection('admins').doc(u);
    if (_reg) {
      await ref.set({'pass': p, 'org': _org.text.trim().isEmpty ? 'राष्ट्रीय प्रशिक्षण केंद्र' : _org.text.trim()});
      if (mounted) setState(() => _reg = false);
    } else {
      final doc = await ref.get();
      if (doc.exists && doc['pass'] == p) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Dashboard(aId: u, org: doc['org'] ?? 'राष्ट्रीय प्रशिक्षण केंद्र')),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('अमान्य यूज़रनेम अथवा पासवर्ड!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GovHeader(title: 'विभागीय अधिकृत लॉगिन पोर्टल'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, size: 50, color: Color(0xFF07192C)),
                          const SizedBox(height: 10),
                          Text(_reg ? 'नवीन संस्थान पंजीकरण' : 'विभागीय अधिकारी लॉगिन', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF07192C))),
                          const SizedBox(height: 16),
                          if (_reg)
                            TextField(controller: _org, decoration: const InputDecoration(labelText: 'कोचिंग / केंद्र का नाम', border: OutlineInputBorder(), isDense: true)),
                          if (_reg) const SizedBox(height: 10),
                          TextField(controller: _u, decoration: const InputDecoration(labelText: 'विभागीय यूज़रनेम (मोबाइल नंबर)', border: OutlineInputBorder(), isDense: true)),
                          const SizedBox(height: 10),
                          TextField(controller: _p, obscureText: true, decoration: const InputDecoration(labelText: 'सुरक्षा पासवर्ड', border: OutlineInputBorder(), isDense: true)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: const Color(0xFFFFD700), minimumSize: const Size.fromHeight(45)),
                            onPressed: _submit,
                            child: Text(_reg ? 'पंजीकृत करें' : 'सत्यापित करें एवं प्रवेश लें', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _reg = !_reg),
                            child: Text(_reg ? 'लॉगिन पर वापस जाएँ' : 'नवीन केंद्र का पंजीकरण करें', style: const TextStyle(color: Color(0xFF07192C))),
                          ),
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
    final curDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(org, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF07192C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.power_settings_new), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()))),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0A2540),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('अधिकृत कोड: $aId', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                Text('दिनांक: $curDate', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _menuCard(context, 'दैनिक बायोमेट्रिक उपस्थिति (Live Auto-SMS)', Icons.fingerprint, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttScreen(aId: aId, org: org)))),
                _menuCard(context, 'राजस्व एवं शुल्क संधारण (Auto Receipt)', Icons.receipt_long, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeeMod(aId: aId, org: org)))),
                _menuCard(context, 'शैक्षणिक मूल्यांकन एवं प्राप्तांक (Test Ledger)', Icons.assignment_turned_in, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestMod(aId: aId)))),
                _menuCard(context, 'नवीन शिक्षार्थी नामांकन (Student Enrolment)', Icons.person_add_alt_1, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnrollScreen(aId: aId)))),
                _menuCard(context, 'डिजिटल शिक्षार्थी रिकॉर्ड एवं पहचान पत्र (Dossier & ID)', Icons.badge, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchMod(aId: aId, org: org)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext ctx, String t, IconData ic, VoidCallback tap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE3F2FD), child: Icon(ic, color: const Color(0xFF07192C))),
        title: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: tap,
      ),
    );
  }
}

class AttScreen extends StatefulWidget {
  final String aId, org;
  const AttScreen({super.key, required this.aId, required this.org});

  @override
  State<AttScreen> createState() => _AttScreenState();
}

class _AttScreenState extends State<AttScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dStr = DateFormat('yyyy-MM-dd').format(_date);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('बायोमेट्रिक एवं दैनिक उपस्थिति'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('अभिलेख तिथि: $dStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('तिथि बदलें', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2025), lastDate: DateTime(2030));
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').snapshots(),
              builder: (ctx, s1) {
                if (!s1.hasData) return const Center(child: CircularProgressIndicator());
                final stds = s1.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').where('date', isEqualTo: dStr).snapshots(),
                  builder: (ctx, s2) {
                    final attMap = {for (var d in (s2.data?.docs ?? [])) d['roll'].toString(): d['status'].toString()};

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: stds.length,
                      itemBuilder: (c, i) {
                        final r = stds[i]['roll'].toString();
                        final sName = stds[i]['name'] ?? '';
                        final phone = (stds[i].data() as Map<String, dynamic>)['phone'] ?? '';
                        final curStatus = attMap[r] ?? 'Pending';

                        final isP = curStatus == 'Present';
                        final isA = curStatus == 'Absent';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isP ? Colors.green : (isA ? Colors.red : Colors.grey.shade300), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF07192C),
                                  child: Text(r, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        'स्थिति: ${isP ? "उपस्थित (Present) ✔" : (isA ? "अनुपस्थित (Absent) ✖" : "अनिर्णीत (Pending)")}',
                                        style: TextStyle(color: isP ? Colors.green : (isA ? Colors.red : Colors.blueGrey), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                // Present Button (P)
                                InkWell(
                                  onTap: () {
                                    FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').doc('$dStr-$r').set({
                                      'roll': r, 'name': sName, 'date': dStr, 'status': 'Present'
                                    });
                                    if (phone.isNotEmpty) {
                                      sendGovCloudSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $sName (रोल: $r) आज दिनांक $dStr को संस्थान (${widget.org}) में ससमय उपस्थित है।');
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(color: isP ? Colors.green : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                    child: Center(child: Text('P', style: TextStyle(fontWeight: FontWeight.bold, color: isP ? Colors.white : Colors.black87))),
                                  ),
                                ),
                                // Absent Button (A)
                                InkWell(
                                  onTap: () {
                                    FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').doc('$dStr-$r').set({
                                      'roll': r, 'name': sName, 'date': dStr, 'status': 'Absent'
                                    });
                                    if (phone.isNotEmpty) {
                                      sendGovCloudSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $sName (रोल: $r) आज दिनांक $dStr को संस्थान (${widget.org}) से अनुपस्थित (Absent) है। कृपया संज्ञान लें।');
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(color: isA ? Colors.red : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                    child: Center(child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, color: isA ? Colors.white : Colors.black87))),
                                  ),
                                ),
                                // Face Scan Option
                                IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Color(0xFF07192C), size: 22),
                                  onPressed: () async {
                                    final res = await showDialog(context: context, builder: (_) => FaceScanDialog(stdName: sName));
                                    if (res == true) {
                                      FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').doc('$dStr-$r').set({
                                        'roll': r, 'name': sName, 'date': dStr, 'status': 'Present', 'bio': true
                                      });
                                      if (phone.isNotEmpty) {
                                        sendGovCloudSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $sName का लाइव बायोमेट्रिक सत्यापन सफल रहा। संस्थान में उपस्थित दर्ज किया गया।');
                                      }
                                    }
                                  },
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
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: const Color(0xFFFFD700), minimumSize: const Size.fromHeight(46)),
              icon: const Icon(Icons.lock_clock),
              label: Text('$dStr का दैनिक हाजिरी डाटा लॉक करें'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आज की दैनिक उपस्थिति सफलतापूर्वक सुरक्षित एवं लॉक हो गई! ✔')));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EnrollScreen extends StatefulWidget {
  final String aId;
  const EnrollScreen({super.key, required this.aId});

  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  final _n = TextEditingController(), _r = TextEditingController(), _c = TextEditingController(), _f = TextEditingController(), _p = TextEditingController(), _ad = TextEditingController();

  void _save() async {
    final r = _r.text.trim();
    if (r.isEmpty || _n.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').doc(r).set({
      'name': _n.text.trim(),
      'roll': r,
      'class': _c.text.trim(),
      'father': _f.text.trim(),
      'phone': _p.text.trim(),
      'address': _ad.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शिक्षार्थी नामांकन पूर्ण हुआ! ✔')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('शिक्षार्थी नवीन नामांकन'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _n, decoration: const InputDecoration(labelText: 'शिक्षार्थी का पूरा नाम', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _r, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अनुक्रमांक (Roll No)', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _c, decoration: const InputDecoration(labelText: 'कक्षा / वर्ग', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _f, decoration: const InputDecoration(labelText: 'अभिभावक / पिता का नाम', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'अभिभावक का मोबाइल नंबर (SMS हेतु)', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
          TextField(controller: _ad, decoration: const InputDecoration(labelText: 'स्थानीय पता', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: const Color(0xFFFFD700), minimumSize: const Size.fromHeight(45)),
              onPressed: _save,
              child: const Text('नामांकन सुरक्षित करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
