// lib/screens/memo_list_screen.dart

import 'package:flutter/material.dart';
import '../models/memo_model.dart';
import '../services/ai_service.dart'; // AIサービスをインポート
import '../services/firebase_service.dart';
import 'memo_detail_screen.dart';
import 'memo_input_screen.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({Key? key}) : super(key: key);

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AiService _aiService = AiService(); // AIサービスをインスタンス化
  
  // AIアイデア生成を実行するメソッド
  Future<void> _runGeneration(String tag, List<Memo> memos) async {
    // 進行中ダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      final referenceMemos = memos.map((m) => m.content).toList();
      final result = await _aiService.generateIdea(referenceMemos);
      
      Navigator.of(context).pop(); // 進行中ダイアログを閉じる
      
      // 結果表示ダイアログ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('✨ 新しいアイデアが生まれました！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${result['title'] ?? '無題'}」', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(result['description'] ?? '説明がありません'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('閉じる'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // 進行中ダイアログを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI生成エラー: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ネタ帳')),
      body: StreamBuilder<List<Memo>>(
        stream: _firebaseService.getMemos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('エラー: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('メモがありません'));

          final groupedMemos = groupMemosByTag(snapshot.data!);
          final tags = groupedMemos.keys.toList();

          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final memosForTag = groupedMemos[tag]!;
              return _buildTagSection(tag, memosForTag);
            },
          );
        },
      ),
    );
  }

  Widget _buildTagSection(String tag, List<Memo> memos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tag, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: Colors.blueAccent),
                  tooltip: 'このタグのネタから新しいアイデアを生成',
                  onPressed: () => _runGeneration(tag, memos), // AI生成メソッドを呼び出す
                ),
              ],
            ),
          ),
          const Divider(),
          ...memos.map((memo) => _buildMemoCard(memo)).toList(),
        ],
      ),
    );
  }
  
  // 他のメソッドは変更なし
  Widget _buildMemoCard(Memo memo) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemoDetailScreen(memo: memo))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (memo.tags.isNotEmpty) Wrap(spacing: 6.0, children: memo.tags.map((tag) => Chip(label: Text(tag, style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)).toList()),
                    if (memo.tags.isNotEmpty) SizedBox(height: 8),
                    Text(memo.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(memo.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _navigateToInputScreen(memo: memo);
                  if (value == 'delete') _showDeleteConfirmDialog(memo);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('編集'))),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('削除', style: TextStyle(color: Colors.red)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Map<String, List<Memo>> groupMemosByTag(List<Memo> memos) {
    final map = <String, List<Memo>>{};
    for (var memo in memos) {
      if (memo.tags.isEmpty) {
        (map['(タグなし)'] ??= []).add(memo);
      } else {
        for (var tag in memo.tags) {
          (map[tag] ??= []).add(memo);
        }
      }
    }
    return map;
  }

  void _navigateToInputScreen({Memo? memo}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MemoInputScreen(memo: memo)));
  }

  void _showDeleteConfirmDialog(Memo memo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('確認'),
          content: Text('「${memo.title}」を本当に削除しますか？'),
          actions: [
            TextButton(child: Text('キャンセル'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('削除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firebaseService.deleteMemo(memo.id!);
                  if (mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) Navigator.of(context).pop();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除失敗: $e'), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
