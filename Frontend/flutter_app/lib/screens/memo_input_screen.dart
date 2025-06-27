import 'package:flutter/material.dart';
import '../models/memo_model.dart';
import '../services/firebase_service.dart';

class MemoInputScreen extends StatefulWidget {
  final Memo? memo;
  final VoidCallback? onSaveSuccess;

  const MemoInputScreen({Key? key, this.memo, this.onSaveSuccess}) : super(key: key);

  @override
  _MemoInputScreenState createState() => _MemoInputScreenState();
}

class _MemoInputScreenState extends State<MemoInputScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  late List<String> _tags;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  // ★★★ UX改善のための追加部分 ① ★★★
  // タグ入力欄のフォーカスを監視するためのもの
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final isEditing = widget.memo != null;
    _titleController = TextEditingController(text: isEditing ? widget.memo!.title : '');
    _contentController = TextEditingController(text: isEditing ? widget.memo!.content : '');
    _tagController = TextEditingController();
    _tags = isEditing ? List.from(widget.memo!.tags) : [];

    // ★★★ UX改善のための追加部分 ② ★★★
    // フォーカスが外れたときのリスナーを設定
    _tagFocusNode.addListener(() {
      // フォーカスが外れ、かつ、テキスト入力欄に何か文字があればタグを追加
      if (!_tagFocusNode.hasFocus && _tagController.text.isNotEmpty) {
        _addTag();
      }
    });
  }

  void _addTag() {
    // trim()で前後の空白を削除し、純粋なテキストだけを比較・追加
    final newTag = _tagController.text.trim();
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      setState(() {
        _tags.add(newTag);
        _tagController.clear();
      });
      // タグを追加したら、再度フォーカスを当てる
      _tagFocusNode.requestFocus();
    }
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
  }

  Future<void> _saveOrUpdateMemo() async {
    // 保存する前に、万が一入力途中のタグがあれば追加する
    if (_tagController.text.isNotEmpty) {
      _addTag();
    }

    // ... (保存ロジックは変更なし) ...
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('タイトルとメモ内容を入力してください')));
      return;
    }
    setState(() { _isLoading = true; });
    final memoData = Memo(
      id: widget.memo?.id,
      title: _titleController.text,
      content: _contentController.text,
      tags: _tags,
      createdAt: widget.memo?.createdAt ?? DateTime.now(),
      isEvaluated: widget.memo?.isEvaluated ?? false,
    );
    try {
      if (widget.memo != null) {
        await _firebaseService.updateMemo(memoData);
      } else {
        await _firebaseService.saveMemo(memoData);
      }
      if (!mounted) return;
      final successMessage = widget.memo != null ? 'メモを更新しました' : 'メモを保存しました';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: Colors.green));
      if (widget.memo != null) {
        Navigator.of(context).pop();
      } else {
        _titleController.clear();
        _contentController.clear();
        setState(() => _tags.clear());
        widget.onSaveSuccess?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'ネタを編集' : '新しいネタを追加')),
      body: GestureDetector( // ★★★ 画面全体をタップ可能にする ★★★
        onTap: () {
          // 画面のどこかをタップしたら、キーボードを閉じる
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _titleController, decoration: InputDecoration(labelText: 'タイトル', border: OutlineInputBorder())),
              SizedBox(height: 16),
              TextField(controller: _contentController, maxLines: 8, decoration: InputDecoration(labelText: 'メモ内容', border: OutlineInputBorder(), hintText: 'ネタのアイデアを入力してください...')),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      // ★★★ UX改善のための追加部分 ③ ★★★
                      focusNode: _tagFocusNode,
                      controller: _tagController,
                      decoration: InputDecoration(labelText: 'タグ', border: OutlineInputBorder(), hintText: '入力してEnter'),
                      // キーボードの「実行」ボタンが押されたときにタグを追加
                      onSubmitted: (_) => _addTag(),
                    )
                  ),
                  IconButton(icon: Icon(Icons.add_circle_outline), onPressed: _addTag),
                ],
              ),
              SizedBox(height: 8),
              if (_tags.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('タグがありません', style: TextStyle(color: Colors.grey)))
              else
                Wrap(
                  spacing: 8.0,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  )).toList(),
                ),
              SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(isEditing ? Icons.sync : Icons.save),
                      onPressed: _saveOrUpdateMemo,
                      label: Text(isEditing ? '更新' : '保存'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose(); // ★★★ リスナーを破棄する ★★★
    super.dispose();
  }
}