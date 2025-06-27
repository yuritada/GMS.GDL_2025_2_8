import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memo_model.dart';

// Firestoreとの全ての通信を担うクラス
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// メモの一覧をリアルタイムで取得する
  Stream<List<Memo>> getMemos() {
    return _firestore
        .collection('memos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Memo.fromFirestore(doc)).toList());
  }

  /// 新しいメモを保存する
  ///
  /// Memoオブジェクトを受け取り、それをMapに変換してFirestoreに追加する
  Future<String> saveMemo(Memo memo) async {
    try {
      // ★★★ 最重要ポイント ★★★
      // memo.toMap() を呼ぶことで、タイトル、内容、そして「タグ」も
      // 含んだ全てのデータが、抜け漏れなくMapに変換される。
      final memoMap = memo.toMap();

      DocumentReference docRef = await _firestore.collection('memos').add(memoMap);
      return docRef.id;
    } catch (e) {
      print('Error saving memo: $e');
      rethrow; // エラーを呼び出し元に伝えて、UIに表示させる
    }
  }

  /// 既存のメモを更新する
  Future<void> updateMemo(Memo memo) async {
    if (memo.id == null) {
      // 理論上、編集時はIDが必ずあるはずだが、念のためチェック
      throw Exception("Cannot update a memo without an ID");
    }
    try {
      // ★★★ ここでも同じく toMap() を使う ★★★
      await _firestore.collection('memos').doc(memo.id).update(memo.toMap());
    } catch (e) {
      print('Error updating memo: $e');
      rethrow;
    }
  }

  /// メモをIDで削除する
  Future<void> deleteMemo(String id) async {
    try {
      await _firestore.collection('memos').doc(id).delete();
    } catch (e) {
      print('Error deleting memo: $e');
      rethrow;
    }
  }
}
