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

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Si el compilador se queja de que no encuentra 'package:http/http.dart' o
/// 'package:speech_to_text/speech_to_text.dart', añade ambos paquetes en
/// Custom Pub Dependencies (http y speech_to_text), igual que se hizo con
/// flutter_svg.
const String _baseUrlApi =
    'https://dictafit-api-1028761004087.europe-west1.run.app';
const int _maxCaracteresNota = 3000;

enum _Estado {
  cargando,
  error,
  inicio,
  escuchando,
  procesando,
  confirmacion,
  guardando
}

class _SerieEdit {
  double? kg;
  int? reps;
  _SerieEdit({this.kg, this.reps});
}

class _EjercicioEdit {
  String ejercicioId;
  String nombre;
  int inclinacionGrados;
  String cargaPor;
  List<_SerieEdit> series;
  double e1rmKg;
  double ratioPeso;
  String nivel;
  List<Map<String, dynamic>> musculos;

  _EjercicioEdit({
    required this.ejercicioId,
    required this.nombre,
    this.inclinacionGrados = 0,
    this.cargaPor = '',
    List<_SerieEdit>? series,
    this.e1rmKg = 0,
    this.ratioPeso = 0,
    this.nivel = '',
    List<Map<String, dynamic>>? musculos,
  })  : series = series ?? [],
        musculos = musculos ?? [];

  factory _EjercicioEdit.desdeJson(Map<String, dynamic> j) {
    return _EjercicioEdit(
      ejercicioId: (j['ejercicioId'] ?? 'desconocido').toString(),
      nombre: (j['nombre'] ?? 'Ejercicio sin identificar').toString(),
      inclinacionGrados: (j['inclinacionGrados'] as num?)?.toInt() ?? 0,
      cargaPor: (j['cargaPor'] ?? '').toString(),
      series: ((j['series'] as List?) ?? [])
          .map((s) => _SerieEdit(
                kg: (s['kg'] as num?)?.toDouble(),
                reps: (s['reps'] as num?)?.toInt(),
              ))
          .toList(),
      e1rmKg: (j['e1rmKg'] as num?)?.toDouble() ?? 0,
      ratioPeso: (j['ratioPeso'] as num?)?.toDouble() ?? 0,
      nivel: (j['nivel'] ?? '').toString(),
      musculos: ((j['musculos'] as List?) ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(),
    );
  }

  Map<String, dynamic> aPeticion() => {
        'ejercicioId': ejercicioId,
        'nombre': nombre,
        'inclinacionGrados': inclinacionGrados,
        'cargaPor': cargaPor,
        'series': series.map((s) => {'kg': s.kg, 'reps': s.reps}).toList(),
        'e1rmKg': e1rmKg,
        'ratioPeso': ratioPeso,
        'nivel': nivel,
        'musculos': musculos,
      };

  Map<String, dynamic> aFirestore() => {
        'ejercicioId': ejercicioId,
        'nombre': nombre,
        'inclinacionGrados': inclinacionGrados,
        'cargaPor': cargaPor,
        'series': series.map((s) => {'kg': s.kg, 'reps': s.reps}).toList(),
        'e1rmKg': e1rmKg,
        'ratioPeso': ratioPeso,
        'nivel': nivel,
        'musculos': musculos,
      };
}

class _ErrorApi implements Exception {
  final int codigo;
  final String mensaje;
  _ErrorApi(this.codigo, this.mensaje);
}

class _ItemCatalogo {
  final String id;
  final String nombre;
  _ItemCatalogo(this.id, this.nombre);
}

class RegistroEntreno extends StatefulWidget {
  const RegistroEntreno({
    super.key,
    this.width,
    this.height,
    required this.onGuardado,
  });

  final double? width;
  final double? height;

