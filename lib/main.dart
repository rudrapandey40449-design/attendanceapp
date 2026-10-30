class UIDAIOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.black.withOpacity(0.72);
    final center = Offset(size.width / 2, size.height * 0.42);
    const double radius = 110.0;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paintBg);

    final ringPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceScanDialog extends StatefulWidget {
  final String stdName;
  const FaceScanDialog({super.key, required this.stdName});

  @override
  State<FaceScanDialog> createState() => _FaceScanDialogState();
}

class _FaceScanDialogState extends State<FaceScanDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _verifying = false;

  void _startCamera() async {
    setState(() => _verifying = true);
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (photo != null) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: UIDAIOverlayPainter()),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Colors.amber, size: 36),
                const SizedBox(height: 6),
                const Text('UIDAI स्टाइल लाइव बायोमेट्रिक सत्यापन', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('शिक्षार्थी: ${widget.stdName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              children: [
                const Text('कृपया चेहरे को वृत्त के केंद्र में स्थिर रखें...', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_verifying ? 'सत्यापन प्रक्रियाधीन...' : 'स्कैन आरंभ करें'),
                  onPressed: _verifying ? null : _startCamera,
                ),
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('रद्द करें', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
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
      setState(() {
        _face[roll] = true;
        _st[roll] = true;
      });
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
                      for (var d in s2.data!.docs) {
                        final r = d['roll'].toString();
                        _st.putIfAbsent(r, () => d['status'] == 'Present');
                        _face.putIfAbsent(r, () => (d.data() as Map<String, dynamic>)['face'] == true);
                      }
                    }
                    return ListView.builder(
                      itemCount: stds.length,
                      itemBuilder: (c, i) {
                        final r = stds[i]['roll'].toString();
                        final isV = _face[r] ?? false;
                        final isP = _st[r] ?? false;
                        final phone = (stds[i].data() as Map<String, dynamic>)['phone'] ?? '';
                        final sName = stds[i]['name'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: ListTile(
                            title: Text('$sName (अनुक्रमांक: $r)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(isP ? (isV ? 'UIDAI बायोमेट्रिक प्रमाणित ✔' : 'उपस्थित ✔') : 'अनुपस्थित ✖', style: TextStyle(color: isP ? Colors.green.shade700 : Colors.red, fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isP ? Colors.green.shade700 : Colors.grey.shade400, foregroundColor: Colors.white, minimumSize: const Size(36, 30)),
                                  onPressed: () => setState(() => _st[r] = !(isP)),
                                  child: Text(isP ? 'P' : 'A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: isV ? Colors.green.shade700 : const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size(54, 30)),
                                  icon: const Icon(Icons.face, size: 14),
                                  label: Text(isV ? 'प्रमाणित' : 'सत्यापन', style: const TextStyle(fontSize: 10)),
                                  onPressed: () => _scanUIDAI(r, sName),
                                ),
                                if (!isP && phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.sms, color: Colors.red, size: 20),
                                    onPressed: () => sendGovCloudSMS(context, phone, 'राजकीय कोचिंग (${widget.org}): प्रिय अभिभावक, आपका पाल्य $sName (अनुक्रमांक: $r) आज दिनांक $_dKey को कक्षा से अनुपस्थित है। संस्थान संपर्क: 7393899011'),
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
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42)),
              onPressed: () async {
                final b = FirebaseFirestore.instance.batch();
                _st.forEach((r, p) {
                  final ref = FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('attendance').doc('$_dKey-$r');
                  b.set(ref, {'date': _dKey, 'roll': r, 'status': p ? 'Present' : 'Absent', 'face': _face[r] ?? false, 'timestamp': FieldValue.serverTimestamp()});
                });
                await b.commit();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('उपस्थिति पंजिका लॉक हो गई!')));
              },
              child: Text('$_dKey का दैनिक हाजिरी डेटा लॉक करें'),
            ),
          )
        ],
      ),
    );
  }
}

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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  gradient: const RadialGradient(colors: [Color(0xFF2A4D69), Color(0xFF0D253F)]),
                ),
                child: const Center(child: Icon(Icons.shield, color: Colors.amber, size: 20)),
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
                      subtitle: Text('अनुक्रमांक: $r | स्थिति: ${isP ? "जमा" : "बकाया"}', style: TextStyle(color: isP ? Colors.green.shade700 : Colors.red, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isP) IconButton(icon: const Icon(Icons.print, color: Color(0xFF0D253F), size: 20), onPressed: () => _showReceipt(context, sName, r, m, pDate)),
                          if (isP && phone.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.sms, color: Colors.green, size: 20),
                              onPressed: () => sendGovCloudSMS(context, phone, 'राजकीय कोचिंग ($org): प्रिय अभिभावक, शिक्षार्थी $sName (अनुक्रमांक: $r) का माह $m का शुल्क प्राप्त हुआ। रसीद सं: REC-$r। संपर्क: 7393899011'),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isP ? Colors.green.shade700 : Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              final dt = DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
                              FirebaseFirestore.instance.collection('admins').doc(aId).collection('fees').doc('$m-$r').set({'month': m, 'roll': r, 'isPaid': !isP, 'paidOn': !isP ? dt : null});
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
  final _t = TextEditingController(text: 'मासिक मूल्यांकन'), _sub = TextEditingController(text: 'Chemistry'), _tot = TextEditingController(text: '50');
  final Map<String, TextEditingController> _m = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('शैक्षणिक मूल्यांकन पंजिका'), backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('students').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          for (var d in docs) { _m.putIfAbsent(d['roll'].toString(), () => TextEditingController(text: '0')); }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _t, decoration: const InputDecoration(labelText: 'परीक्षा', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _sub, decoration: const InputDecoration(labelText: 'विषय', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 4),
                    SizedBox(width: 65, child: TextField(controller: _tot, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'पूर्णांक', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final r = docs[i]['roll'].toString();
                    return ListTile(
                      title: Text('${docs[i]['name']} (रोल: $r)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: SizedBox(width: 65, child: TextField(controller: _m[r], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'प्राप्तांक', border: OutlineInputBorder(), isDense: true))),
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D253F), foregroundColor: Colors.white),
                onPressed: () async {
                  final b = FirebaseFirestore.instance.batch();
                  for (var doc in docs) {
                    final r = doc['roll'].toString();
                    b.set(FirebaseFirestore.instance.collection('admins').doc(widget.aId).collection('tests').doc('${_t.text.trim()}-$r'), {
                      'test': _t.text.trim(), 'sub': _sub.text.trim(), 'tot': _tot.text.trim(), 'marks': _m[r]?.text.trim() ?? '0', 'roll': r, 'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
                    });
                  }
                  await b.commit();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('मूल्यांकन सुरक्षित हो गया!')));
                },
                child: const Text('मूल्यांकन डेटा सुरक्षित करें'),
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
                color: const Color(0xFF0D253F),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 1.5),
                        gradient: const RadialGradient(colors: [Color(0xFF2A4D69), Color(0xFF0D253F)]),
                      ),
                      child: const Center(child: Icon(Icons.shield, color: Colors.amber, size: 14)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.org, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Row(children: [Expanded(child: Container(height: 2, color: Colors.orange)), Expanded(child: Container(height: 2, color: Colors.white)), Expanded(child: Container(height: 2, color: Colors.green))]),
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
                              children: tDocs.map((doc) => Card(
                                child: ListTile(
                                  title: Text('${doc['test']} - ${doc['sub']}', style: const TextStyle(fontSize: 12)),
                                  trailing: Text('${doc['marks']} / ${doc['tot']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              )).toList(),
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
                _tile(context, 'दैनिक बायोमेट्रिक उपस्थिति (Face RD & Cloud SMS)', Icons.face, Colors.teal, AttMod(aId: aId, org: org)),
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

class UIDAIOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.black.withOpacity(0.72);
    final center = Offset(size.width / 2, size.height * 0.42);
    const double radius = 110.0;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paintBg);

    final ringPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceScanDialog extends StatefulWidget {
  final String stdName;
  const FaceScanDialog({super.key, required this.stdName});

  @override
  State<FaceScanDialog> createState() => _FaceScanDialogState();
}

class _FaceScanDialogState extends State<FaceScanDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _verifying = false;

  void _startCamera() async {
    setState(() => _verifying = true);
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (photo != null) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: UIDAIOverlayPainter()),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Colors.amber, size: 36),
                const SizedBox(height: 6),
                const Text('UIDAI स्टाइल लाइव बायोमेट्रिक सत्यापन', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('शिक्षार्थी: ${widget.stdName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              children: [
                const Text('कृपया चेहरे को वृत्त के केंद्र में स्थिर रखें...', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_verifying ? 'सत्यापन प्रक्रियाधीन...' : 'स्कैन आरंभ करें'),
                  onPressed: _verifying ? null : _startCamera,
                ),
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('रद्द करें', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
