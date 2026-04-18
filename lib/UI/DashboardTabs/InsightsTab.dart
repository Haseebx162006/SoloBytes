import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Widgets/AiInsightsCard.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Financial Insights',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        const AiInsightsCard(),

        const SizedBox(height: 16),
        const Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'These insights are powered by AI and generated based on your overall cash summary and recent activities. Check back later for updated actionable insights as your financials change.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
    );
  }
}
