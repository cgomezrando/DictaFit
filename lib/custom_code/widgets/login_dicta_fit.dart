// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class LoginDictaFit extends StatefulWidget {
  const LoginDictaFit({
    super.key,
    this.width,
    this.height,
    required this.onAutenticado,
  });

  final double? width;
  final double? height;
  final Future Function() onAutenticado;

  @override
  State<LoginDictaFit> createState() => _LoginDictaFitState();
}

class _LoginDictaFitState extends State<LoginDictaFit> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();

  bool _modoRegistro = false;
  bool _verPass = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  // ---------- Utilidades ----------

  Color _tinte(Color color, double opacidad) {
    return color.withAlpha((255 * opacidad).round());
  }

  Color _aclarar(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + cantidad).clamp(0.0, 1.0))
        .toColor();
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _mostrarMensaje(String mensaje) {
    final tema = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tema.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tema.alternate),
        ),
        content: Text(
          mensaje,
          style: tema.bodyMedium.copyWith(color: tema.primaryText),
        ),
      ),
    );
  }

  String _mensajeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos y vuelve a probar.';
      case 'network-request-failed':
        return 'Sin conexión. Comprueba tu red.';
      case 'operation-not-allowed':
        return 'El acceso con correo no está activado.';
      default:
        return 'No se pudo completar la operación (${e.code}).';
    }
  }

  void _cambiarModo(bool registro) {
    if (_cargando || registro == _modoRegistro) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _modoRegistro = registro;
      _pass2Controller.clear();
      _verPass = false;
    });
  }

  // ---------- Acciones ----------

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final pass = _passController.text;

    if (!_emailValido(email)) {
      _mostrarMensaje('Escribe un correo electrónico válido.');
      return;
    }
    if (pass.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_modoRegistro && pass != _pass2Controller.text) {
      _mostrarMensaje('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _cargando = true);

    try {
      if (_modoRegistro) {
        final credencial =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        final usuario = credencial.user;
        if (usuario != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(usuario.uid)
                .set(
              {
                'email': email,
                'uid': usuario.uid,
                'created_time': DateTime.now(),
              },
              SetOptions(merge: true),
            );
          } catch (e) {
            // El onboarding completa el documento con merge si esto falla.
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      TextInput.finishAutofillContext();
      if (!mounted) return;
      await widget.onAutenticado();
    } on FirebaseAuthException catch (e) {
      if (mounted) _mostrarMensaje(_mensajeError(e));
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
            'No se pudo completar la operación. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _recuperarContrasena() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    if (!_emailValido(email)) {
      _mostrarMensaje(
          'Escribe tu correo arriba y vuelve a pulsar "¿Olvidaste tu contraseña?".');
      return;
    }

    const mensajeNeutro =
        'Si existe una cuenta con ese correo, te hemos enviado un enlace para restablecer la contraseña.';

    setState(() => _cargando = true);
    try {
      await FirebaseAuth.instance.setLanguageCode('es');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _mostrarMensaje(mensajeNeutro);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        _mostrarMensaje(mensajeNeutro);
      } else {
        _mostrarMensaje(_mensajeError(e));
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('No se pudo enviar el correo. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // ---------- Componentes visuales ----------

  Widget _insignia(IconData icono, Color acento, double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_aclarar(acento, 0.10), acento],
        ),
        boxShadow: [
          BoxShadow(
            color: _tinte(acento, 0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icono, color: Colors.white, size: tamano * 0.5),
    );
  }

  Widget _chipFuncion(IconData icono, String texto, Color acento) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _tinte(acento, 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tinte(acento, 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: acento),
          const SizedBox(width: 6),
          Text(
            texto,
            style: tema.bodySmall.copyWith(
              color: tema.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorModo() {
    final tema = FlutterFlowTheme.of(context);

    Widget segmento(String texto, bool activo, VoidCallback alPulsar) {
      return Expanded(
        child: GestureDetector(
          onTap: alPulsar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: activo
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_aclarar(tema.primary, 0.10), tema.primary],
                    )
                  : null,
            ),
            child: Text(
              texto,
              style: tema.bodyMedium.copyWith(
                color: activo ? Colors.white : tema.secondaryText,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tema.primaryBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tema.alternate),
      ),
      child: Row(
        children: [
          segmento('Entrar', !_modoRegistro, () => _cambiarModo(false)),
          segmento('Crear cuenta', _modoRegistro, () => _cambiarModo(true)),
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String pista,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    Iterable<String>? autofill,
    bool contrasena = false,
    TextInputAction accion = TextInputAction.next,
    ValueChanged<String>? alEnviar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final bordeBase = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: tema.alternate),
    );

    return TextField(
      controller: controller,
      enabled: !_cargando,
      keyboardType: teclado,
      keyboardAppearance: Brightness.dark,
      autofillHints: autofill,
      obscureText: contrasena && !_verPass,
      autocorrect: false,
      enableSuggestions: !contrasena,
      textInputAction: accion,
      onSubmitted: alEnviar,
      cursorColor: tema.primary,
      style: tema.bodyLarge.copyWith(color: tema.primaryText),
      decoration: InputDecoration(
        hintText: pista,
        hintStyle:
            tema.bodyLarge.copyWith(color: _tinte(tema.secondaryText, 0.7)),
        prefixIcon: Icon(icono, size: 20, color: tema.secondaryText),
        suffixIcon: contrasena
            ? IconButton(
                onPressed: () => setState(() => _verPass = !_verPass),
                icon: Icon(
                  _verPass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: tema.secondaryText,
                ),
              )
            : null,
        filled: true,
        fillColor: tema.primaryBackground,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: bordeBase,
        enabledBorder: bordeBase,
        disabledBorder: bordeBase,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tema.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _botonGradiente({
    required String texto,
    required Color acento,
    required VoidCallback? alPulsar,
    IconData? icono,
    bool cargando = false,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final deshabilitado = alPulsar == null;
    return Opacity(
      opacity: deshabilitado && !cargando ? 0.5 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_aclarar(acento, 0.10), acento],
          ),
          boxShadow: deshabilitado
              ? const []
              : [
                  BoxShadow(
                    color: _tinte(acento, 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: alPulsar,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 56,
              child: Center(
                child: cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            texto,
                            style: tema.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (icono != null) ...[
                            const SizedBox(width: 8),
                            Icon(icono, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Marca
                Center(
                  child: _insignia(Icons.graphic_eq_rounded, tema.primary, 76),
                ),
                const SizedBox(height: 20),
                Text(
                  'DictaFit',
                  textAlign: TextAlign.center,
                  style: tema.headlineLarge.copyWith(
                    color: tema.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gym y dieta por voz',
                  textAlign: TextAlign.center,
                  style: tema.bodyLarge.copyWith(color: tema.secondaryText),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipFuncion(
                        Icons.fitness_center_rounded, 'Entreno', tema.primary),
                    _chipFuncion(
                        Icons.eco_rounded, 'Nutrición', tema.secondary),
                    _chipFuncion(
                        Icons.timer_rounded, 'Intervalos', tema.tertiary),
                  ],
                ),
                const SizedBox(height: 32),

                // Tarjeta de acceso
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tema.alternate),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.6],
                      colors: [
                        Color.alphaBlend(_tinte(tema.primary, 0.14),
                            tema.secondaryBackground),
                        tema.secondaryBackground,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _selectorModo(),
                      const SizedBox(height: 20),
                      _campo(
                        controller: _emailController,
                        pista: 'Correo electrónico',
                        icono: Icons.mail_outline_rounded,
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      _campo(
                        controller: _passController,
                        pista: 'Contraseña',
                        icono: Icons.lock_outline_rounded,
                        contrasena: true,
                        autofill: _modoRegistro
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        accion: _modoRegistro
                            ? TextInputAction.next
                            : TextInputAction.done,
                        alEnviar: _modoRegistro ? null : (_) => _enviar(),
                      ),
                      if (_modoRegistro) ...[
                        const SizedBox(height: 12),
                        _campo(
                          controller: _pass2Controller,
                          pista: 'Repite la contraseña',
                          icono: Icons.lock_reset_rounded,
                          contrasena: true,
                          autofill: const [AutofillHints.newPassword],
                          accion: TextInputAction.done,
                          alEnviar: (_) => _enviar(),
                        ),
                      ],
                      if (!_modoRegistro)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _cargando ? null : _recuperarContrasena,
                            style: TextButton.styleFrom(
                              foregroundColor: tema.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 10),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: tema.bodyMedium.copyWith(
                                color: tema.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                      const SizedBox(height: 4),
                      _botonGradiente(
                        texto: _modoRegistro ? 'Crear cuenta' : 'Entrar',
                        icono: Icons.arrow_forward_rounded,
                        acento: tema.primary,
                        alPulsar: _cargando ? null : _enviar,
                        cargando: _cargando,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  _modoRegistro
                      ? 'Tus datos se guardan en tu cuenta y solo tú puedes verlos.'
                      : 'Registra entrenos y comidas hablando.',
                  textAlign: TextAlign.center,
                  style: tema.bodySmall.copyWith(color: tema.secondaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
