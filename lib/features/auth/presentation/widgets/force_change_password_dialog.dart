import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diálogo obligatorio para solicitar al usuario una nueva contraseña.
class ForceChangePasswordDialog extends StatefulWidget {
  const ForceChangePasswordDialog({
    super.key,
    this.minimumPasswordLength = 6,
  });

  final int minimumPasswordLength;

  @override
  State<ForceChangePasswordDialog> createState() =>
      _ForceChangePasswordDialogState();
}

class _ForceChangePasswordDialogState extends State<ForceChangePasswordDialog> {
  static const _primary = Color(0xFF5546E8);
  static const _fieldBackground = Color(0xFFF3F3F6);
  static const _textMuted = Color(0xFF6E6E7A);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;

      if (session == null || user == null) {
        throw Exception(
          'La sesión expiró. Inicia sesión nuevamente.',
        );
      }

      debugPrint(
        'Invocando change-temporary-password...',
      );

      final response = await client.functions.invoke(
        'change-temporary-password',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'password': _passwordController.text,
          'confirmPassword': _confirmationController.text,
        },
      );

      debugPrint(
        'Estado Edge Function: ${response.status}',
      );
      debugPrint(
        'Respuesta Edge Function: ${response.data}',
      );

      final data = response.data;

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'La función respondió con error ${response.status}.',
        );
      }

      if (data is! Map || data['success'] != true) {
        throw Exception(
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'No se confirmó el cambio de contraseña.',
        );
      }

      // La función puede invalidar el refresh token al cambiar la contraseña.
      // El cambio ya fue confirmado, así que un refresh fallido no debe
      // convertir el resultado exitoso en un error para el usuario.
      try {
        // No se refresca aquí: el cambio administrativo de contraseña puede
        // invalidar el refresh token anterior y vaciar la sesión local.
      } catch (refreshError, refreshStackTrace) {
        debugPrint('No se pudo refrescar la sesión: $refreshError');
        debugPrintStack(stackTrace: refreshStackTrace);
      }

      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(true);
    } catch (error, stackTrace) {
      debugPrint(
        'Error cambiando contraseña: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is FunctionException) {
      final details = error.details;

      if (details is Map && details['message'] != null) {
        return details['message'].toString();
      }

      return 'No fue posible cambiar la contraseña. Inténtalo nuevamente.';
    }

    if (error is AuthException) {
      return error.message;
    }

    final text = error.toString();

    return text.replaceFirst('Exception: ', '');
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una nueva contraseña';
    }
    if (value.length < widget.minimumPasswordLength) {
      return 'Debe tener al menos ${widget.minimumPasswordLength} caracteres';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-+=]').hasMatch(value)) {
      return 'Debe incluir al menos un carácter especial';
    }
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required bool obscureText,
    required VoidCallback? onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline, size: 20),
      suffixIcon: IconButton(
        tooltip: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: onToggleVisibility,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
      ),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      color: _primary,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cambia tu contraseña',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por seguridad, debes crear una nueva contraseña antes de continuar.',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _passwordController,
                    autofocus: true,
                    obscureText: _obscurePassword,
                    enabled: !_saving,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _inputDecoration(
                      label: 'Nueva contraseña',
                      obscureText: _obscurePassword,
                      onToggleVisibility: _saving
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmationController,
                    obscureText: _obscureConfirmation,
                    enabled: !_saving,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _changePassword(),
                    decoration: _inputDecoration(
                      label: 'Confirmar contraseña',
                      obscureText: _obscureConfirmation,
                      onToggleVisibility: _saving
                          ? null
                          : () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu nueva contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withOpacity(0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saving ? null : _changePassword,
                      child: _saving
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar nueva contraseña',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
