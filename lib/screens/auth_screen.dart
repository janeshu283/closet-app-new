import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      if (_isLogin) {
        await client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // 新規登録時は確認メールが送信されるので、ログインモードに切り替え
        if (mounted) {
          await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('確認メール送信'),
              content: const Text('登録したメールアドレスに確認メールを送信しました。メール内のリンクで認証後、ログインしてください。'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() { _isLogin = true; });
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      final session = client.auth.currentSession;
      if (mounted && session != null) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('認証エラー'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isLogin ? 'ログイン' : 'サインアップ'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'メールアドレス',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'パスワード',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : Text(_isLogin ? 'ログイン' : '登録'),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? 'アカウントを作成'
                    : '既存のアカウントでログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
