import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Color ink = Color(0xFF101B2A);
const Color panel = Color(0xFF19283A);
const Color teal = Color(0xFF46C6A6);
const Color muted = Color(0xFF9BAEC2);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();
  runApp(EvolveApp(store: store));
}

class AppStore extends ChangeNotifier {
  AppStore(this.prefs);
  final SharedPreferences prefs;

  static Future<AppStore> load() async =>
      AppStore(await SharedPreferences.getInstance());

  int get dayNumber => prefs.getInt('dayNumber') ?? 1;
  String get coachEndpoint => prefs.getString('coachEndpoint') ?? '';
  String get journal => prefs.getString('journal_${dayNumber}') ?? '';
  Set<String> get completed =>
      (prefs.getStringList('completed_$dayNumber') ?? <String>[]).toSet();

  Future<void> toggleTask(String id) async {
    final next = completed;
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    await prefs.setStringList('completed_$dayNumber', next.toList());
    notifyListeners();
  }

  Future<void> saveJournal(String value) async {
    await prefs.setString('journal_$dayNumber', value);
    notifyListeners();
  }

  Future<void> saveEndpoint(String value) async {
    await prefs.setString('coachEndpoint', value.trim());
    notifyListeners();
  }

  Future<void> advanceDay() async {
    if (dayNumber < 365) {
      await prefs.setInt('dayNumber', dayNumber + 1);
      notifyListeners();
    }
  }

  int get totalCompleted {
    var total = 0;
    for (var i = 1; i <= 365; i++) {
      total += (prefs.getStringList('completed_$i') ?? []).length;
    }
    return total;
  }
}

class EvolveApp extends StatelessWidget {
  const EvolveApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVOLVE 2.0',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.dark,
          surface: panel,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: MainShell(store: store),
    );
  }
}

class DailyTask {
  const DailyTask(this.id, this.title, this.subtitle, this.minutes, this.icon);
  final String id, title, subtitle;
  final int minutes;
  final IconData icon;
}

const tasks = <DailyTask>[
  DailyTask('mind', 'ذهن‌آگاهی و مشاهده افکار', 'تنفس آرام و مشاهده بدون قضاوت', 10, Icons.self_improvement),
  DailyTask('learn', 'یادگیری موضوع اصلی', 'یک درس عمیق و یادداشت نکات کلیدی', 25, Icons.menu_book_rounded),
  DailyTask('think', 'تمرین منطق و تحلیل', 'ادعا، شواهد و فرض‌های پنهان را بررسی کن', 15, Icons.psychology_alt_rounded),
  DailyTask('english', 'زبان انگلیسی', 'واژگان و خواندن یک متن کوتاه', 15, Icons.translate_rounded),
  DailyTask('review', 'یادآوری فعال', 'بدون نگاه‌کردن، مطالب قبلی را بازیابی کن', 10, Icons.memory_rounded),
  DailyTask('apply', 'کاربرد و نوشتن', 'آموخته امروز را به مسئله‌ای واقعی وصل کن', 10, Icons.edit_note_rounded),
  DailyTask('reflect', 'بازبینی روزانه', 'چه چیزی آموختم و فردا چه چیزی را بهتر می‌کنم؟', 5, Icons.check_circle_outline),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final AppStore store;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store),
      AcademyPage(),
      CoachPage(store: widget.store),
      JournalPage(store: widget.store),
      ProgressPage(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: teal.withOpacity(.18),
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.school_rounded), label: 'آکادمی'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'مربی'),
          NavigationDestination(icon: Icon(Icons.book_rounded), label: 'ژورنال'),
          NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'پیشرفت'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final done = store.completed.length;
        final percent = done / tasks.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('EVOLVE 2.0', style: TextStyle(fontSize: 13, letterSpacing: 2.2, color: teal, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('نسخه آگاه‌تر تو', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                ]),
                IconButton(
                  tooltip: 'تنظیمات مربی',
                  onPressed: () => showEndpointDialog(context, store),
                  icon: const Icon(Icons.tune_rounded, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF244A58), Color(0xFF17283B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bolt_rounded, color: teal),
                    const SizedBox(width: 8),
                    Text('روز ${store.dayNumber} از ۳۶۵', style: const TextStyle(color: Colors.white70)),
                    const Spacer(),
                    const Text('مسیر یک‌ساله', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                  const SizedBox(height: 18),
                  const Text('هر روز، عمیق‌تر فکر کن.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  const Text('هدف امروز: فهم بهتر، نه فقط دانستن بیشتر.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 22),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('پیشرفت امروز', style: TextStyle(color: Colors.white70)),
                    Text('${(percent * 100).round()}٪', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: percent, minHeight: 9, backgroundColor: Colors.white12, color: teal),
                  ),
                  const SizedBox(height: 9),
                  Text('$done از ${tasks.length} تمرین انجام شده', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const SectionTitle('مأموریت‌های امروز', 'حدود ۹۰ دقیقه'),
            const SizedBox(height: 12),
            ...tasks.map((task) {
              final checked = store.completed.contains(task.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: CheckboxListTile(
                  value: checked,
                  onChanged: (_) => store.toggleTask(task.id),
                  activeColor: teal,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(task.icon, color: checked ? teal : muted),
                  title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: checked ? TextDecoration.lineThrough : null)),
                  subtitle: Text('${task.minutes} دقیقه · ${task.subtitle}', style: const TextStyle(color: muted, fontSize: 11)),
                ),
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: store.dayNumber == 365 ? null : () => confirmAdvance(context, store),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('پایان روز و رفتن به روز بعد'),
            ),
            const SizedBox(height: 10),
            const Text('یادآوری: یک روز ناقص، شکست نیست. استمرار از کمال‌گرایی مهم‌تر است.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          ],
        );
      },
    );
  }
}

