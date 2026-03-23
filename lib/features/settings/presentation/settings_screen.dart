import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double fontSize = 18;
  double lineHeight = 1.8;
  double letterSpacing = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cai dat doc')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Co chu: ${fontSize.toStringAsFixed(0)}'),
          Slider(
            min: 14,
            max: 26,
            value: fontSize,
            onChanged: (v) => setState(() => fontSize = v),
          ),
          const SizedBox(height: 12),
          Text('Line-height: ${lineHeight.toStringAsFixed(1)}'),
          Slider(
            min: 1.2,
            max: 2.4,
            value: lineHeight,
            onChanged: (v) => setState(() => lineHeight = v),
          ),
          const SizedBox(height: 12),
          Text('Letter-spacing: ${letterSpacing.toStringAsFixed(1)}'),
          Slider(
            min: -0.5,
            max: 2,
            value: letterSpacing,
            onChanged: (v) => setState(() => letterSpacing = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {},
            child: const Text('Luu va dong bo'),
          ),
        ],
      ),
    );
  }
}
