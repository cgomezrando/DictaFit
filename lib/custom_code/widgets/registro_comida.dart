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
/// Custom Pub Dependencies, igual que en RegistroEntreno.
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

class _AlimentoEdit {
  String alimentoId;
  String nombre;
  double gramos;
  double kcal100;
  double proteina100;
  double carbos100;
  double grasa100;
  double kcal;
  double proteinaG;
  double carbosG;
  double grasaG;
  bool supuesto;
  String notaSupuesto;

  _AlimentoEdit({
    required this.alimentoId,
    required this.nombre,
    this.gramos = 0,
    this.kcal100 = 0,
    this.proteina100 = 0,
    this.carbos100 = 0,
    this.grasa100 = 0,
    this.kcal = 0,
    this.proteinaG = 0,
    this.carbosG = 0,
    this.grasaG = 0,
    this.supuesto = false,
    this.notaSupuesto = '',
  });

  factory _AlimentoEdit.desdeJson(Map<String, dynamic> j) {
    return _AlimentoEdit(
      alimentoId: (j['alimentoId'] ?? 'desconocido').toString(),
      nombre: (j['nombre'] ?? 'Alimento sin identificar').toString(),
      gramos: (j['gramos'] as num?)?.toDouble() ?? 0,
      kcal100: (j['kcal100'] as num?)?.toDouble() ?? 0,
      proteina100: (j['proteina100'] as num?)?.toDouble() ?? 0,
      carbos100: (j['carbos100'] as num?)?.toDouble() ?? 0,
      grasa100: (j['grasa100'] as num?)?.toDouble() ?? 0,
      kcal: (j['kcal'] as num?)?.toDouble() ?? 0,
      proteinaG: (j['proteinaG'] as num?)?.toDouble() ?? 0,
      carbosG: (j['carbosG'] as num?)?.toDouble() ?? 0,
      grasaG: (j['grasaG'] as num?)?.toDouble() ?? 0,
      supuesto: j['supuesto'] == true,
      notaSupuesto: (j['notaSupuesto'] ?? '').toString(),
    );
  }

  Map<String, dynamic> aPeticion() => {
        'alimentoId': alimentoId,
        'nombre': nombre,
        'gramos': gramos,
        'kcal100': kcal100,
        'proteina100': proteina100,
        'carbos100': carbos100,
        'grasa100': grasa100,
        'kcal': kcal,
        'proteinaG': proteinaG,
        'carbosG': carbosG,
        'grasaG': grasaG,
        'supuesto': supuesto,
        'notaSupuesto': notaSupuesto,
      };

  Map<String, dynamic> aFirestore() => aPeticion();
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

class RegistroComida extends StatefulWidget {
  const RegistroComida({
    super.key,
    this.width,
    this.height,
    required this.onGuardado,
  });

  final double? width;
  final double? height;

  /// Se llama tras marcar la sesión de comida como completa. La acción de
  /// FlutterFlow puede simplemente volver a Home (Replace Route); todavía
  /// no hay una pantalla de análisis nutricional a la que navegar.
  final Future Function() onGuardado;

  @override
  State<RegistroComida> createState() => _RegistroComidaState();
}

class _RegistroComidaState extends State<RegistroComida> {
  final stt.SpeechToText _voz = stt.SpeechToText();
  bool _vozCapaz = false; // el dispositivo admite dictado por voz
  bool _prefiereTexto = false; // el usuario ha elegido escribir en su lugar
  String _localeVoz = 'es_ES';

  /// Si hay que mostrar el micrófono ahora mismo (capacidad + preferencia).
  bool get _vozDisponible => _vozCapaz && !_prefiereTexto;

  _Estado _estado = _Estado.cargando;
  String? _errorCarga;

  /// 'crudo' o 'cocinado', de Perfil. Decide qué variante del catálogo usar
  /// por defecto cuando un alimento tiene las dos.
  String _pesoAlimentos = 'cocinado';

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
  List<_AlimentoEdit> _alimentos = [];

  /// Documento de la comida abierta (si ya existía una al entrar, o la que
  /// se crea al primer guardado). Null hasta que se guarda por primera vez.
  DocumentReference? _comidaAbiertaRef;

