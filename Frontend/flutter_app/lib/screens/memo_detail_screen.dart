import 'package:flutter/material.dart';
import '../models/memo_model.dart';
import '../services/ai_service.dart'; // AIサービスをインポート

class MemoDetailScreen extends StatefulWidget {
  final Memo memo;
  const MemoDetailScreen({Key? key, required this.memo}) : super(key: key);

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  final AiService _aiService = AiService();
  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluationScores;

  Future<void> _runEvaluation() async {
    setState(() {
      _isEvaluating = true;
      _evaluationScores = null; // 前回の結果をクリア
    });
    try {
      final scores = await _aiService.evaluateIdea(widget.memo.content);
      setState(() {
        _evaluationScores = scores;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI評価エラー: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('メモの内容', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Text(widget.memo.content, style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(height: 16),
              Text('タグ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (widget.memo.tags.isNotEmpty)
                Wrap(spacing: 8.0, children: widget.memo.tags.map((tag) => Chip(label: Text(tag))).toList())
              else
                const Text('タグはありません'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text('AIによる評価', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (_isEvaluating)
                      CircularProgressIndicator()
                    else
                      ElevatedButton.icon(
                        icon: Icon(Icons.psychology),
                        label: Text('評価を実行する'),
                        onPressed: _runEvaluation,
                      ),
                    const SizedBox(height: 16),
                    if (_evaluationScores != null)
                      // 結果表示用のウィジェット
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: _evaluationScores!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key),
                                    Text(entry.value?.toString() ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