  /// Se llama tras guardar el entreno. Antes de llamarlo, el widget guarda la
  /// referencia del documento creado en FFAppState().entrenoGuardadoRef, para
  /// que la acción de FlutterFlow pueda navegar a WorkoutAnalysis pasándola
  /// como Page Parameter.
  final Future Function() onGuardado;

  @override
  State<RegistroEntreno> createState() => _RegistroEntrenoState();
}

class _RegistroEntrenoState extends State<RegistroEntreno> {
  final stt.SpeechToText _voz = stt.SpeechToText();
  bool _vozCapaz = false; // el dispositivo admite dictado por voz
  bool _prefiereTexto = false; // el usuario ha elegido escribir en su lugar
  String _localeVoz = 'es_ES';

  /// Si hay que mostrar el micrófono ahora mismo (capacidad + preferencia).
  bool get _vozDisponible => _vozCapaz && !_prefiereTexto;

  _Estado _estado = _Estado.cargando;
  String? _errorCarga;

  double _pesoCorporalKg = 0;
  String _sexo = 'hombre';

  List<_ItemCatalogo> _catalogo = [];

  final TextEditingController _controladorTexto = TextEditingController();
  String _textoEscuchado = '';
  Timer? _cronometro;
  int _segundosEscucha = 0;

  /// Estado al que se vuelve tras escuchar: 'inicio' en el primer dictado,
  /// 'confirmacion' cuando el usuario pulsa "Dictar más" desde la revisión.
  _Estado _estadoPrevioEscucha = _Estado.inicio;
  bool _guardandoAhora = false;

  String _transcripcion = '';
  List<_EjercicioEdit> _ejercicios = [];
  List<String> _avisos = [];
  int? _notasRestantes;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _voz.stop();
    _controladorTexto.dispose();
    super.dispose();
  }

  // ---------- Carga inicial ----------

