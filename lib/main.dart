// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuizApp());
}

/* ---------------------------
   MODELS & DATA SERVICE
--------------------------- */
class Question {
  String text;
  List<String> options;
  int correctIndex;

  Question({required this.text, required this.options, required this.correctIndex});

  Map<String, dynamic> toMap() => {
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
      };

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        text: m['text'],
        options: List<String>.from(m['options']),
        correctIndex: m['correctIndex'],
      );
}

class ResultEntry {
  String studentName;
  String roll;
  int score;
  int total;
  String time;

  ResultEntry({required this.studentName, required this.roll, required this.score, required this.total, required this.time});

  Map<String, dynamic> toMap() => {
        'studentName': studentName,
        'roll': roll,
        'score': score,
        'total': total,
        'time': time,
      };

  factory ResultEntry.fromMap(Map<String, dynamic> m) => ResultEntry(
        studentName: m['studentName'],
        roll: m['roll'],
        score: m['score'],
        total: m['total'],
        time: m['time'],
      );
}

class DataService {
  static const String _kQuestions = 'questions';
  static const String _kResults = 'results';
  static const String _kSubject = 'subject';
  static const String _kProfessor = 'professor';
  static const String _kAccessCode = 'accessCode';
  static const String _kDuration = 'durationSeconds';
  static const String _kAdminPass = 'adminPass';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<List<Question>> loadQuestions() async {
    final p = await _prefs();
    final s = p.getString(_kQuestions) ?? '[]';
    final List decoded = jsonDecode(s);
    return decoded.map((m) => Question.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  static Future<void> saveQuestions(List<Question> list) async {
    final p = await _prefs();
    await p.setString(_kQuestions, jsonEncode(list.map((q) => q.toMap()).toList()));
  }

  static Future<List<ResultEntry>> loadResults() async {
    final p = await _prefs();
    final s = p.getString(_kResults) ?? '[]';
    final List decoded = jsonDecode(s);
    return decoded.map((m) => ResultEntry.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  static Future<void> addResult(ResultEntry r) async {
    final list = await loadResults();
    list.add(r);
    final p = await _prefs();
    await p.setString(_kResults, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  static Future<void> saveSettings({String? subject, String? professor, String? accessCode, int? durationSeconds, String? adminPass}) async {
    final p = await _prefs();
    if (subject != null) await p.setString(_kSubject, subject);
    if (professor != null) await p.setString(_kProfessor, professor);
    if (accessCode != null) await p.setString(_kAccessCode, accessCode);
    if (durationSeconds != null) await p.setInt(_kDuration, durationSeconds);
    if (adminPass != null) await p.setString(_kAdminPass, adminPass);
  }

  static Future<String> subject() async => (await _prefs()).getString(_kSubject) ?? 'Unknown Subject';
  static Future<String> professor() async => (await _prefs()).getString(_kProfessor) ?? 'Professor';
  static Future<String> accessCode() async => (await _prefs()).getString(_kAccessCode) ?? 'quiz123';
  static Future<int> durationSeconds() async => (await _prefs()).getInt(_kDuration) ?? 600;
  static Future<String> adminPass() async => (await _prefs()).getString(_kAdminPass) ?? 'prof123';
}

/* ---------------------------
   APP
--------------------------- */
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const LandingPage(),
    );
  }
}

/* ---------------------------
   LANDING PAGE
--------------------------- */
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('📚 Quiz App',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black38, offset: Offset(2, 2))])),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.school, size: 28),
              label: const Text('Professor Login', style: TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessorLoginPage())),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person, size: 28),
              label: const Text('Student Login', style: TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLoginPage())),
            ),
          ]),
        ),
      ),
    );
  }
}

/* ---------------------------
   PROFESSOR LOGIN
--------------------------- */
class ProfessorLoginPage extends StatefulWidget {
  const ProfessorLoginPage({super.key});
  @override
  State<ProfessorLoginPage> createState() => _ProfessorLoginPageState();
}

class _ProfessorLoginPageState extends State<ProfessorLoginPage> {
  final _passCtrl = TextEditingController();
  String _storedAdmin = 'prof123';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DataService.adminPass().then((v) => setState(() { _storedAdmin = v; _loading = false; }));
  }

  void _login() {
    if (_passCtrl.text == _storedAdmin) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfessorPanel()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong admin password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.deepPurple, Colors.indigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('👨‍🏫 Professor Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: _passCtrl, obscureText: true,
                    decoration: InputDecoration(labelText: 'Admin Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 6), child: const Text('Login', style: TextStyle(fontSize: 20))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------
   PROFESSOR PANEL
--------------------------- */
class ProfessorPanel extends StatefulWidget {
  const ProfessorPanel({super.key});
  @override
  State<ProfessorPanel> createState() => _ProfessorPanelState();
}

class _ProfessorPanelState extends State<ProfessorPanel> {
  List<Question> _questions = [];
  List<ResultEntry> _results = [];
  final _subject = TextEditingController();
  final _profName = TextEditingController();
  final _accessCode = TextEditingController();
  final _duration = TextEditingController();
  final _adminPass = TextEditingController();
  bool _loading = true;

  Future<void> _loadAll() async {
    final q = await DataService.loadQuestions();
    final r = await DataService.loadResults();
    final s = await DataService.subject();
    final p = await DataService.professor();
    final ac = await DataService.accessCode();
    final dur = await DataService.durationSeconds();
    final ap = await DataService.adminPass();
    setState(() { _questions = q; _results = r; _subject.text = s; _profName.text = p; _accessCode.text = ac; _duration.text = dur.toString(); _adminPass.text = ap; _loading = false; });
  }

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _saveSettings() async {
    final dur = int.tryParse(_duration.text) ?? 600;
    await DataService.saveSettings(subject: _subject.text, professor: _profName.text, accessCode: _accessCode.text, durationSeconds: dur, adminPass: _adminPass.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _addQuestion() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddQuestionPage()));
    if (res == true) await _loadAll();
  }

  Future<void> _editQuestion(int index) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddQuestionPage(existing: _questions[index], editIndex: index)));
    if (res == true) await _loadAll();
  }

  Future<void> _deleteQuestion(int index) async {
    _questions.removeAt(index);
    await DataService.saveQuestions(_questions);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Professor Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Class Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          ...[_subject, _profName, _accessCode, _duration, _adminPass].map((c) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: c, obscureText: c == _adminPass, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 6), child: const Text('Save Settings')),
          const Divider(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: _addQuestion, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 6), child: const Text('➕ Add'))]),
          const SizedBox(height: 8),
          ..._questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(q.text),
                subtitle: Text('Options: ${q.options.join(" | ")}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editQuestion(i)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(i)),
                ]),
              ),
            );
          }).toList(),
          if (_questions.isEmpty) const Text('No questions yet.'),
          const Divider(height: 30),
          const Text('Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ..._results.reversed.map((r) => Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(title: Text('${r.studentName} (${r.roll})'), subtitle: Text('${r.score}/${r.total} • ${r.time}')))).toList(),
        ]),
      ),
    );
  }
}

