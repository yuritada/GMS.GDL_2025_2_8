import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/memo_list_screen.dart';
import 'screens/memo_input_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ネタ帳アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // initStateの中で、画面のリストを一度だけ作成する
    _widgetOptions = <Widget>[
      MemoListScreen(),
      MemoInputScreen(key: ValueKey('new_memo_input'), onSaveSuccess: _switchToListView),
    ];
  }
  // ★★★★★★★★★★★★★★★★★★★★★★

  // タブを「ネタ一覧」に切り替えるメソッド
  void _switchToListView() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // buildメソッドの中では、もうリストを作り直さない！
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions, // initStateで作ったリストを使い回す
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'ネタ一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '新規追加',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