  Future<void> _cargarTodo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _estado = _Estado.error;
          _errorCarga = 'Tu sesión ha caducado. Vuelve a iniciar sesión.';
        });
        return;
      }
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final datos = doc.data() ?? {};
      final peso = (datos['pesoKg'] as num?)?.toDouble() ?? 0;
      final sexo = (datos['sexo'] ?? 'hombre').toString();

      if (peso <= 0) {
        setState(() {
          _estado = _Estado.error;
          _errorCarga =
              'Completa tu perfil (peso corporal) antes de registrar un entreno.';
        });
        return;
      }

      _pesoCorporalKg = peso;
      _sexo = sexo == 'mujer' ? 'mujer' : 'hombre';

      unawaited(_inicializarVoz());
      unawaited(_cargarCatalogo());

      if (mounted) setState(() => _estado = _Estado.inicio);
    } catch (_) {
      if (mounted) {
        setState(() {
          _estado = _Estado.error;
          _errorCarga = 'No se ha podido cargar tu perfil. Inténtalo de nuevo.';
        });
      }
    }
  }

  Future<void> _inicializarVoz() async {
    final capaz = await _intentarInicializarVoz();
    if (mounted) setState(() => _vozCapaz = capaz);
  }

  Future<bool> _intentarInicializarVoz({bool esReintento = false}) async {
    try {
      final disponible = await _voz.initialize(
        onStatus: _alCambiarEstadoVoz,
        onError: (e) => _finalizarEscucha(),
      );
      if (!disponible) {
        // Algunos dispositivos tardan un momento en tener listo el motor de
        // voz la primera vez; se reintenta una sola vez tras una pausa breve.
        if (!esReintento) {
          await Future.delayed(const Duration(milliseconds: 600));
          return _intentarInicializarVoz(esReintento: true);
        }
        return false;
      }
      final locales = await _voz.locales();
      final esp =
          locales.where((l) => l.localeId.toLowerCase().startsWith('es'));
      if (esp.isNotEmpty) _localeVoz = esp.first.localeId;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cargarCatalogo() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      final resp = await http.get(
        Uri.parse('$_baseUrlApi/v1/ejercicios'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final lista = (json['ejercicios'] as List?) ?? [];
      final catalogo = lista
          .map((e) => _ItemCatalogo(
              (e['id'] ?? '').toString(), (e['nombre'] ?? '').toString()))
          .where((e) => e.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      if (mounted) setState(() => _catalogo = catalogo);
    } catch (_) {
      // Sin catálogo, el selector de ejercicio quedará limitado; no es bloqueante.
    }
  }

  void _alCambiarEstadoVoz(String status) {
    if ((status == 'done' || status == 'notListening') &&
        _estado == _Estado.escuchando) {
      _finalizarEscucha();
    }
  }

  // ---------- Dictado ----------

  void _empezarEscucha() {
    _estadoPrevioEscucha = _estado; // inicio o confirmacion (al dictar más)
    setState(() {
      _estado = _Estado.escuchando;
      _textoEscuchado = '';
      _segundosEscucha = 0;
    });
    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundosEscucha++);
    });
    _voz.listen(
      onResult: (r) {
        if (mounted) setState(() => _textoEscuchado = r.recognizedWords);
      },
      localeId: _localeVoz,
      listenFor: const Duration(minutes: 4),
      pauseFor: const Duration(seconds: 6),
      partialResults: true,
      cancelOnError: true,
    );
  }

  void _finalizarEscucha() {
    _cronometro?.cancel();
    _voz.stop();
    if (!mounted) return;
    final texto = _textoEscuchado.trim();
    if (texto.isEmpty) {
      setState(() => _estado = _estadoPrevioEscucha);
      return;
    }
    _procesar(texto);
  }

  void _cancelarEscucha() {
    _cronometro?.cancel();
    _voz.cancel();
    setState(() {
      _estado = _estadoPrevioEscucha;
      _textoEscuchado = '';
    });
  }

  /// Alternativa a dictar cuando el reconocimiento de voz no está disponible
  /// (p. ej. test mode) y el usuario quiere añadir más ejercicios a mano.
  Future<void> _dictarMasTexto() async {
    final tema = FlutterFlowTheme.of(context);
    final controlador = TextEditingController();
    final texto = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tema.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Añadir más ejercicios',
                style: tema.titleMedium.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controlador,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              style: TextStyle(color: tema.primaryText),
              decoration: InputDecoration(
                hintText: 'Por ejemplo: sentadilla 3 series de 10 con 60 kilos',
                hintStyle: TextStyle(color: tema.secondaryText),
                filled: true,
                fillColor: tema.primaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tema.alternate),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _botonPrincipal(
                'Añadir', () => Navigator.of(ctx).pop(controlador.text.trim())),
          ],
        ),
      ),
    );
    if (texto == null || texto.isEmpty) return;
    _estadoPrevioEscucha = _Estado.confirmacion;
    _procesar(texto);
  }

  // ---------- Llamadas al backend ----------

  Future<Map<String, dynamic>> _llamarBackend(
      String ruta, Map<String, dynamic> cuerpo) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null)
      throw _ErrorApi(401, 'Tu sesión ha caducado. Vuelve a iniciar sesión.');
    final token = await usuario.getIdToken();
    late final http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse('$_baseUrlApi$ruta'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw _ErrorApi(0, 'No se ha podido conectar. Comprueba tu conexión.');
    }
    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (resp.statusCode != 200) {
      throw _ErrorApi(
          resp.statusCode,
          (json['detail'] ?? 'Ha ocurrido un error. Inténtalo de nuevo.')
              .toString());
    }
    return json;
  }

  Future<void> _procesar(String texto) async {
    final anadiendo = _estadoPrevioEscucha == _Estado.confirmacion;

    if (texto.length > _maxCaracteresNota) {
      setState(() => _estado = _estadoPrevioEscucha);
      _mostrarError(
          'La nota es demasiado larga. Divide el entreno en varias notas.');
      return;
    }
    setState(() => _estado = _Estado.procesando);
    try {
      final json = await _llamarBackend('/v1/entreno/procesar', {
        'texto': texto,
        'pesoCorporalKg': _pesoCorporalKg,
        'sexo': _sexo,
      });
      final ejerciciosNuevos = ((json['ejercicios'] as List?) ?? [])
          .map((e) =>
              _EjercicioEdit.desdeJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final avisosNuevos =
          ((json['avisos'] as List?) ?? []).map((a) => a.toString()).toList();
      final transcripcionNueva = (json['transcripcion'] ?? texto).toString();

      setState(() {
        if (anadiendo) {
          _ejercicios = [..._ejercicios, ...ejerciciosNuevos];
          _transcripcion = '$_transcripcion  ·  $transcripcionNueva';
        } else {
          _ejercicios = ejerciciosNuevos;
          _transcripcion = transcripcionNueva;
        }
        _avisos = avisosNuevos;
        _notasRestantes =
            (json['notasRestantes'] as num?)?.toInt() ?? _notasRestantes;
        _estado = _Estado.confirmacion;
      });
    } on _ErrorApi catch (e) {
      setState(() => _estado = _estadoPrevioEscucha);
      _mostrarError(e.mensaje);
    } catch (_) {
      setState(() => _estado = _estadoPrevioEscucha);
      _mostrarError('Ha ocurrido un error. Inténtalo de nuevo.');
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardandoAhora = true);
    try {
      final json = await _llamarBackend('/v1/entreno/calcular', {
        'pesoCorporalKg': _pesoCorporalKg,
        'sexo': _sexo,
        'ejercicios': _ejercicios.map((e) => e.aPeticion()).toList(),
      });
      final recalculados = ((json['ejercicios'] as List?) ?? [])
          .map((e) =>
              _EjercicioEdit.desdeJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final avisos =
          ((json['avisos'] as List?) ?? []).map((a) => a.toString()).toList();

      if (!mounted) return;
      setState(() {
        _ejercicios = recalculados;
        _avisos = avisos;
      });

      if (avisos.isNotEmpty) {
        final continuar = await _confirmarPeseALosAvisos(avisos);
        if (continuar != true) {
          setState(() => _guardandoAhora = false);
          return;
        }
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final referencia = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entrenos')
          .add({
        'fecha': FieldValue.serverTimestamp(),
        'transcripcion': _transcripcion,
        'pesoCorporalKg': _pesoCorporalKg,
        'ejercicios': recalculados.map((e) => e.aFirestore()).toList(),
      });

      FFAppState().update(() {
        FFAppState().entrenoGuardadoRef = referencia;
      });

      await widget.onGuardado();
    } on _ErrorApi catch (e) {
      if (mounted) _mostrarError(e.mensaje);
    } catch (_) {
      if (mounted)
        _mostrarError(
            'No se ha podido guardar el entreno. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _guardandoAhora = false);
    }
  }

  Future<bool?> _confirmarPeseALosAvisos(List<String> avisos) {
    final tema = FlutterFlowTheme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: tema.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Todavía faltan algunos datos',
                  style: tema.titleMedium.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...avisos.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 18, color: tema.warning),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(a,
                                style: tema.bodySmall
                                    .copyWith(color: tema.secondaryText))),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tema.primaryText,
                  side: BorderSide(color: tema.alternate),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Seguir editando'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tema.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Guardar igualmente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    final tema = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tema.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.error),
      ),
      content: Text(mensaje,
          style: tema.bodyMedium.copyWith(color: tema.primaryText)),
    ));
  }

  // ---------- Edición de ejercicios ----------

  void _agregarSerie(int indiceEjercicio) {
    setState(() => _ejercicios[indiceEjercicio].series.add(_SerieEdit()));
  }

  void _borrarSerie(int indiceEjercicio, int indiceSerie) {
    setState(() => _ejercicios[indiceEjercicio].series.removeAt(indiceSerie));
  }

  void _borrarEjercicio(int indice) {
    setState(() => _ejercicios.removeAt(indice));
  }

  void _agregarEjercicioVacio() {
    setState(() => _ejercicios.add(
        _EjercicioEdit(ejercicioId: 'desconocido', nombre: 'Nuevo ejercicio')));
  }

  Future<void> _elegirEjercicio(int indice) async {
    final tema = FlutterFlowTheme.of(context);
    final controlador = TextEditingController();
    String filtro = '';

    final elegido = await showModalBottomSheet<_ItemCatalogo?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tema.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final filtrados = _catalogo
              .where(
                  (e) => e.nombre.toLowerCase().contains(filtro.toLowerCase()))
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Elegir ejercicio',
                      style: tema.titleMedium.copyWith(
                          color: tema.primaryText,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controlador,
                    style: TextStyle(color: tema.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(color: tema.secondaryText),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: tema.secondaryText),
                      filled: true,
                      fillColor: tema.primaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setSheet(() => filtro = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 320,
                    child: _catalogo.isEmpty
                        ? Center(
                            child: Text('No se ha podido cargar el catálogo.',
                                style: tema.bodySmall
                                    .copyWith(color: tema.secondaryText)))
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (ctx, i) {
                              final item = filtrados[i];
                              return ListTile(
                                title: Text(item.nombre,
                                    style: tema.bodyMedium
                                        .copyWith(color: tema.primaryText)),
                                onTap: () => Navigator.of(ctx).pop(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (elegido != null) {
      setState(() {
        _ejercicios[indice].ejercicioId = elegido.id;
        _ejercicios[indice].nombre = elegido.nombre;
      });
    }
  }

  // ---------- Utilidades visuales ----------

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  String _tiempo(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _cabecera(String titulo, {bool conCerrar = true}) {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          if (conCerrar)
            IconButton(
              onPressed: _confirmarSalida,
              icon:
                  Icon(Icons.close_rounded, color: tema.primaryText, size: 22),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.titleLarge.copyWith(
                  color: tema.primaryText, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Future<void> _confirmarSalida() async {
    if (_estado == _Estado.inicio ||
        _estado == _Estado.cargando ||
        _estado == _Estado.error) {
      context.safePop();
      return;
    }
    final tema = FlutterFlowTheme.of(context);
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tema.secondaryBackground,
        title: Text('¿Descartar entreno?',
            style: TextStyle(color: tema.primaryText)),
        content: Text('Se perderá lo que has dictado.',
            style: TextStyle(color: tema.secondaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Seguir', style: TextStyle(color: tema.primary))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Descartar', style: TextStyle(color: tema.error))),
        ],
      ),
    );
    if (salir == true) {
      _voz.cancel();
      context.safePop();
    }
  }

  Widget _botonPrincipal(String texto, VoidCallback? onPulsar,
      {bool relleno = true}) {
    final tema = FlutterFlowTheme.of(context);
    if (relleno) {
      return ElevatedButton(
        onPressed: onPulsar,
        style: ElevatedButton.styleFrom(
          backgroundColor: tema.primary,
          disabledBackgroundColor: _tinte(tema.primary, 0.4),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton(
      onPressed: onPulsar,
      style: OutlinedButton.styleFrom(
        foregroundColor: tema.primaryText,
        side: BorderSide(color: tema.alternate),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(texto),
    );
  }

  // ---------- Pantallas por estado ----------

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
            _botonPrincipal('Volver', () => context.safePop()),
          ],
        ),
      ),
    );
  }

  Widget _vistaInicio() {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_rounded,
                    size: 40, color: tema.primary),
                const SizedBox(height: 16),
                Text('Dicta tu entreno',
                    style: tema.titleLarge.copyWith(
                        color: tema.primaryText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _vozDisponible
                      ? 'Toca el micrófono y di los ejercicios, las series, los kilos y las repeticiones.'
                      : 'El dictado por voz no está disponible en este dispositivo. Escribe tu entreno.',
                  textAlign: TextAlign.center,
                  style: tema.bodyMedium.copyWith(color: tema.secondaryText),
                ),
                const SizedBox(height: 32),
                if (_vozDisponible)
                  GestureDetector(
                    onTap: _empezarEscucha,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_tinte(tema.primary, 0.8), tema.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: _tinte(tema.primary, 0.5),
                              blurRadius: 22,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 42),
                    ),
                  ),
              ],
            ),
          ),
          if (_vozDisponible) ...[
            TextButton(
              onPressed: () => setState(() => _prefiereTexto = true),
              child: Text('Escribir en su lugar',
                  style: TextStyle(
                      color: tema.secondaryText,
                      decoration: TextDecoration.underline)),
            ),
          ] else ...[
            if (_vozCapaz) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _prefiereTexto = false),
                  child: Text('Probar con el micrófono',
                      style: TextStyle(
                          color: tema.primary,
                          decoration: TextDecoration.underline)),
                ),
              ),
              const SizedBox(height: 4),
            ],
            TextField(
              controller: _controladorTexto,
              maxLines: 4,
              minLines: 3,
              style: TextStyle(color: tema.primaryText),
              decoration: InputDecoration(
                hintText:
                    'Por ejemplo: press de banca 4 series de 8 con 80 kilos...',
                hintStyle: TextStyle(color: tema.secondaryText),
                filled: true,
                fillColor: tema.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: tema.alternate),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _botonPrincipal('Continuar', () {
              final texto = _controladorTexto.text.trim();
              if (texto.isEmpty) return;
              _procesar(texto);
            }),
          ],
        ],
      ),
    );
  }

  Widget _vistaEscuchando() {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _tinte(tema.error, 0.15),
                  ),
                  child: Icon(Icons.mic_rounded, color: tema.error, size: 40),
                ),
                const SizedBox(height: 14),
                Text(_tiempo(_segundosEscucha),
                    style: tema.titleLarge.copyWith(
                        color: tema.primaryText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tema.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tema.alternate),
                  ),
                  child: Text(
                    _textoEscuchado.isEmpty ? 'Te escucho...' : _textoEscuchado,
                    style: tema.bodyMedium.copyWith(
                      color: _textoEscuchado.isEmpty
                          ? tema.secondaryText
                          : tema.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: _botonPrincipal('Cancelar', _cancelarEscucha,
                      relleno: false)),
              const SizedBox(width: 12),
              Expanded(child: _botonPrincipal('Listo', _finalizarEscucha)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vistaProcesando() {
    final tema = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: tema.primary),
          const SizedBox(height: 16),
          Text('Interpretando tu entreno...',
              style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
        ],
      ),
    );
  }

  Widget _filaSerie(int indiceEjercicio, int indiceSerie, _SerieEdit serie) {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('${indiceSerie + 1}',
              style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          const SizedBox(width: 10),
          Expanded(
            child: _campoNumero(
              valor: serie.kg,
              sufijo: 'kg',
              onCambiar: (v) => serie.kg = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _campoNumero(
              valor: serie.reps?.toDouble(),
              sufijo: 'reps',
              onCambiar: (v) => serie.reps = v?.toInt(),
            ),
          ),
          IconButton(
            onPressed: () => _borrarSerie(indiceEjercicio, indiceSerie),
            icon:
                Icon(Icons.close_rounded, size: 18, color: tema.secondaryText),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _campoNumero({
    required double? valor,
    required String sufijo,
    required ValueChanged<double?> onCambiar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return TextFormField(
      initialValue: valor == null
          ? ''
          : (valor == valor.roundToDouble()
              ? valor.toInt().toString()
              : valor.toString()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: tema.bodyMedium.copyWith(color: tema.primaryText),
      decoration: InputDecoration(
        isDense: true,
        suffixText: sufijo,
        suffixStyle: tema.bodySmall.copyWith(color: tema.secondaryText),
        filled: true,
        fillColor: tema.primaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tema.alternate),
        ),
      ),
      onChanged: (texto) {
        final normalizado = texto.replaceAll(',', '.');
        onCambiar(normalizado.isEmpty ? null : double.tryParse(normalizado));
      },
    );
  }

  Widget _tarjetaEjercicio(int indice) {
    final tema = FlutterFlowTheme.of(context);
    final ejercicio = _ejercicios[indice];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _elegirEjercicio(indice),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ejercicio.nombre,
                          style: tema.titleSmall.copyWith(
                              color: tema.primaryText,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.edit_rounded,
                          size: 16, color: tema.secondaryText),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _borrarEjercicio(indice),
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: tema.error),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (ejercicio.ejercicioId == 'desconocido')
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                  'Sin identificar. Toca el nombre para elegir el ejercicio correcto.',
                  style: tema.bodySmall.copyWith(color: tema.warning)),
            ),
          const SizedBox(height: 10),
          ...ejercicio.series
              .asMap()
              .entries
              .map((e) => _filaSerie(indice, e.key, e.value)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _agregarSerie(indice),
              icon: Icon(Icons.add_rounded, size: 18, color: tema.primary),
              label: Text('Serie', style: TextStyle(color: tema.primary)),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaConfirmacion() {
    final tema = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('"$_transcripcion"',
                      style: tema.bodySmall.copyWith(
                          color: tema.secondaryText,
                          fontStyle: FontStyle.italic)),
                ),
                if (_avisos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _tinte(tema.warning, 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _avisos
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $a',
                                    style: tema.bodySmall
                                        .copyWith(color: tema.primaryText)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ..._ejercicios.asMap().keys.map((i) => _tarjetaEjercicio(i)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed:
                            _vozDisponible ? _empezarEscucha : _dictarMasTexto,
                        icon: Icon(
                            _vozDisponible
                                ? Icons.mic_rounded
                                : Icons.edit_note_rounded,
                            color: tema.primary),
                        label: Text('Dictar más',
                            style: TextStyle(color: tema.primary)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _agregarEjercicioVacio,
                        icon: Icon(Icons.add_circle_outline_rounded,
                            color: tema.secondaryText),
                        label: Text('Añadir manual',
                            style: TextStyle(color: tema.secondaryText)),
                      ),
                    ),
                  ],
                ),
                if (_notasRestantes != null) ...[
                  const SizedBox(height: 4),
                  Text('Te quedan $_notasRestantes notas hoy.',
                      style:
                          tema.bodySmall.copyWith(color: tema.secondaryText)),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _botonPrincipal('Descartar',
                    _guardandoAhora ? null : () => context.safePop(),
                    relleno: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _botonPrincipal(
                  _guardandoAhora ? 'Guardando...' : 'Guardar entreno',
                  (_guardandoAhora || _ejercicios.isEmpty) ? null : _guardar,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    Widget cuerpo;
    String titulo = 'Registrar entreno';
    switch (_estado) {
      case _Estado.cargando:
        cuerpo = _vistaCargando();
        break;
      case _Estado.error:
        cuerpo = _vistaError();
        break;
      case _Estado.inicio:
        cuerpo = _vistaInicio();
        break;
      case _Estado.escuchando:
        titulo = 'Escuchando...';
        cuerpo = _vistaEscuchando();
        break;
      case _Estado.procesando:
        cuerpo = _vistaProcesando();
        break;
      case _Estado.confirmacion:
        titulo = 'Revisa tu entreno';
        cuerpo = _vistaConfirmacion();
        break;
      case _Estado.guardando:
        cuerpo = _vistaProcesando();
        break;
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: tema.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            _cabecera(titulo),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}
