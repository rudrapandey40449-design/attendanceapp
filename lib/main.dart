import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AuthScreen(),
  ));
}

Future sendSMS(BuildContext ctx, String phone, String msg) async {
  if (phone.isEmpty) return;
  final num = phone.replaceAll(RegExp(r'[^0-9]'), '');
  const key = 'TcMuHytKcrz7j8bbmvjdb6tIPG6ofRl0bM5y9c6LowxLrkSqTnGP0vlSteARud6dHjRMg9AGY8eUW5Ne';
  try {
    final res = await http.post(
      Uri.parse('https://www.fast2sms.com/dev/bulkV2'),
      headers: {'authorization': key, 'Content-Type': 'application/json'},
      body: jsonEncode({'route': 'q', 'message': msg, 'language': 'unicode', 'numbers': num}),
    );
    final d = jsonDecode(res.body);
    if (ctx.mounted && d['return'] == true) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('SMS भेजा गया ✔'), duration: Duration(seconds: 1)));
    }
  } catch (_) {}
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  final _u = TextEditingController(text: 'admin');
  final _p = TextEditingController(text: '1234');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07192C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 60, color: Color(0xFFFFD700)),
              const SizedBox(height: 12),
              const Text('राष्ट्रीय कोचिंग पोर्टल', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _u, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'यूज़रनेम', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _p, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'पासवर्ड', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder())),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                child: const Text('प्रवेश करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('कोचिंग डैशबोर्ड'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _tile(context, 'दैनिक उपस्थिति एवं ऑटो SMS', Icons.fingerprint, const AttScreen()),
          _tile(context, 'मासिक शुल्क संधारण', Icons.receipt_long, const FeeScreen()),
          _tile(context, 'टेस्ट अंक एवं रिजल्ट लेजर', Icons.assessment, const TestScreen()),
          _tile(context, 'नवीन छात्र नामांकन', Icons.person_add, const AddStudentScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, String t, IconData ic, Widget page) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF07192C), child: Icon(ic, color: const Color(0xFFFFD700))),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});
  @override
  State createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudentScreen> {
  final _n = TextEditingController();
  final _r = TextEditingController();
  final _p = TextEditingController();

  void _save() async {
    final name = _n.text.trim();
    final roll = _r.text.trim();
    final phone = _p.text.trim();
    if (name.isEmpty || roll.isEmpty) return;

    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list') ?? [];
    var list = raw.map((e) => jsonDecode(e)).toList();

    list.removeWhere((e) => e['roll'].toString() == roll);
    list.add({'name': name, 'roll': roll, 'phone': phone});

    await pref.setStringList('students_list', list.map((e) => jsonEncode(e)).toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('छात्र सुरक्षित हुआ ✔')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('नया नामांकन'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _n, decoration: const InputDecoration(labelText: 'छात्र का नाम', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _r, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अनुक्रमांक (Roll No)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर (SMS हेतु)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07192C), foregroundColor: const Color(0xFFFFD700), minimumSize: const Size.fromHeight(45)),
              onPressed: _save,
              child: const Text('सुरक्षित करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
class AttScreen extends StatefulWidget {
  const AttScreen({super.key});
  @override
  State createState() => _AttState();
}

class _AttState extends State<AttScreen> {
  var stds = [];
  var status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list') ?? [];
    setState(() {
      stds = raw.map((e) => jsonDecode(e)).toList();
    });
  }

  void _mark(String r, String name, String phone, String st) {
    setState(() {
      status[r] = st;
    });
    final dt = DateFormat('dd-MM-yyyy').format(DateTime.now());
    if (phone.isNotEmpty) {
      sendSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $name (रोल: $r) आज दिनांक $dt को कोचिंग में ${st == "P" ? "उपस्थित" : "अनुपस्थित"} है।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('दैनिक उपस्थिति'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: stds.isEmpty
          ? const Center(child: Text('कोई छात्र नहीं है। पहले नामांकन करें।'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: stds.length,
              itemBuilder: (ctx, i) {
                final r = stds[i]['roll'].toString();
                final name = stds[i]['name'] ?? '';
                final phone = stds[i]['phone'] ?? '';
                final cur = status[r] ?? '';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF07192C), child: Text(r, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold))),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('स्थिति: ${cur.isEmpty ? "बाकी" : (cur == "P" ? "उपस्थित ✔" : "अनुपस्थित ✖")}', style: TextStyle(color: cur == "P" ? Colors.green : (cur == "A" ? Colors.red : Colors.grey))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _mark(r, name, phone, 'P')),
                        IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _mark(r, name, phone, 'A')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});
  @override
  State createState() => _FeeState();
}

class _FeeState extends State<FeeScreen> {
  var stds = [];
  var paid = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list') ?? [];
    setState(() {
      stds = raw.map((e) => jsonDecode(e)).toList();
    });
  }

  void _pay(String r, String name, String phone) {
    final isPaidNow = !(paid[r] == true);
    setState(() {
      paid[r] = isPaidNow;
    });
    final m = DateFormat('MMMM yyyy').format(DateTime.now());
    if (isPaidNow && phone.isNotEmpty) {
      sendSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $name (रोल: $r) का माह $m का मासिक शुल्क प्राप्त हुआ।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मासिक शुल्क लेजर'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: stds.isEmpty
          ? const Center(child: Text('कोई छात्र नहीं है।'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: stds.length,
              itemBuilder: (ctx, i) {
                final r = stds[i]['roll'].toString();
                final name = stds[i]['name'] ?? '';
                final phone = stds[i]['phone'] ?? '';
                final isP = paid[r] == true;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: isP ? Colors.green.shade100 : Colors.red.shade100, child: Text(r, style: TextStyle(fontWeight: FontWeight.bold, color: isP ? Colors.green : Colors.red))),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isP ? 'शुल्क जमा ✔' : 'बकाया ✖', style: TextStyle(color: isP ? Colors.green : Colors.red)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isP ? Colors.green : Colors.red, foregroundColor: Colors.white),
                      onPressed: () => _pay(r, name, phone),
                      child: Text(isP ? 'Paid' : 'Due'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State createState() => _TestState();
}

class _TestState extends State<TestScreen> {
  var stds = [];
  var ctrl = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList('students_list') ?? [];
    setState(() {
      stds = raw.map((e) => jsonDecode(e)).toList();
      for (var s in stds) {
        ctrl[s['roll'].toString()] = TextEditingController(text: '0');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('टेस्ट अंक व SMS'), backgroundColor: const Color(0xFF07192C), foregroundColor: Colors.white),
      body: stds.isEmpty
          ? const Center(child: Text('कोई छात्र नहीं है।'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: stds.length,
              itemBuilder: (ctx, i) {
                final r = stds[i]['roll'].toString();
                final name = stds[i]['name'] ?? '';
                final phone = stds[i]['phone'] ?? '';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF07192C), child: Text(r, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold))),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 55,
                          height: 38,
                          child: TextField(
                            controller: ctrl[r],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () {
                            final m = ctrl[r]?.text.trim() ?? '0';
                            sendSMS(context, phone, 'प्रिय अभिभावक, शिक्षार्थी $name (रोल: $r) का टेस्ट परिणाम: प्राप्तांक $m/50।');
                          },
                          child: const Text('SMS'),
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
