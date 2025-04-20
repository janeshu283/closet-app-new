import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _sendPasswordReset(BuildContext context) async {
    final client = Supabase.instance.client;
    final email = client.auth.currentUser?.email;
    if (email == null) return;
    try {
      await client.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('パスワードリセット'),
            content: const Text('パスワードリセットメールを送信しました。'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('エラー'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final client = Supabase.instance.client;
    await client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => const AuthOrMain()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('プロフィール'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('メール: $email'),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () => _sendPasswordReset(context),
                child: const Text('パスワードリセット'),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () => _signOut(context),
                child: const Text('ログアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
