import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets.dart';

class FeeMod extends StatefulWidget {
  final String aId, org;
  const FeeMod({super.key, required this.aId, required this.org});

  @override
  State<FeeMod> createState() => _FeeModState();
}

class _FeeModState extends State<FeeMod> {
  List> _stds = [];
  Map<String, dynamic> _feeMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list_${widget.aId}') ?? [];
    _stds = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final m = DateFormat('MMMM yyyy').format(DateTime.now());
    final rawFees = pref.getString('fees_${widget.aId}_$m');
    if (rawFees != null) {
      _feeMap = jsonDecode(rawFees) as Map<String, dynamic>;
    } else {
      _feeMap = {};
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleFee(String roll, String name, String phone) async {
    final m = DateFormat('MMMM yyyy').format(DateTime.now());
    final dt = DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
    final currentStatus = _feeMap[roll]?['isPaid'] == true;
    final newStatus = !currentStatus;

    setState(() {
      _feeMap[roll] = {
        'isPaid': newStatus,
        'paidOn': newStatus ? dt : null,
      };
    });

    final pref = await SharedPreferences.getInstance();
    await pref.setString('fees_${widget.aId}_$m', jsonEncode(_feeMap));

    if (newStatus && phone.isNotEmpty) {
      sendGovCloudSMS(context, phone, 'राजकीय कोचिंग (${widget.org}): प्रिय अभिभावक, शिक्षार्थी $name (अनुक्रमांक: $roll) का माह $m का मासिक शुल्क प्राप्त हुआ। रसीद सं: REC-$roll।');
    }
  }

  void _showReceipt(BuildContext context, String name, String roll, String m, String date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                ),
                child: const Icon(Icons.workspace_premium, color: Color(0xFF07192C), size: 28),
              ),
              const SizedBox(height: 8),
              Text(widget.org, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF07192C))),
              const Text('राजकीय डिजिटल शुल्क प्राप्ति प्रमाण', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
              const Divider(thickness: 1.2, height: 20),
              _row('रसीद क्रमांक:', 'REC-$roll-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
              _row('शिक्षार्थी:', name),
              _row('अनुक्रमांक:', roll),
              _row('माह / सत्र:', m),
              _row('भुगतान समय:', date),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('शुल्क भुगतान अधिकृत एवं सत्यापित ✔', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें', style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  static Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF07192C))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = DateFormat('MMMM yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: Text('राजस्व एवं शुल्क ($m)'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stds.isEmpty
              ? const Center(child: Text('कोई शिक्षार्थी उपलब्ध नहीं है।'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _stds.length,
                  itemBuilder: (c, i) {
                    final r = _stds[i]['roll'].toString();
                    final sName = _stds[i]['name'] ?? '';
                    final phone = _stds[i]['phone'] ?? '';
                    final item = _feeMap[r];
                    final isP = item != null && item['isPaid'] == true;
                    final pDate = item?['paidOn'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isP ? Colors.green.shade100 : Colors.red.shade100,
                          child: Text(r, style: TextStyle(fontWeight: FontWeight.bold, color: isP ? Colors.green.shade900 : Colors.red.shade900)),
                        ),
                        title: Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(isP ? 'स्थिति: जमा ✔' : 'स्थिति: बकाया ✖', style: TextStyle(color: isP ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isP) IconButton(icon: const Icon(Icons.receipt_long, color: Color(0xFF07192C)), onPressed: () => _showReceipt(context, sName, r, m, pDate)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isP ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () => _toggleFee(r, sName, phone),
                              child: Text(isP ? 'Paid ✔' : 'Due ✖', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
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
  List> _stds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list_${widget.aId}') ?? [];
    _stds = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    for (var d in _stds) {
      final r = d['roll'].toString();
      _m[r] = TextEditingController(text: '0');
    }
    setState(() => _loading = false);
  }

  String _calcGrade(double pct) {
    if (pct >= 85) return 'A+';
    if (pct >= 70) return 'A';
    if (pct >= 55) return 'B';
    if (pct >= 33) return 'C';
    return 'F';
  }

  void _showMarkDialog(BuildContext context, String sName, String roll, String exam, String sub, String obtained, String total, String pct, String grade) {
    final bool isPass = (double.tryParse(pct) ?? 0) >= 33;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 310,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, color: Color(0xFF07192C), size: 36),
              const SizedBox(height: 6),
              const Text('राजकीय डिजिटल मूल्यांकन पत्र', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF07192C))),
              const Divider(thickness: 1.2),
              FeeMod._row('शिक्षार्थी:', '$sName (रोल: $roll)'),
              FeeMod._row('परीक्षा / विषय:', '$exam ($sub)'),
              FeeMod._row('प्राप्तांक / पूर्णांक:', '$obtained / $total'),
              FeeMod._row('प्रतिशत:', '$pct%'),
              FeeMod._row('परिणाम:', isPass ? 'उत्तीर्ण ($grade) ✔' : 'अनुत्तीर्ण ($grade) ✖'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))],
      ),
    );
  }

  Future<void> _saveSingleTest(String r, String sName, String phone, String obtained, String total, String pct, String grade, bool isPass) async {
    final curDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final testVal = _t.text.trim();
    final subVal = _sub.text.trim();

    final pref = await SharedPreferences.getInstance();
    final key = 'tests_${widget.aId}_$r';
    final rawList = pref.getStringList(key) ?? [];
    final currentTests = rawList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    currentTests.removeWhere((e) => e['test'] == testVal && e['sub'] == subVal);
    currentTests.add({
      'test': testVal, 'sub': subVal, 'tot': total, 'marks': obtained, 'pct': pct, 'grade': grade, 'roll': r, 'date': curDate
    });

    await pref.setStringList(key, currentTests.map((e) => jsonEncode(e)).toList());

    if (phone.isNotEmpty) {
      sendGovCloudSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $sName (रोल: $r) का $testVal ($subVal) का परिणाम: प्राप्तांक $obtained/$total ($pct%), परिणाम: ${isPass ? "उत्तीर्ण" : "अनुत्तीर्ण"}।');
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$sName का परिणाम सुरक्षित व SMS प्रेषित! ✔')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('शैक्षणिक मूल्यांकन (Test Ledger)'),
        backgroundColor: const Color(0xFF07192C),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: const Color(0xFF07192C),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _t, style: const TextStyle(fontSize: 12), decoration: InputDecoration(labelText: 'परीक्षा', labelStyle: const TextStyle(color: Colors.white70), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), isDense: true, filled: true, fillColor: Colors.white))),
                      const SizedBox(width: 6),
                      Expanded(child: TextField(controller: _sub, style: const TextStyle(fontSize: 12), decoration: InputDecoration(labelText: 'विषय', labelStyle: const TextStyle(color: Colors.white70), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), isDense: true, filled: true, fillColor: Colors.white))),
                      const SizedBox(width: 6),
                      SizedBox(width: 70, child: TextField(controller: _tot, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: 'पूर्णांक', labelStyle: const TextStyle(color: Colors.white70), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), isDense: true, filled: true, fillColor: Colors.white))),
                    ],
                  ),
                ),
                Expanded(
                  child: _stds.isEmpty
                      ? const Center(child: Text('कोई शिक्षार्थी उपलब्ध नहीं है।'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          itemCount: _stds.length,
                          itemBuilder: (c, i) {
                            final r = _stds[i]['roll'].toString();
                            final sName = _stds[i]['name'] ?? '';
                            final phone = _stds[i]['phone'] ?? '';
                            final marks = double.tryParse(_m[r]?.text.trim() ?? '0') ?? 0;
                            final total = double.tryParse(_tot.text.trim()) ?? 50;
                            final pctNum = total > 0 ? (marks / total) * 100 : 0.0;
                            final pct = pctNum.toStringAsFixed(1);
                            final grade = _calcGrade(pctNum);
                            final isPass = pctNum >= 33;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isPass ? Colors.green.shade300 : Colors.red.shade300, width: 1.2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: const Color(0xFF07192C),
                                              child: Text(r, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: isPass ? Colors.green : Colors.red),
                                          ),
                                          child: Text(
                                            isPass ? 'उत्तीर्ण ($grade)' : 'अनुत्तीर्ण ($grade)',
                                            style: TextStyle(color: isPass ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: total > 0 ? (marks / total).clamp(0.0, 1.0) : 0,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(isPass ? Colors.green : Colors.red),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('अंक: ${marks.toInt()}/$total ($pct%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              height: 36,
                                              child: TextField(
                                                controller: _m[r],
                                                keyboardType: TextInputType.number,
                                                onChanged: (_) => setState(() {}),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                decoration: const InputDecoration(labelText: 'अंक', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.remove_red_eye, color: Color(0xFF07192C), size: 20),
                                              onPressed: () => _showMarkDialog(context, sName, r, _t.text.trim(), _sub.text.trim(), _m[r]?.text.trim() ?? '0', _tot.text.trim(), pct, grade),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2E7D32),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: const Size(60, 34),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              icon: const Icon(Icons.send, size: 12),
                                              label: const Text('SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              onPressed: () => _saveSingleTest(r, sName, phone, _m[r]?.text.trim() ?? '0', _tot.text.trim(), pct, grade, isPass),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
  Map<String, dynamic>? _found;
  List> _tests = [];
  int _attCount = 0;

  void _search() async {
    final r = _s.text.trim();
    if (r.isEmpty) return;

    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list_${widget.aId}') ?? [];
    final all = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final match = all.firstWhere((e) => e['roll'].toString() == r, orElse: () => {});
    if (match.isNotEmpty) {
      final rawTests = pref.getStringList('tests_${widget.aId}_$r') ?? [];
      final tList = rawTests.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      setState(() {
        _found = match;
        _tests = tList;
        _attCount = 1; // लोकल रिकॉर्ड
      });
    } else {
      setState(() {
        _found = null;
        _tests = [];
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('अभिलेख उपलब्ध नहीं है।')));
    }
  }

  void _showIDCard(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF07192C),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Color(0xFF07192C), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.org, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Row(children: [
                Expanded(child: Container(height: 3, color: const Color(0xFFFF9933))),
                Expanded(child: Container(height: 3, color: Colors.white)),
                Expanded(child: Container(height: 3, color: const Color(0xFF138808))),
              ]),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 28, backgroundColor: Color(0xFF07192C), child: Icon(Icons.person, size: 34, color: Color(0xFFFFD700))),
                    const SizedBox(height: 8),
                    Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF07192C))),
                    Text('अनुक्रमांक: ${d['roll']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12)),
                    const Divider(height: 18),
                    Text('कक्षा: ${d['class']} | पिता: ${d['father']}', style: const TextStyle(fontSize: 11)),
                    Text('दूरभाष: ${d['phone']}', style: const TextStyle(fontSize: 11)),
                    Text('स्थान: ${d['address']}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(6)),
                      child: const Text('अधिकृत शिक्षार्थी पहचान पत्र ✔', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें', style: TextStyle(fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('डिजिटल शिक्षार्थी डोजियर'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'विभागीय अनुक्रमांक दर्ज करें', border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white, minimumSize: const Size(50, 48)),
                  onPressed: _search,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_found != null)
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_found!['name']} (रोल: ${_found!['roll']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: const Color(0xFFFFD700), minimumSize: const Size(60, 30)),
                                  icon: const Icon(Icons.badge, size: 14),
                                  label: const Text('ID Card', style: TextStyle(fontSize: 10)),
                                  onPressed: () => _showIDCard(context, _found!),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Text('कक्षा: ${_found!['class']} | पिता: ${_found!['father']}\nमोबाइल: ${_found!['phone']} | पता: ${_found!['address']}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      color: const Color(0xFFE3F2FD),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('सक्रिय शिक्षार्थी प्रोफाइल उपलब्ध ✔', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D47A1))),
                      ),
                    ),
                    ..._tests.map((doc) {
                      return Card(
                        child: ListTile(
                          title: Text('${doc['test']} - ${doc['sub']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('प्रतिशत: ${doc['pct']}% | ग्रेड: ${doc['grade']}', style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                          trailing: Text('${doc['marks']} / ${doc['tot']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
