import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/data/repositories/insights_repository_impl.dart';
import 'package:solobytes/data/services/ai_service.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

class GetInsightsUseCase {
  const GetInsightsUseCase(this._aiService, this._repository);

  final AiService _aiService;
  final InsightsRepositoryImpl _repository;

  Future<String> execute({
    required String uid,
    required CashSummary summary,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return AiService.fallbackMessage;
    }

    // 1. Check cached insight from Firestore
    final cached = await _repository.getLatestInsight(normalizedUid);

    if (cached != null) {
      final generatedAt = cached['generatedAt'] as Timestamp?;

      // 2. If cached is valid and not older than 6 hours -> Return cached
      if (generatedAt != null) {
        final ageInHours = DateTime.now()
            .difference(generatedAt.toDate())
            .inHours;

        if (ageInHours < 6) {
          final cachedText = cached['text'] as String?;
          if (cachedText != null && cachedText.trim().isNotEmpty) {
            return cachedText;
          }
        }
      }
    }

    // 3. Otherwise -> Call AI Service to generate new insights
    final newInsight = await _aiService.generateInsights(summary);

    // 4. Save new insight if successful
    if (newInsight != AiService.fallbackMessage) {
      await _repository.saveInsight(
        uid: normalizedUid,
        text: newInsight,
        summary: summary,
      );
    }

    return newInsight;
  }
}