class AcademyPage extends StatelessWidget {
  AcademyPage({super.key});
  final modules = const [
    ('ماه ۱', 'خودشناسی و فراشناخت', 'شناخت عادت‌ها، توجه و الگوهای فکری', Icons.person_search),
    ('ماه ۲', 'یادگیری و حافظه', 'یادآوری فعال، مرور فاصله‌دار و تمرکز', Icons.memory),
    ('ماه ۳', 'منطق و تفکر نقاد', 'مغالطه‌ها، شواهد و ارزیابی ادعاها', Icons.account_tree),
    ('ماه ۴', 'فلسفه و اخلاق', 'حقیقت، معرفت، ارزش‌ها و مسئولیت', Icons.account_balance),
    ('ماه ۵', 'روان‌شناسی', 'رفتار، هیجان، انگیزه و روابط', Icons.psychology),
    ('ماه ۶', 'تاریخ و تمدن', 'الگوهای تاریخی و تحول جوامع', Icons.public),
    ('ماه ۷', 'اقتصاد و جامعه', 'بازارها، نهادها و تصمیم جمعی', Icons.insights),
    ('ماه ۸', 'علوم طبیعی', 'فیزیک، زیست‌شناسی و روش علمی', Icons.science),
    ('ماه ۹', 'فناوری و هوش مصنوعی', 'فناوری‌های نو و پیامدهای آن‌ها', Icons.memory_rounded),
    ('ماه ۱۰', 'تفکر استراتژیک', 'سیستم‌ها، سناریو و مدیریت ریسک', Icons.route),
    ('ماه ۱۱', 'هوش اجتماعی', 'ارتباط، مذاکره و همدلی', Icons.groups),
    ('ماه ۱۲', 'پروژه تلفیقی', 'تحلیل چندبعدی یک مسئله واقعی', Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const PageHeader('آکادمی', 'نقشه یادگیری ۱۲ ماهه'),
      const SizedBox(height: 18),
      const InfoBanner(text: 'هر ماه یک محور اصلی دارد؛ تمرین زبان، تفکر نقاد و خودشناسی در تمام ماه‌ها ادامه پیدا می‌کند.'),
      const SizedBox(height: 14),
      ...modules.map((m) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: teal.withOpacity(.15), child: Icon(m.$4, color: teal)),
          title: Text('${m.$1} · ${m.$2}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(m.$3, style: const TextStyle(color: muted)),
          trailing: const Icon(Icons.chevron_left, color: muted),
          onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
            title: Text(m.$2),
            content: Text('این ماژول شامل درس‌های کوتاه، تمرین کاربردی، آزمون یادآوری و یک پروژه پایانی خواهد بود.\n\nمحور: ${m.$3}'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('متوجه شدم'))],
          )),
        ),
      )),
    ],
  );
}

