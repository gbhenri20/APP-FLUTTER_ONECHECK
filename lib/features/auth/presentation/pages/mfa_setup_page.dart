import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/auth_session.dart';

class MfaSetupPage extends ConsumerStatefulWidget {
  const MfaSetupPage({super.key});

  @override
  ConsumerState<MfaSetupPage> createState() => _MfaSetupPageState();
}

class _MfaSetupPageState extends ConsumerState<MfaSetupPage> {
  final _codigo = TextEditingController();
  MfaSetupData? _setup;
  bool _loadingSetup = true;
  bool _activating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(authStateProvider.notifier).loadSetupData();
      if (mounted) {
        setState(() {
          _setup = data;
          _loadingSetup = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSetup = false;
          _error = 'Não foi possível iniciar o setup do MFA';
        });
      }
    }
  }

  Future<void> _activate() async {
    final code = _codigo.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Informe o código de 6 dígitos');
      return;
    }
    setState(() {
      _activating = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(authStateProvider.notifier).activateSetup(code);
      if (!mounted) return;
      if (result == null) {
        context.go('/');
      } else {
        setState(() => _error = result);
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível ativar o MFA');
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authStateProvider).pendingSetupToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar MFA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: _loadingSetup
          ? const OcLoading(message: 'Gerando segredo MFA...')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Primeiro acesso — ative o autenticador',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escaneie o QR Code ou digite o segredo no Google Authenticator, '
                  'depois confirme com o código gerado.',
                ),
                const SizedBox(height: 24),
                if (_setup?.qrUrl.isNotEmpty == true)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _setup!.qrUrl,
                        width: 200,
                        height: 200,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.qr_code_2,
                          size: 120,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SelectableText(
                  'Segredo: ${_setup?.secret ?? '—'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codigo,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Código de confirmação',
                    counterText: '',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                OcPrimaryButton(
                  label: 'Ativar MFA e entrar',
                  loading: _activating,
                  icon: Icons.security,
                  onPressed: _activate,
                ),
              ],
            ),
    );
  }
}
