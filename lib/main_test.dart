import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Input Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Click Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  debugPrint('BUTTON CLICKED!');
                },
                child: const Text('Click Me!'),
              ),
              const SizedBox(height: 20),
              const Text('If you can click the button, Flutter input works'),
            ],
          ),
        ),
      ),
    );
  }
}