class CoachPage extends StatefulWidget {
  const CoachPage({super.key, required this.store});
  final AppStore store;
  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  final messages = <({bool user, String text})>[
    (user: false, text: 'سلام. من مربی EVOLVE هستم. می‌توانم در یادگیری، تحلیل، تفکر نقاد و بازبینی اهداف همراهت باشم. برای شروع، یک سؤال یا مسئله واقعی مطرح کن.')
  ];
  bool busy = false;

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || busy) return;
    controller.clear();
    setState(() { messages.add((user: true, text: text)); busy = true; });
    final endpoint = widget.store.coachEndpoint;
    if (endpoint.isEmpty) {
      setState(() {
        messages.add((user: false, text: 'برای فعال‌کردن پاسخ هوشمند، ابتدا نشانی سرور امن مربی را از تنظیمات وارد کن. تا آن زمان می‌توانی پرسشت را ثبت کنی؛ اتصال مستقیم و امن به سرویس هوش مصنوعی نیازمند سرور واسط است.'));
        busy = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'system': 'تو مربی آموزشی EVOLVE هستی. به فارسی پاسخ بده. دقیق، فروتن، مبتنی بر شواهد و شفاف درباره عدم قطعیت باش. به جای تأیید بی‌دلیل، استدلال را بررسی کن.',
          'day': widget.store.dayNumber,
        }),
      ).timeout(const Duration(seconds: 40));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('پاسخ سرور: ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      final answer = data is Map ? (data['reply'] ?? data['answer'] ?? 'پاسخی دریافت نشد.').toString() : response.body;
      setState(() => messages.add((user: false, text: answer)));
    } catch (e) {
      setState(() => messages.add((user: false, text: 'ارتباط با مربی برقرار نشد. اتصال اینترنت و نشانی سرور را بررسی کن.\nجزئیات: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { controller.dispose(); scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(children: [
    const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: PageHeader('مربی هوشمند', 'گفت‌وگو برای عمیق‌تر فکر کردن')),
    Expanded(
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length + (busy ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == messages.length) return const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)));
          final m = messages[i];
          return Align(
            alignment: m.user ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: m.user ? const Color(0xFF244A58) : panel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(m.text, style: const TextStyle(height: 1.55)),
            ),
          );
        },
      ),
    ),
    SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'سؤالت را بنویس...',
              filled: true,
              fillColor: panel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => send(),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: teal, foregroundColor: ink),
            onPressed: busy ? null : send,
            icon: const Icon(Icons.send_rounded),
          ),
        ]),
      ),
    ),
  ]);
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, required this.store});
  final AppStore store;
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late final TextEditingController text;
  @override
  void initState() { super.initState(); text = TextEditingController(text: widget.store.journal); }
  @override
  void dispose() { text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const PageHeader('ژورنال آگاهی', 'مشاهده، ثبت و بازاندیشی'),
      const SizedBox(height: 18),
      const InfoBanner(text: 'صادقانه بنویس؛ لازم نیست نوشته‌ها زیبا یا کامل باشند. هدف، دیدن الگوهاست نه قضاوت‌کردن خودت.'),
      const SizedBox(height: 18),
      const Text('پرسش‌های راهنما', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 10),
      ...[
        'امروز چه چیزی بیشترین توجه من را گرفت؟',
        'کدام باورم را باید با شواهد بیشتری بررسی کنم؟',
        'چه احساسی داشتم و چه چیزی آن را فعال کرد؟',
        'فردا یک رفتار کوچک را چگونه بهتر انجام می‌دهم؟',
      ].map((q) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $q', style: const TextStyle(color: muted)))),
      const SizedBox(height: 12),
      TextField(
        controller: text,
        minLines: 9,
        maxLines: 16,
        decoration: InputDecoration(
          hintText: 'یادداشت امروزت را اینجا بنویس...',
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () async {
          await widget.store.saveJournal(text.text);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('یادداشت ذخیره شد.')));
        },
        icon: const Icon(Icons.save_outlined),
        label: const Text('ذخیره یادداشت'),
      ),
      const SizedBox(height: 8),
      const Text('یادداشت‌ها فعلاً روی همین دستگاه ذخیره می‌شوند.', style: TextStyle(color: muted, fontSize: 11)),
    ],
  );
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final completed = store.totalCompleted;
      final possible = store.dayNumber * tasks.length;
      final rate = possible == 0 ? 0.0 : (completed / possible).clamp(0.0, 1.0).toDouble();
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader('پیشرفت', 'اندازه‌گیری استمرار و یادگیری'),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: MetricCard(label: 'روز فعلی', value: '${store.dayNumber}/365', icon: Icons.calendar_month)),
            const SizedBox(width: 10),
            Expanded(child: MetricCard(label: 'تمرین انجام‌شده', value: '$completed', icon: Icons.task_alt)),
          ]),
          const SizedBox(height: 12),
          Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('نرخ انجام تمرین‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: rate, minHeight: 9, color: teal, backgroundColor: Colors.white12),
              const SizedBox(height: 8),
              Text('${(rate * 100).round()}٪ از تمرین‌های برنامه‌ریزی‌شده تا امروز', style: const TextStyle(color: muted, fontSize: 12)),
            ]),
          )),
          const SizedBox(height: 12),
          const InfoBanner(text: 'این نسخه، شاخص‌های رفتاری پایه را ثبت می‌کند. سنجش معتبر مهارت‌هایی مثل استدلال و دانش باید با آزمون‌های جداگانه و تکرارشونده اضافه شود.'),
          const SizedBox(height: 20),
          const Text('معیارهای رشد در نسخه‌های بعدی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 10),
          const Wrap(spacing: 8, runSpacing: 8, children: [
            Pill('دانش و یادآوری'), Pill('استدلال'), Pill('فراشناخت'), Pill('خودفرمانی'), Pill('کاربرد دانش'), Pill('زبان انگلیسی'),
          ]),
        ],
      );
    },
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 5),
    Text(subtitle, style: const TextStyle(color: muted)),
  ]);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, this.trailing, {super.key});
  final String title, trailing;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Text(trailing, style: const TextStyle(color: muted, fontSize: 12)),
  ]);
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: teal.withOpacity(.09), borderRadius: BorderRadius.circular(16), border: Border.all(color: teal.withOpacity(.18))),
    child: Text(text, style: const TextStyle(color: Color(0xFFC7E5DC), height: 1.5, fontSize: 13)),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: teal),
      const SizedBox(height: 14),
      Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ]),
  ));
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Chip(label: Text(text), backgroundColor: panel, side: BorderSide.none);
}

Future<void> confirmAdvance(BuildContext context, AppStore store) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('رفتن به روز بعد؟'),
      content: const Text('حتی اگر همه تمرین‌ها کامل نشده‌اند، می‌توانی ادامه بدهی. استمرار مهم‌تر از کامل‌بودن است.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ادامه مسیر')),
      ],
    ),
  );
  if (ok == true) await store.advanceDay();
}

Future<void> showEndpointDialog(BuildContext context, AppStore store) async {
  final c = TextEditingController(text: store.coachEndpoint);
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('اتصال امن مربی هوشمند'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('نشانی HTTPS سرور واسط خودت را وارد کن. کلید API نباید داخل اپلیکیشن ذخیره شود.'),
        const SizedBox(height: 12),
        TextField(controller: c, decoration: const InputDecoration(hintText: 'https://your-server.example/chat')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: () async {
          await store.saveEndpoint(c.text);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('ذخیره')),
      ],
    ),
  );
  c.dispose();
}
