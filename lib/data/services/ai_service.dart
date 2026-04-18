import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

// IMPORTANT: Ensure your Env class is imported here
// import 'package:solobytes/core/env/env.dart';

class AiService {
  final http.Client _client = http.Client();

  static const String fallbackMessage =
      'Unable to generate insights right now. Please try again later.';

  Future<String> generateInsights(CashSummary summary) async {
    try {
      final prompt =
          '''
Weekly financials:
- Total sales: ${summary.totalSales}
- Total expenses: ${summary.totalExpenses}
- Unpaid customers: ${summary.unpaidReceivables}
- Unpaid vendors: ${summary.unpaidPayables}
- Top expense category: ${summary.topExpenseCategory}

Give 3 short, actionable insights.
''';

      // Use GROQ_API_KEY from environment variables
      final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

      final response = await _client.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama3-8b-8192", // Model available on Groq
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a financial advisor for small businesses. Give 3 short, practical insights in plain English. No jargon.",
            },
            {"role": "user", "content": prompt},
          ],
          "max_tokens": 300,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString().trim();
        }
      } else {
        print("Groq Error [${response.statusCode}]: ${response.body}");
      }

      return fallbackMessage;
    } catch (e) {
      print("Groq Exception: $e");
      return fallbackMessage;
    }
  }
}