  /// Foto de _alimentos/_transcripcion en el último guardado con éxito, para
  /// saber si hay cambios sin guardar y no preguntar "¿salir?" sin motivo.
  String? _ultimoGuardadoSerializado;

  String _serializarEstado() => jsonEncode({
        't': _transcripcion,
        'a': _alimentos.map((a) => a.aFirestore()).toList()
      });

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
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await userRef.get();
      final datos = doc.data() ?? {};
      final pesoAlimentos = (datos['pesoAlimentos'] ?? 'cocinado').toString();
      _pesoAlimentos = pesoAlimentos == 'crudo' ? 'crudo' : 'cocinado';

      _Estado estadoInicial = _Estado.inicio;

      // Un usuario solo tiene, como mucho, una comida abierta a la vez: si
      // existe, seguimos añadiendo a ella en vez de empezar una nueva. Se
      // busca solo por igualdad (sin orderBy) para no necesitar un índice
      // compuesto en Firestore.
      final abiertas = await userRef
          .collection('comidas')
          .where('estado', isEqualTo: 'abierto')
          .limit(1)
          .get();

      if (abiertas.docs.isNotEmpty) {
        final comidaDoc = abiertas.docs.first;
        _comidaAbiertaRef = comidaDoc.reference;
        final datosComida = comidaDoc.data();
        _transcripcion = (datosComida['transcripcion'] ?? '').toString();
        _alimentos = ((datosComida['alimentos'] as List?) ?? [])
            .whereType<Map>()
            .map((a) => _AlimentoEdit.desdeJson(Map<String, dynamic>.from(a)))
            .toList();
        estadoInicial = _Estado.confirmacion;
        _ultimoGuardadoSerializado = _serializarEstado();
      }

      unawaited(_inicializarVoz());
      unawaited(_cargarCatalogo());