/* ---------------------------
   ADD/EDIT QUESTION PAGE
   --------------------------- */
class AddQuestionPage extends StatefulWidget {
  final Question? existing;
  final int? editIndex;
  AddQuestionPage({this.existing, this.editIndex, super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _qCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = List.generate(4, (i) => TextEditingController());
  int _correct = 0;
  bool _loading = true;
  List<Question> _allQuestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _qCtrl.text = widget.existing!.text;
      for (int i = 0; i < 4; i++) _optCtrls[i].text = widget.existing!.options[i];
      _correct = widget.existing!.correctIndex;
    }
    DataService.loadQuestions().then((v) {
      setState(() {
        _allQuestions = v;
        _loading = false;
      });
    });
  }

  Future<void> _save() async {
    if (_qCtrl.text.isEmpty || _optCtrls.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    final newQ = Question(
      text: _qCtrl.text,
      options: _optCtrls.map((c) => c.text).toList(),
      correctIndex: _correct,
    );
    if (widget.editIndex != null) {
      _allQuestions[widget.editIndex!] = newQ;
    } else {
      _allQuestions.add(newQ);
    }
    await DataService.saveQuestions(_allQuestions);
    Navigator.pop(context, true);
  }

  Widget _buildTextField(TextEditingController c, String label, {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Question' : 'Add Question')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_qCtrl, 'Question'),
              const SizedBox(height: 12),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: _optCtrls[i],
                    decoration: InputDecoration(
                      labelText: 'Option ${i + 1}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: RadioListTile(
                      title: Text('Correct ${i + 1}'),
                      value: i,
                      groupValue: _correct,
                      onChanged: (int? v) => setState(() => _correct = v!),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                ),
                child: const Text('Save Question', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/* ---------------------------
   STUDENT LOGIN & QUIZ
--------------------------- */
class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});
  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _accessCtrl = TextEditingController();
  bool _loading = true;
  String _storedAccess = 'quiz123';

  @override
  void initState() {
    super.initState();
    DataService.accessCode().then((v) => setState(() { _storedAccess = v; _loading = false; }));
  }

  void _login() {
    if (_accessCtrl.text == _storedAccess && _nameCtrl.text.isNotEmpty && _rollCtrl.text.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizPage(name: _nameCtrl.text, roll: _rollCtrl.text)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid access or missing info')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Student Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _accessCtrl, decoration: const InputDecoration(labelText: 'Quiz Access Code', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 6), child: const Text('Start Quiz')),
        ]),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String name;
  final String roll;
  const QuizPage({required this.name, required this.roll, super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> _questions = [];
  int _index = 0;
  int _score = 0;
  Timer? _timer;
  int _remaining = 0;

  Future<void> _loadQuiz() async {
    final q = await DataService.loadQuestions();
    final dur = await DataService.durationSeconds();
    setState(() { _questions = q; _remaining = dur; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _remaining--; });
      if (_remaining <= 0) _submit();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _answer(int choice) {
  if (_questions[_index].correctIndex == choice) _score++;

if (_index < _questions.length - 1) {
  setState(() {
    _index++;
  });
} else {
  _submit();
}

  }

  void _submit() {
    _timer?.cancel();
    final now = DateTime.now();
    final entry = ResultEntry(studentName: widget.name, roll: widget.roll, score: _score, total: _questions.length, time: '${now.hour}:${now.minute}:${now.second}');
    DataService.addResult(entry).then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultPage(entry: entry))));
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions available')));
    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz ${_index + 1}/${_questions.length}'), actions: [Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('⏱ $_remaining')))]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...q.options.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => _answer(e.key),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
              child: Text(e.value, style: const TextStyle(fontSize: 18)),
            ),
          )),
        ]),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final ResultEntry entry;
  const ResultPage({required this.entry, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🎉 ${entry.studentName} (${entry.roll})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Score: ${entry.score}/${entry.total}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              Text('Time: ${entry.time}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingPage()), (route) => false), child: const Text('Back to Home')),
            ]),
          ),
        ),
      ),
    );
  }
}
