import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snow/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _primary = Color(0xFF5B4CF0);
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'request-temporary-password',
        body: {'email': _emailCtrl.text.trim()},
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300) {
        throw Exception(data is Map && data['message'] != null
            ? data['message'].toString()
            : 'La función respondió con error ${response.status}.');
      }
      if (data is! Map || data['success'] != true) {
        throw Exception(data is Map && data['message'] != null
            ? data['message'].toString()
            : 'No se confirmó el envío de la contraseña temporal.');
      }
      if (!mounted) return;
      _formKey.currentState?.reset();
      _emailCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.mark_email_read_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Revisa tu correo. Enviamos tu contraseña temporal.')),
          ]),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: const Color(0xFFE84D67),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  String _friendlyError(Object error) {
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['message'] != null) {
        return details['message'].toString();
      }
    }
    return error.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException(message: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(authLoadingProvider);
    final surface = dark ? const Color(0xFF181824) : Colors.white;
    final field = dark ? const Color(0xFF242433) : const Color(0xFFF4F3F8);
    final muted = dark ? const Color(0xFFB4B2C2) : const Color(0xFF747381);

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0E0E17) : const Color(0xFFF0EEFF),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _GlowOrb(size: 260, color: _primary.withOpacity(.10)),
          ),
          Positioned(
            bottom: -80,
            left: -90,
            child: _GlowOrb(
              size: 230,
              color: const Color(0xFF9287FF).withOpacity(.10),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 28),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: dark ? Colors.white10 : Colors.white),
                    boxShadow: [BoxShadow(
                      color: dark ? Colors.black38 : _primary.withOpacity(.12),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    )],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Volver al inicio de sesión',
                              onPressed: isLoading
                                  ? null
                                  : () => context.go('/login'),
                              icon: const Icon(Icons.arrow_back_rounded, size: 21),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(dark ? .16 : .08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.ac_unit_rounded,
                                    color: _primary,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Snow',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7668FF), _primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: _primary.withOpacity(.28), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 39),
                        )),
                        const SizedBox(height: 26),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Recupera el acceso a tu cuenta',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ingresa el correo asociado a tu cuenta y te enviaremos una contraseña temporal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _emailCtrl,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) { if (!isLoading) _resetPassword(); },
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'nombre@correo.com',
                            hintStyle: TextStyle(color: muted),
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            filled: true,
                            fillColor: field,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? Colors.white10 : const Color(0xFFE7E4F2))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primary, width: 1.6)),
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE84D67))),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE84D67), width: 1.6)),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Ingresa tu correo electrónico';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Ingresa un correo válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primary.withOpacity(.55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : _resetPassword,
                            icon: isLoading
                                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                : const Icon(Icons.send_rounded, size: 19),
                            label: Text(isLoading ? 'Enviando...' : 'Enviar contraseña temporal', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF20202D)
                                : const Color(0xFFF7F6FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dark
                                  ? Colors.white10
                                  : const Color(0xFFE9E6F4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  'Tu contraseña temporal se enviará únicamente al correo registrado en Snow.',
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: isLoading ? null : () => context.go('/login'),
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Volver a iniciar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
            }),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
