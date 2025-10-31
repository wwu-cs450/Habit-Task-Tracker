import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Habits'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Track checkbox state for each list item. Initialize with 5 items.
  List<bool> _checked = List<bool>.filled(5, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        toolbarHeight: 75,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Make this actually open a menu
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Menu tapped')));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Make this actually open settings
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings tapped')));
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: _checked.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: _checked[index],
                  onChanged: (bool? value) {
                    setState(() {
                      // Make this actually update the habit status
                      _checked[index] = value ?? false;
                    });
                  },
                ),
                title: Text('Card title ${index + 1}'),
                subtitle: Text('This is a description for card ${index + 1}.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Make this actually open card details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Card ${index + 1} tapped')),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