      if (mounted) setState(() => _estado = estadoInicial);
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
        Uri.parse('$_baseUrlApi/v1/alimentos'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final lista = (json['alimentos'] as List?) ?? [];
      final catalogo = lista
          .map((a) => _ItemCatalogo(
              (a['id'] ?? '').toString(), (a['nombre'] ?? '').toString()))
          .where((a) => a.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      if (mounted) setState(() => _catalogo = catalogo);
    } catch (_) {
      // Sin catálogo, el selector de alimento quedará limitado; no es bloqueante.
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
      pauseFor: const Duration(seconds: 45),
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
  /// (p. ej. test mode) y el usuario quiere añadir más comida a mano.
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
            Text('Añadir más comida',
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
                hintText:
                    'Por ejemplo: 150 gramos de arroz con pechuga de pollo a la plancha',
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
      _mostrarMensaje(
          'La nota es demasiado larga. Divide la comida en varias notas.');
      return;
    }
    setState(() => _estado = _Estado.procesando);
    try {
      final json = await _llamarBackend('/v1/comida/procesar', {
        'texto': texto,
        'pesoAlimentos': _pesoAlimentos,
      });
      final alimentosNuevos = ((json['alimentos'] as List?) ?? [])
          .map((a) =>
              _AlimentoEdit.desdeJson(Map<String, dynamic>.from(a as Map)))
          .toList();
      final avisosNuevos =
          ((json['avisos'] as List?) ?? []).map((a) => a.toString()).toList();
      final transcripcionNueva = (json['transcripcion'] ?? texto).toString();

      setState(() {
        if (anadiendo) {
          // A diferencia de los ejercicios, aquí no se fusionan alimentos
          // repetidos: si dictas "manzana" dos veces en momentos distintos,
          // son casi seguro dos manzanas distintas a lo largo del día.
          _alimentos.addAll(alimentosNuevos);
          _transcripcion = '$_transcripcion  ·  $transcripcionNueva';
        } else {
          _alimentos = alimentosNuevos;
          _transcripcion = transcripcionNueva;
        }
        _avisos = avisosNuevos;
        _notasRestantes =
            (json['notasRestantes'] as num?)?.toInt() ?? _notasRestantes;
        _estado = _Estado.confirmacion;
      });
    } on _ErrorApi catch (e) {
      setState(() => _estado = _estadoPrevioEscucha);
      _mostrarMensaje(e.mensaje);
    } catch (_) {
      setState(() => _estado = _estadoPrevioEscucha);
      _mostrarMensaje('Ha ocurrido un error. Inténtalo de nuevo.');
    }
  }

  Future<void> _guardar({required bool completar}) async {
    setState(() => _guardandoAhora = true);
    try {
      final json = await _llamarBackend('/v1/comida/calcular', {
        'alimentos': _alimentos.map((a) => a.aPeticion()).toList(),
      });
      final recalculados = ((json['alimentos'] as List?) ?? [])
          .map((a) =>
              _AlimentoEdit.desdeJson(Map<String, dynamic>.from(a as Map)))
          .toList();
      final avisos =
          ((json['avisos'] as List?) ?? []).map((a) => a.toString()).toList();

      if (!mounted) return;
      setState(() {
        _alimentos = recalculados;
        _avisos = avisos;
      });

      if (avisos.isNotEmpty) {
        final continuar = await _confirmarPeseALosAvisos(avisos);
        if (continuar != true) {
          if (mounted) setState(() => _guardandoAhora = false);
          return;
        }
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final datosComida = {
        'transcripcion': _transcripcion,
        'alimentos': recalculados.map((a) => a.aFirestore()).toList(),
        'kcal': recalculados.fold(0.0, (s, a) => s + a.kcal),
        'proteinaG': recalculados.fold(0.0, (s, a) => s + a.proteinaG),
        'carbosG': recalculados.fold(0.0, (s, a) => s + a.carbosG),
        'grasaG': recalculados.fold(0.0, (s, a) => s + a.grasaG),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
        'estado': completar ? 'completo' : 'abierto',
        if (completar) 'fechaCompletado': FieldValue.serverTimestamp(),
      };

      if (_comidaAbiertaRef == null) {
        final nueva = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('comidas')
            .add({...datosComida, 'fecha': FieldValue.serverTimestamp()});
        if (!completar) _comidaAbiertaRef = nueva;
      } else {
        await _comidaAbiertaRef!.set(datosComida, SetOptions(merge: true));
        if (completar) _comidaAbiertaRef = null;
      }

      if (!completar) {
        if (!mounted) return;
        _ultimoGuardadoSerializado = _serializarEstado();
        setState(() => _guardandoAhora = false);
        _mostrarMensaje(
            'Guardado. Puedes seguir añadiendo comida cuando quieras.',
            esError: false);
        return;
      }

      await widget.onGuardado();
    } on _ErrorApi catch (e) {
      if (mounted) {
        setState(() => _guardandoAhora = false);
        _mostrarMensaje(e.mensaje);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _guardandoAhora = false);
        _mostrarMensaje(
            'No se ha podido guardar la comida. Inténtalo de nuevo.');
      }
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

  // ---------- Edición de alimentos ----------

  void _borrarAlimento(int indice) {
    setState(() => _alimentos.removeAt(indice));
  }

  void _agregarAlimentoVacio() {
    setState(() => _alimentos.add(_AlimentoEdit(
        alimentoId: 'desconocido', nombre: 'Nuevo alimento', gramos: 100)));
  }

  Future<void> _elegirAlimento(int indice) async {
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
                  (a) => a.nombre.toLowerCase().contains(filtro.toLowerCase()))
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
                  Text('Elegir alimento',
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
        _alimentos[indice].alimentoId = elegido.id;
        _alimentos[indice].nombre = elegido.nombre;
      });
    }
  }

  // ---------- Utilidades visuales ----------

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  String _numeroCorto(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

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
    final sinCambios = _estado == _Estado.inicio ||
        _estado == _Estado.cargando ||
        _estado == _Estado.error ||
        _serializarEstado() == _ultimoGuardadoSerializado;
    if (sinCambios) {
      context.safePop();
      return;
    }
    final tema = FlutterFlowTheme.of(context);
    final salir = await showModalBottomSheet<bool>(
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: tema.alternate,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text('Tienes cambios sin guardar',
                  style: tema.titleMedium.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Si sales ahora, se perderá lo que no hayas guardado.',
                  style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tema.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continuar en la comida'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tema.error,
                  side: BorderSide(color: _tinte(tema.error, 0.5)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Salir sin guardar'),
              ),
            ],
          ),
        ),
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
          backgroundColor: tema.secondary,
          disabledBackgroundColor: _tinte(tema.secondary, 0.4),
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
                Icon(Icons.eco_rounded, size: 40, color: tema.secondary),
                const SizedBox(height: 16),
                Text('Dicta lo que has comido',
                    style: tema.titleLarge.copyWith(
                        color: tema.primaryText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _vozDisponible
                      ? 'Toca el micrófono y di los alimentos y, si lo sabes, la cantidad.'
                      : 'El dictado por voz no está disponible en este dispositivo. Escribe lo que has comido.',
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
                          colors: [_tinte(tema.secondary, 0.8), tema.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: _tinte(tema.secondary, 0.5),
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
                          color: tema.secondary,
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
                    'Por ejemplo: 150 gramos de arroz con pechuga de pollo a la plancha...',
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
          CircularProgressIndicator(color: tema.secondary),
          const SizedBox(height: 16),
          Text('Interpretando lo que has comido...',
              style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
        ],
      ),
    );
  }

