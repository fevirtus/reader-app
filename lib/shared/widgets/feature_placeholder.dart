import 'package:flutter/material.dart';

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.description,
    this.actions = const <Widget>[],
  });

  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Text(description, style: theme.textTheme.bodyLarge),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
