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

import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '/auth/firebase_auth/auth_util.dart';

/// Si el compilador se queja de que no encuentra 'package:http/http.dart',
/// añádelo en Custom Pub Dependencies (ya debería estar, se usa también en
/// RegistroEntreno).
const String _baseUrlApiPerfil =
    'https://dictafit-api-1028761004087.europe-west1.run.app';

enum _EstadoPerfil { cargando, error, listo, guardando, eliminando }

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  static const Map<String, String> _opcionesSexo = {
    'hombre': 'Hombre',
    'mujer': 'Mujer',
  };

  static const Map<String, String> _opcionesActividad = {
    'sedentario': 'Sedentario',
    'ligero': 'Ligero',
    'moderado': 'Moderado',
    'alto': 'Alto',
    'muy_alto': 'Muy alto',
  };

  static const Map<String, String> _opcionesObjetivo = {
    'perder': 'Perder grasa',
    'mantener': 'Mantener',
    'ganar': 'Ganar músculo',
  };

  static const Map<String, String> _opcionesPesoAlimentos = {
    'crudo': 'En crudo',
    'cocinado': 'Cocinados',
  };

  _EstadoPerfil _estado = _EstadoPerfil.cargando;
  String? _errorCarga;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _pesoBarraController = TextEditingController();
  final TextEditingController _cuelloController = TextEditingController();
  final TextEditingController _cinturaController = TextEditingController();
  final TextEditingController _caderaController = TextEditingController();
  final TextEditingController _diasEntrenoController = TextEditingController();
  final TextEditingController _objetivoPasosController =
      TextEditingController();

  String? _sexo;
  DateTime? _fechaNacimiento;
  String? _actividad;
  String? _objetivo;
  String? _pesoAlimentos;
  DateTime? _fechaObjetivoPeso;

  double _pesoOriginalKg = 0;
  double _grasaOriginalPct = 0;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _pesoBarraController.dispose();
    _cuelloController.dispose();
    _cinturaController.dispose();
    _caderaController.dispose();
    _diasEntrenoController.dispose();
    _objetivoPasosController.dispose();
    super.dispose();
  }

  // ---------- Carga ----------

  Future<void> _cargar() async {
    final userRef = currentUserReference;
    if (userRef == null) {
      setState(() {
        _estado = _EstadoPerfil.error;
        _errorCarga = 'Tu sesión ha caducado. Vuelve a iniciar sesión.';
      });
      return;
    }
    try {
      final doc = await userRef.get();
      final datos = doc.data() as Map<String, dynamic>? ?? {};

      _nombreController.text = (datos['display_name'] ?? '').toString();
      _email =
          (datos['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '')
              .toString();
      _sexo = (datos['sexo'] as String?);
      final fechaNac = datos['fechaNacimiento'];
      _fechaNacimiento = fechaNac is Timestamp ? fechaNac.toDate() : null;
      _alturaController.text =
          (datos['alturaCm'] as num?)?.round().toString() ?? '';
      _pesoOriginalKg = (datos['pesoKg'] as num?)?.toDouble() ?? 0;
      _pesoController.text =
          _pesoOriginalKg > 0 ? _formatearNumero(_pesoOriginalKg) : '';
      _grasaOriginalPct = (datos['grasaCorporalPct'] as num?)?.toDouble() ?? 0;
      _actividad = (datos['actividad'] as String?);
      _objetivo = (datos['objetivo'] as String?);
      _pesoAlimentos = (datos['pesoAlimentos'] as String?);
      _pesoBarraController.text =
          _formatearNumero((datos['pesoBarraKg'] as num?)?.toDouble() ?? 20.0);
      final cuello = (datos['cuelloCm'] as num?)?.toDouble();
      final cintura = (datos['cinturaCm'] as num?)?.toDouble();
      final cadera = (datos['caderaCm'] as num?)?.toDouble();
      _cuelloController.text = cuello == null ? '' : _formatearNumero(cuello);
      _cinturaController.text =
          cintura == null ? '' : _formatearNumero(cintura);
      _caderaController.text = cadera == null ? '' : _formatearNumero(cadera);
      final dias = (datos['diasEntrenoSemana'] as num?)?.round();
      _diasEntrenoController.text = dias == null ? '' : dias.toString();
      final objetivoPasos = (datos['objetivoPasos'] as num?)?.toInt() ?? 10000;
      _objetivoPasosController.text = objetivoPasos.toString();
      final fechaObj = datos['fechaObjetivoPeso'];
      _fechaObjetivoPeso = fechaObj is Timestamp ? fechaObj.toDate() : null;

      if (mounted) setState(() => _estado = _EstadoPerfil.listo);
    } catch (_) {
      if (mounted) {
        setState(() {
          _estado = _EstadoPerfil.error;
          _errorCarga = 'No se ha podido cargar tu perfil. Inténtalo de nuevo.';
        });
      }
    }
  }

  // ---------- Utilidades ----------

  double? _leerDouble(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  int? _leerInt(String texto) {
    final valor = _leerDouble(texto);
    return valor?.round();
  }

  double _log10(double x) => math.log(x) / math.ln10;

  /// Estimación de grasa corporal con el método de la Marina de EE. UU.
  /// (Hodgdon & Beckett, 1984), a partir de contornos con cinta métrica.
  /// En hombres usa cuello y cintura; en mujeres, cuello, cintura y cadera.
  /// Es una estimación por fórmula, no una medición real (tipo DEXA o
  /// bioimpedancia), así que solo se calcula con datos completos y válidos.
  double? _calcularGrasaCorporal() {
    final alturaCm = _leerInt(_alturaController.text)?.toDouble();
    final cuello = _leerDouble(_cuelloController.text);
    final cintura = _leerDouble(_cinturaController.text);
    if (alturaCm == null || alturaCm <= 0 || cuello == null || cintura == null)
      return null;

    if (_sexo == 'mujer') {
      final cadera = _leerDouble(_caderaController.text);
      if (cadera == null) return null;
      final base = cintura + cadera - cuello;
      if (base <= 0) return null;
      final denom =
          1.29579 - 0.35004 * _log10(base) + 0.22100 * _log10(alturaCm);
      if (denom <= 0) return null;
      final resultado = 495 / denom - 450;
      return resultado.isFinite ? resultado.clamp(3.0, 60.0) : null;
    }

    final base = cintura - cuello;
    if (base <= 0) return null;
    final denom = 1.0324 - 0.19077 * _log10(base) + 0.15456 * _log10(alturaCm);
    if (denom <= 0) return null;
    final resultado = 495 / denom - 450;
    return resultado.isFinite ? resultado.clamp(3.0, 60.0) : null;
  }

  String _formatearNumero(double valor) {
    return valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : valor.toString();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    final tema = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tema.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: esError ? tema.error : tema.secondary),
      ),
      content: Text(mensaje,
          style: tema.bodyMedium.copyWith(color: tema.primaryText)),
    ));
  }

  // ---------- Selectores ----------

  Future<void> _elegirFecha({
    required DateTime? actual,
    required DateTime primera,
    required DateTime ultima,
    required String titulo,
    required ValueChanged<DateTime> alElegir,
  }) async {
    FocusScope.of(context).unfocus();
    final tema = FlutterFlowTheme.of(context);
    final seleccion = await showDatePicker(
      context: context,
      initialDate: actual ?? ultima,
      firstDate: primera,
      lastDate: ultima,
      helpText: titulo,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: tema.primary,
              onPrimary: Colors.white,
              surface: tema.secondaryBackground,
              onSurface: tema.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) alElegir(seleccion);
  }

  // ---------- Guardar ----------

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final userRef = currentUserReference;
    if (userRef == null) {
      _mostrarMensaje('Tu sesión ha caducado. Vuelve a iniciar sesión.');
      return;
    }

    final nombre = _nombreController.text.trim();
    final altura = _leerInt(_alturaController.text);
    final peso = _leerDouble(_pesoController.text);
    final pesoBarra = _leerDouble(_pesoBarraController.text) ?? 20.0;
    final dias = _leerInt(_diasEntrenoController.text);
    final objetivoPasos = _leerInt(_objetivoPasosController.text) ?? 10000;
    final cuello = _leerDouble(_cuelloController.text);
    final cintura = _leerDouble(_cinturaController.text);
    final cadera = _leerDouble(_caderaController.text);

    final errores = <String>[];
    if (nombre.isEmpty || nombre.length > 40) errores.add('el nombre');
    if (_sexo == null) errores.add('el sexo');
    if (_fechaNacimiento == null) errores.add('la fecha de nacimiento');
    if (altura == null || altura < 120 || altura > 230)
      errores.add('la altura (120–230 cm)');
    if (peso == null || peso < 30 || peso > 250)
      errores.add('el peso (30–250 kg)');
    if (_actividad == null) errores.add('el nivel de actividad');
    if (_objetivo == null) errores.add('el objetivo');
    if (_pesoAlimentos == null) errores.add('cómo pesas los alimentos');
    if (pesoBarra < 5 || pesoBarra > 50)
      errores.add('el peso de la barra (5–50 kg)');
    if (dias != null && (dias < 0 || dias > 7))
      errores.add('los días de entreno (0–7)');
    if (objetivoPasos < 1000 || objetivoPasos > 50000)
      errores.add('el objetivo de pasos (1.000–50.000)');
    if (_cuelloController.text.trim().isNotEmpty &&
        (cuello == null || cuello < 20 || cuello > 60)) {
      errores.add('el contorno de cuello (20–60 cm)');
    }
    if (_cinturaController.text.trim().isNotEmpty &&
        (cintura == null || cintura < 40 || cintura > 200)) {
      errores.add('el contorno de cintura (40–200 cm)');
    }
    if (_sexo == 'mujer' &&
        _caderaController.text.trim().isNotEmpty &&
        (cadera == null || cadera < 40 || cadera > 200)) {
      errores.add('el contorno de cadera (40–200 cm)');
    }

    if (errores.isNotEmpty) {
      _mostrarMensaje('Revisa: ${errores.join(', ')}.');
      return;
    }

    setState(() => _estado = _EstadoPerfil.guardando);
    try {
      final grasaCorporal = _calcularGrasaCorporal();
      final objetivos = calcularObjetivos(
        _sexo!,
        peso!,
        altura!,
        _fechaNacimiento!,
        _actividad!,
        _objetivo!,
      );

      await userRef.set({
        'display_name': nombre,
        'sexo': _sexo,
        'fechaNacimiento': _fechaNacimiento,
        'alturaCm': altura,
        'pesoKg': peso,
        'actividad': _actividad,
        'objetivo': _objetivo,
        'pesoAlimentos': _pesoAlimentos,
        'pesoBarraKg': pesoBarra,
        'diasEntrenoSemana': dias,
        'objetivoPasos': objetivoPasos,
        'fechaObjetivoPeso': _fechaObjetivoPeso,
        'cuelloCm': cuello,
        'cinturaCm': cintura,
        'caderaCm': _sexo == 'mujer' ? cadera : null,
        'grasaCorporalPct': grasaCorporal != null
            ? double.parse(grasaCorporal.toStringAsFixed(1))
            : null,
        'objetivoKcal': objetivos.kcal,
        'objetivoProteinaG': objetivos.proteinaG,
        'objetivoCarbosG': objetivos.carbosG,
        'objetivoGrasaG': objetivos.grasaG,
      }, SetOptions(merge: true));

      if ((peso - _pesoOriginalKg).abs() >= 0.1 ||
          (grasaCorporal != null &&
              (grasaCorporal - _grasaOriginalPct).abs() >= 0.1)) {
        await userRef.collection('pesos').add({
          'fecha': FieldValue.serverTimestamp(),
          'pesoKg': peso,
          'grasaCorporalPct': grasaCorporal != null
              ? double.parse(grasaCorporal.toStringAsFixed(1))
              : null,
        });
        _pesoOriginalKg = peso;
        _grasaOriginalPct = grasaCorporal ?? _grasaOriginalPct;
      }

      if (!mounted) return;
      _mostrarMensaje('Perfil actualizado.', esError: false);
      setState(() => _estado = _EstadoPerfil.listo);
    } catch (_) {
      if (mounted) {
        setState(() => _estado = _EstadoPerfil.listo);
        _mostrarMensaje(
            'No se ha podido guardar. Comprueba la conexión e inténtalo de nuevo.');
      }
    }
  }

  // ---------- Cerrar sesión / eliminar cuenta ----------

  Future<void> _cerrarSesion() async {
    final tema = FlutterFlowTheme.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tema.secondaryBackground,
        title:
            Text('¿Cerrar sesión?', style: TextStyle(color: tema.primaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar',
                  style: TextStyle(color: tema.secondaryText))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  Text('Cerrar sesión', style: TextStyle(color: tema.error))),
        ],
      ),
    );
    if (confirmar != true) return;
    GoRouter.of(context).prepareAuthEvent();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth('Login', context.mounted);
  }

  Future<void> _eliminarCuenta() async {
    final tema = FlutterFlowTheme.of(context);
    final controladorConfirmacion = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        return AlertDialog(
          backgroundColor: tema.secondaryBackground,
          title: Text('Eliminar cuenta',
              style: TextStyle(color: tema.primaryText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se borrarán tus entrenos, comidas y datos de perfil. Esta acción no se puede deshacer.',
                style: TextStyle(color: tema.secondaryText),
              ),
              const SizedBox(height: 14),
              Text('Escribe ELIMINAR para confirmar.',
                  style: TextStyle(color: tema.secondaryText, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: controladorConfirmacion,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: tema.primaryText),
                onChanged: (_) => setDialog(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tema.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tema.alternate),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar',
                    style: TextStyle(color: tema.secondaryText))),
            TextButton(
              onPressed: controladorConfirmacion.text.trim().toUpperCase() ==
                      'ELIMINAR'
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: Text('Eliminar', style: TextStyle(color: tema.error)),
            ),
          ],
        );
      }),
    );
    if (confirmar != true) return;

    setState(() => _estado = _EstadoPerfil.eliminando);
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) throw Exception('sin sesión');
      final token = await usuario.getIdToken();
      final resp = await http.post(
        Uri.parse('$_baseUrlApiPerfil/v1/cuenta/eliminar'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        Map<String, dynamic> json = {};
        try {
          json =
              jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        } catch (_) {}
        throw Exception((json['detail'] ?? 'Ha ocurrido un error.').toString());
      }

      if (!context.mounted) return;
      GoRouter.of(context).prepareAuthEvent();
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      GoRouter.of(context).clearRedirectLocation();
      context.goNamedAuth('Login', context.mounted);
    } catch (e) {
      if (mounted) {
        setState(() => _estado = _EstadoPerfil.listo);
        _mostrarMensaje(
            'No se ha podido eliminar la cuenta. Comprueba la conexión e inténtalo de nuevo.');
      }
    }
  }

  // ---------- UI ----------

  Widget _cabecera() {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.safePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: tema.primaryText, size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Tu perfil',
                style: tema.titleLarge.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto) {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(texto,
          style: tema.bodyMedium.copyWith(
              color: tema.secondaryText, fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _decoracionCampo(String pista,
      {String? sufijo, Color? acento}) {
    final tema = FlutterFlowTheme.of(context);
    final bordeBase = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: tema.alternate),
    );
    return InputDecoration(
      hintText: pista,
      hintStyle:
          tema.bodyLarge.copyWith(color: _tinte(tema.secondaryText, 0.7)),
      suffixText: sufijo,
      suffixStyle: tema.bodyMedium.copyWith(color: tema.secondaryText),
      filled: true,
      fillColor: tema.primaryBackground,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: bordeBase,
      enabledBorder: bordeBase,
      disabledBorder: bordeBase,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: acento ?? tema.primary, width: 1.5),
      ),
    );
  }

  Widget _campoTexto(
    TextEditingController controller,
    String pista, {
    TextInputType teclado = TextInputType.text,
    TextCapitalization capitalizacion = TextCapitalization.none,
    String? sufijo,
    Color? acento,
    ValueChanged<String>? onCambiar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final bloqueado = _estado != _EstadoPerfil.listo;
    return TextField(
      controller: controller,
      enabled: !bloqueado,
      keyboardType: teclado,
      keyboardAppearance: Brightness.dark,
      textCapitalization: capitalizacion,
      cursorColor: acento ?? tema.primary,
      style: tema.bodyLarge.copyWith(color: tema.primaryText),
      decoration: _decoracionCampo(pista, sufijo: sufijo, acento: acento),
      onChanged: onCambiar,
    );
  }

  Widget _pildoras(
    Map<String, String> opciones,
    String? seleccionado,
    Color acento,
    ValueChanged<String> alElegir,
  ) {
    final tema = FlutterFlowTheme.of(context);
    final bloqueado = _estado != _EstadoPerfil.listo;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones.entries.map((opcion) {
        final activo = opcion.key == seleccionado;
        return GestureDetector(
          onTap: bloqueado ? null : () => alElegir(opcion.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: activo ? _tinte(acento, 0.20) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: activo ? acento : tema.alternate,
                  width: activo ? 1.5 : 1.0),
            ),
            child: Text(
              opcion.value,
              style: tema.bodyMedium.copyWith(
                color: activo ? tema.primaryText : tema.secondaryText,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectorFecha({
    required DateTime? valor,
    required String vacio,
    required VoidCallback alPulsar,
    IconData icono = Icons.calendar_today_rounded,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final bloqueado = _estado != _EstadoPerfil.listo;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: bloqueado ? null : alPulsar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: tema.primaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tema.alternate),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  valor == null ? vacio : _formatearFecha(valor),
                  style: tema.bodyLarge.copyWith(
                    color: valor == null
                        ? _tinte(tema.secondaryText, 0.7)
                        : tema.primaryText,
                  ),
                ),
              ),
              Icon(icono, size: 18, color: tema.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(
      {required String titulo,
      required Color acento,
      required List<Widget> hijos}) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: acento, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(titulo,
                  style: tema.titleSmall.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
            ],
          ),
          ...hijos,
        ],
      ),
    );
  }

  Widget _vistaCargando() {
    final tema = FlutterFlowTheme.of(context);
    return Center(child: CircularProgressIndicator(color: tema.primary));
  }

  Widget _vistaError() {
    final tema = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: tema.error),
            const SizedBox(height: 14),
            Text(_errorCarga ?? '',
                textAlign: TextAlign.center,
                style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.safePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: tema.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaFormulario() {
    final tema = FlutterFlowTheme.of(context);
    final bloqueado = _estado != _EstadoPerfil.listo;
    final ahora = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_tinte(tema.primary, 0.8), tema.primary],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _nombreController.text.trim().isEmpty
                      ? '?'
                      : _nombreController.text.trim()[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              if (_email.isNotEmpty)
                Expanded(
                  child: Text(_email,
                      style:
                          tema.bodyMedium.copyWith(color: tema.secondaryText),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          _tarjeta(titulo: 'Tus datos', acento: tema.primary, hijos: [
            _etiqueta('¿Cómo te llamas?'),
            _campoTexto(_nombreController, 'Tu nombre',
                capitalizacion: TextCapitalization.words),
            _etiqueta('Sexo'),
            _pildoras(_opcionesSexo, _sexo, tema.primary,
                (v) => setState(() => _sexo = v)),
            _etiqueta('Fecha de nacimiento'),
            _selectorFecha(
              valor: _fechaNacimiento,
              vacio: 'Elegir fecha',
              alPulsar: () => _elegirFecha(
                actual: _fechaNacimiento,
                primera: DateTime(ahora.year - 100, 1, 1),
                ultima: DateTime(ahora.year - 14, ahora.month, ahora.day),
                titulo: 'Fecha de nacimiento',
                alElegir: (f) => setState(() => _fechaNacimiento = f),
              ),
            ),
            _etiqueta('Altura y peso'),
            Row(
              children: [
                Expanded(
                  child: _campoTexto(_alturaController, 'Altura',
                      teclado: TextInputType.number, sufijo: 'cm'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoTexto(_pesoController, 'Peso',
                      teclado:
                          const TextInputType.numberWithOptions(decimal: true),
                      sufijo: 'kg'),
                ),
              ],
            ),
          ]),
          _tarjeta(
              titulo: 'Actividad y objetivo',
              acento: tema.tertiary,
              hijos: [
                _etiqueta('Nivel de actividad'),
                _pildoras(_opcionesActividad, _actividad, tema.tertiary,
                    (v) => setState(() => _actividad = v)),
                _etiqueta('Objetivo'),
                _pildoras(_opcionesObjetivo, _objetivo, tema.tertiary,
                    (v) => setState(() => _objetivo = v)),
                _etiqueta('Días de entreno a la semana'),
                _campoTexto(_diasEntrenoController, 'Por ejemplo, 4',
                    teclado: TextInputType.number),
                _etiqueta('Objetivo de pasos diarios'),
                _campoTexto(_objetivoPasosController, 'Por ejemplo, 10000',
                    teclado: TextInputType.number, sufijo: 'pasos'),
                _etiqueta('Fecha objetivo del peso (opcional)'),
                Row(
                  children: [
                    Expanded(
                      child: _selectorFecha(
                        valor: _fechaObjetivoPeso,
                        vacio: 'Sin fecha',
                        icono: Icons.flag_rounded,
                        alPulsar: () => _elegirFecha(
                          actual: _fechaObjetivoPeso,
                          primera: ahora,
                          ultima: DateTime(ahora.year + 5),
                          titulo: 'Fecha objetivo del peso',
                          alElegir: (f) =>
                              setState(() => _fechaObjetivoPeso = f),
                        ),
                      ),
                    ),
                    if (_fechaObjetivoPeso != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: bloqueado
                            ? null
                            : () => setState(() => _fechaObjetivoPeso = null),
                        icon: Icon(Icons.close_rounded,
                            color: tema.secondaryText),
                      ),
                    ],
                  ],
                ),
              ]),
          _tarjeta(titulo: 'Nutrición', acento: tema.secondary, hijos: [
            _etiqueta('¿Cómo pesas los alimentos?'),
            _pildoras(_opcionesPesoAlimentos, _pesoAlimentos, tema.secondary,
                (v) => setState(() => _pesoAlimentos = v)),
          ]),
          _tarjeta(
              titulo: 'Composición corporal',
              acento: tema.tertiary,
              hijos: [
                Text(
                  'Opcional. Estimación con el método de la Marina de EE. UU. a partir de contornos '
                  'con cinta métrica; no sustituye una medición real (DEXA, bioimpedancia...).',
                  style: tema.bodySmall.copyWith(color: tema.secondaryText),
                ),
                _etiqueta('Contorno de cuello'),
                _campoTexto(_cuelloController, 'Por ejemplo, 38',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    sufijo: 'cm',
                    acento: tema.tertiary,
                    onCambiar: (_) => setState(() {})),
                _etiqueta('Contorno de cintura'),
                _campoTexto(_cinturaController, 'A la altura del ombligo',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    sufijo: 'cm',
                    acento: tema.tertiary,
                    onCambiar: (_) => setState(() {})),
                if (_sexo == 'mujer') ...[
                  _etiqueta('Contorno de cadera'),
                  _campoTexto(_caderaController, 'En el punto más ancho',
                      teclado:
                          const TextInputType.numberWithOptions(decimal: true),
                      sufijo: 'cm',
                      acento: tema.tertiary,
                      onCambiar: (_) => setState(() {})),
                ],
                Builder(builder: (context) {
                  final grasa = _calcularGrasaCorporal();
                  if (grasa == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _tinte(tema.tertiary, 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insights_rounded,
                              color: tema.tertiary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Grasa corporal estimada: ${grasa.toStringAsFixed(1)} %',
                              style: tema.bodyMedium.copyWith(
                                  color: tema.primaryText,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
          _tarjeta(titulo: 'Entrenamiento', acento: tema.primary, hijos: [
            _etiqueta('Peso de la barra por defecto'),
            Text(
              'Se usa como referencia al calcular tus levantamientos con barra.',
              style: tema.bodySmall.copyWith(color: tema.secondaryText),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 140,
              child: _campoTexto(_pesoBarraController, '20',
                  teclado: const TextInputType.numberWithOptions(decimal: true),
                  sufijo: 'kg'),
            ),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: bloqueado ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: tema.primary,
              disabledBackgroundColor: _tinte(tema.primary, 0.4),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
                _estado == _EstadoPerfil.guardando
                    ? 'Guardando...'
                    : 'Guardar cambios',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 28),
          Divider(color: tema.alternate),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: bloqueado ? null : _cerrarSesion,
            icon: Icon(Icons.logout_rounded, color: tema.primaryText),
            label: Text('Cerrar sesión',
                style: TextStyle(color: tema.primaryText)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: tema.alternate),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: bloqueado ? null : _eliminarCuenta,
            icon: Icon(
              _estado == _EstadoPerfil.eliminando
                  ? Icons.hourglass_top_rounded
                  : Icons.delete_outline_rounded,
              color: tema.error,
            ),
            label: Text(
              _estado == _EstadoPerfil.eliminando
                  ? 'Eliminando cuenta...'
                  : 'Eliminar cuenta',
              style: TextStyle(color: tema.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _tinte(tema.error, 0.5)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    Widget cuerpo;
    switch (_estado) {
      case _EstadoPerfil.cargando:
        cuerpo = _vistaCargando();
        break;
      case _EstadoPerfil.error:
        cuerpo = _vistaError();
        break;
      default:
        cuerpo = _vistaFormulario();
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: tema.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}
