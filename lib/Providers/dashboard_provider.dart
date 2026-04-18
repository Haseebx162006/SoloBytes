import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/receivables_provider.dart';
import 'package:solobytes/application/usecases/get_summary_usecase.dart';
import 'package:solobytes/data/repositories/dashboard_repository_impl.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

class DashboardDateRange {
  const DashboardDateRange({this.startDate, this.endDate, this.period = 'all'});

  final DateTime? startDate;
  final DateTime? endDate;
  final String period;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DashboardDateRange &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, period);
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final dashboardRepositoryProvider = Provider<DashboardRepositoryImpl>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DashboardRepositoryImpl(firestore: firestore);
});

final getSummaryUseCaseProvider = Provider<GetSummaryUseCase>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return GetSummaryUseCase(repository);
});

final dashboardProvider = FutureProvider<CashSummary>((ref) async {
  final accessState = await ref.watch(authAccessStateProvider.future);
  if (accessState != AuthAccessState.authenticated) {
    throw Exception('Complete business setup to access dashboard.');
  }

  // Recalculate summary whenever receivables/payables change.
  ref.watch(receivablesProvider);
  ref.watch(payablesProvider);

  final useCase = ref.watch(getSummaryUseCaseProvider);
  try {
    return await useCase.execute();
  } catch (_) {
    throw Exception('Unable to load dashboard summary');
  }
});

final dashboardRangeProvider =
    FutureProvider.family<CashSummary, DashboardDateRange>((ref, range) async {
      final accessState = await ref.watch(authAccessStateProvider.future);
      if (accessState != AuthAccessState.authenticated) {
        throw Exception('Complete business setup to access dashboard.');
      }

      // Keep range summaries in sync with live receivables/payables updates.
      ref.watch(receivablesProvider);
      ref.watch(payablesProvider);

      final useCase = ref.watch(getSummaryUseCaseProvider);
      try {
        return await useCase.execute(
          startDate: range.startDate,
          endDate: range.endDate,
          period: range.period,
        );
      } catch (_) {
        throw Exception('Unable to load dashboard summary');
      }
    });