  Widget _campoGramos(int indice) {
    final tema = FlutterFlowTheme.of(context);
    final alimento = _alimentos[indice];
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: alimento.gramos == 0 ? '' : _numeroCorto(alimento.gramos),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: tema.bodyMedium.copyWith(color: tema.primaryText),
        decoration: InputDecoration(
          isDense: true,
          suffixText: 'g',
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
          alimento.gramos = double.tryParse(normalizado) ?? 0;
        },
      ),
    );
  }

  Widget _tarjetaAlimento(int indice) {
    final tema = FlutterFlowTheme.of(context);
    final alimento = _alimentos[indice];
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
                  onTap: () => _elegirAlimento(indice),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          alimento.nombre,
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
                onPressed: () => _borrarAlimento(indice),
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: tema.error),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (alimento.supuesto)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                alimento.notaSupuesto.isEmpty
                    ? 'Cantidad o alimento estimados.'
                    : '${alimento.notaSupuesto[0].toUpperCase()}${alimento.notaSupuesto.substring(1)}.',
                style: tema.bodySmall.copyWith(color: tema.warning),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _campoGramos(indice),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_numeroCorto(alimento.kcal)} kcal  ·  P ${_numeroCorto(alimento.proteinaG)}  ·  '
                  'C ${_numeroCorto(alimento.carbosG)}  ·  G ${_numeroCorto(alimento.grasaG)}',
                  style: tema.bodySmall.copyWith(color: tema.secondaryText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenTotales() {
    final tema = FlutterFlowTheme.of(context);
    final kcal = _alimentos.fold(0.0, (s, a) => s + a.kcal);
    final proteina = _alimentos.fold(0.0, (s, a) => s + a.proteinaG);
    final carbos = _alimentos.fold(0.0, (s, a) => s + a.carbosG);
    final grasa = _alimentos.fold(0.0, (s, a) => s + a.grasaG);

    Widget dato(String etiqueta, double valor) {
      return Expanded(
        child: Column(
          children: [
            Text(_numeroCorto(valor),
                style: tema.titleMedium.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
            Text(etiqueta,
                style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _tinte(tema.secondary, 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _tinte(tema.secondary, 0.35)),
      ),
      child: Row(
        children: [
          dato('kcal', kcal),
          dato('proteína g', proteina),
          dato('carbos g', carbos),
          dato('grasa g', grasa),
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
                if (_alimentos.isNotEmpty) _resumenTotales(),
                ..._alimentos.asMap().keys.map((i) => _tarjetaAlimento(i)),
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
                            color: tema.secondary),
                        label: Text('Dictar más',
                            style: TextStyle(color: tema.secondary)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _agregarAlimentoVacio,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _botonPrincipal(
                _guardandoAhora ? 'Guardando...' : 'Guardar',
                (_guardandoAhora || _alimentos.isEmpty)
                    ? null
                    : () => _guardar(completar: false),
                relleno: false,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: (_guardandoAhora || _alimentos.isEmpty)
                    ? null
                    : () => _guardar(completar: true),
                icon:
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(_guardandoAhora ? 'Guardando...' : 'Día completo',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tema.primary,
                  disabledBackgroundColor: _tinte(tema.primary, 0.4),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
    String titulo = 'Registrar comida';
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
        titulo = _comidaAbiertaRef != null
            ? 'Tu comida de hoy'
            : 'Revisa lo que has comido';
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
