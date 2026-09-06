import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuggestedQuestion {
  const SuggestedQuestion({
    required this.id,
    required this.question,
    required this.bookName,
    required this.author,
  });

  factory SuggestedQuestion.fromJson(Map<String, dynamic> json) {
    return SuggestedQuestion(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      bookName: json['book_name'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }

  final int id;
  final String question;
  final String bookName;
  final String author;
}

final suggestedQuestionsProvider =
    FutureProvider<List<SuggestedQuestion>>((ref) async {
  try {
    final jsonString = await rootBundle.loadString(
      'assets/data/suggested_questions_c1.json',
    );
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final list = data['questions'] as List<dynamic>? ?? [];
    return list
        .map((e) => SuggestedQuestion.fromJson(e as Map<String, dynamic>))
        .where((q) => q.question.isNotEmpty)
        .toList();
  } catch (e) {
    return const [];
  }
});

extension SuggestedQuestionsListX on List<SuggestedQuestion> {
  List<SuggestedQuestion> pickRandom(int count) {
    if (isEmpty) return const [];
    final shuffled = List<SuggestedQuestion>.from(this)..shuffle(Random());
    return shuffled.take(count).toList();
  }
}
