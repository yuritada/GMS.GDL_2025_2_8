import 'package:cloud_firestore/cloud_firestore.dart';

class Memo {
  final String? id;
  final String title;
  final String content;
  final List<String> tags;
  final Map<String, double>? dimensions;
  final DateTime createdAt;
  final bool isEvaluated;

  Memo({
    this.id,
    required this.title,
    required this.content,
    required this.tags,
    this.dimensions,
    required this.createdAt,
    this.isEvaluated = false,
  });

  // FirestoreのドキュメントからMemoを生成
  factory Memo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // dimensionsをMapに変換
    Map<String, double> dimensionsMap = {};
    if (data['dimensions'] != null) {
      (data['dimensions'] as Map<String, dynamic>).forEach((key, value) {
        dimensionsMap[key] = (value as num).toDouble();
      });
    }

    return Memo(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      dimensions: dimensionsMap.isNotEmpty ? dimensionsMap : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isEvaluated: data['isEvaluated'] ?? false,
    );
  }

  // MemoをFirestoreに保存可能なMapに変換
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'dimensions': dimensions,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEvaluated': isEvaluated,
    };
  }
}