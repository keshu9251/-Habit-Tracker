
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HabitTrackerApp());
}

const Color purple = Color(0xFF7655C9);
const Color lightPurple = Color(0xFFF0EBFA);
const Color background = Color(0xFFF8F7FC);

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
      ),
      home: const HomeScreen(),
    );
  }
}

class Habit {
  String name;
  String category;
  bool completed;

  Habit(
    this.name, {
    this.category = 'Personal',
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'completed': completed,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      json['name'] as String,
      category: json['category'] as String? ?? 'Personal',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Habit> habits = [];
  bool isLoading = true;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    loadHabits();
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = habits.map((habit) => habit.toJson()).toList();
    await prefs.setString('habits', jsonEncode(data));
  }

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('habits');

    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);

      habits.addAll(
        decoded.map(
          (item) => Habit.fromJson(
            Map<String, dynamic>.from(item),
          ),
        ),
      );
    } else {
      habits.addAll([
        Habit('Morning Walk', category: 'Fitness'),
        Habit('Drink 8 Glasses of Water', category: 'Health'),
        Habit('Read for 30 Minutes', category: 'Learning'),
        Habit('Exercise', category: 'Fitness'),
      ]);
      await saveHabits();
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addHabit(String name, String category) async {
    if (name.trim().isEmpty) return;

    setState(() {
      habits.add(
        Habit(name.trim(), category: category),
      );
      selectedTab = 0;
    });

    await saveHabits();
  }

  Future<void> toggleHabit(int index, bool? value) async {
    setState(() {
      habits[index].completed = value ?? false;
    });
    await saveHabits();
  }

  Future<void> deleteHabit(int index) async {
    setState(() {
      habits.removeAt(index);
    });
    await saveHabits();
  }

  IconData habitIcon(String category) {
    switch (category) {
      case 'Fitness':
        return Icons.fitness_center_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Learning':
        return Icons.menu_book_rounded;
      case 'Work':
        return Icons.work_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Widget habitCard(int index) {
    final habit = habits[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: habit.completed
              ? const Color(0xFFDCD2F3)
              : const Color(0xFFEDEAF3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 7,
        ),
        leading: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: lightPurple,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            habitIcon(habit.category),
            color: purple,
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: habit.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: habit.completed ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          habit.completed ? 'Completed ✓' : habit.category,
          style: TextStyle(
            color: habit.completed ? purple : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: habit.completed,
              activeColor: purple,
              onChanged: (value) => toggleHabit(index, value),
            ),
            IconButton(
              onPressed: () => deleteHabit(index),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget progressCard() {
    final completed = habits.where((h) => h.completed).length;
    final progress =
        habits.isEmpty ? 0.0 : completed / habits.length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7655C9), Color(0xFF9677DF)],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S PROGRESS",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completed out of ${habits.length} habits completed',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white30,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                ),
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Hello, Welcome! 👋',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Small steps every day lead to big changes.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),
        progressCard(),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Daily Habits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${habits.length} habits',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (habits.isEmpty)
          const Padding(
            padding: EdgeInsets.all(25),
            child: Text(
              'No habits yet. Go to Add Habit to get started!',
              textAlign: TextAlign.center,
            ),
          ),
        ...List.generate(habits.length, habitCard),
      ],
    );
  }

  Widget addPage() {
    final nameController = TextEditingController();
    String category = 'Personal';

    return StatefulBuilder(
      builder: (context, updateDialog) {
        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Create New Habit ✨',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Build a better routine, one habit at a time.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Habit Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Read for 30 minutes',
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Choose Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'Personal',
                      'Fitness',
                      'Health',
                      'Learning',
                      'Work',
                    ].map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        updateDialog(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a habit name'),
                            ),
                          );
                          return;
                        }

                        await addHabit(name, category);
                        nameController.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Habit added successfully!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Save Habit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget statisticsPage() {
    final completed = habits.where((h) => h.completed).length;
    final pending = habits.length - completed;
    final progress =
        habits.isEmpty ? 0.0 : completed / habits.length;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Your Statistics 📊',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check your daily habit performance.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Text(
                'Overall Completion',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 145,
                width: 145,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 13,
                        backgroundColor: lightPurple,
                        valueColor:
                            const AlwaysStoppedAnimation(purple),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                '$completed of ${habits.length} habits completed',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: statisticCard(
                'Total Habits',
                habits.length.toString(),
                Icons.list_alt_rounded,
                purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statisticCard(
                'Completed',
                completed.toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        statisticCard(
          'Pending Habits',
          pending.toString(),
          Icons.pending_actions_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget statisticCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      addPage(),
      statisticsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Habit Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: IndexedStack(
                  index: selectedTab,
                  children: pages,
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        backgroundColor: Colors.white,
        indicatorColor: lightPurple,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: purple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded, color: purple),
            label: 'Add Habit',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: purple),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
