import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../services/server_config.dart';
import 'menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiClient _api = ApiClient();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _isSignup = false;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final email = _email.text.trim();
    final senha = _senha.text;

    if (username.isEmpty || senha.isEmpty || (_isSignup && email.isEmpty)) {
      _snack('Preencha todos os campos.');
      return;
    }

    setState(() => _busy = true);
    try {
      final token = _isSignup
          ? await _api.register(username, email, senha)
          : await _api.login(username, senha);
      await AuthStorage.saveToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Menu()),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _configureServer() async {
    final current = await ServerConfig.baseUrl();
    if (!mounted) return;
    final controller = TextEditingController(text: current ?? 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servidor'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL do servidor Railway',
            hintText: 'https://seu-app.up.railway.app',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      await ServerConfig.setBaseUrl(url);
      _snack('Servidor salvo.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignup ? 'Criar conta' : 'Entrar'),
        actions: [
          IconButton(
            tooltip: 'Configurar servidor',
            icon: const Icon(Icons.dns),
            onPressed: _busy ? null : _configureServer,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _username,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                if (_isSignup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _senha,
                  enabled: !_busy,
                  obscureText: true,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignup ? 'Criar conta' : 'Entrar'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isSignup = !_isSignup),
                  child: Text(
                    _isSignup
                        ? 'Já tem conta? Entrar'
                        : 'Não tem conta? Criar conta',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
