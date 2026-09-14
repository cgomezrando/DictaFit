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

class HistorialEntrenos extends StatefulWidget {
  const HistorialEntrenos({
    super.key,
    this.width,
    this.height,
    required this.onVerEntreno,
    required this.onEditarEntreno,
  });

  final double? width;
  final double? height;

  /// Se llama tras dejar el entreno elegido en FFAppState().entrenoGuardadoRef.
  /// La acción de FlutterFlow debe navegar a WorkoutAnalysis (push, no
  /// reemplazar) con Page Parameter entrenoRef = App State entrenoGuardadoRef.
  final Future Function() onVerEntreno;

  /// Igual que onVerEntreno, pero para RecordWorkout (Page Parameter
  /// entrenoParaEditar = App State entrenoGuardadoRef).
  final Future Function() onEditarEntreno;

  @override
  State<HistorialEntrenos> createState() => _HistorialEntrenosState();
}

class _HistorialEntrenosState extends State<HistorialEntrenos> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _stream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entrenos')
          .orderBy('fecha', descending: true)
          .limit(120)
          .snapshots();
    }
  }

  // ---------- Utilidades ----------

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  String _numeroCorto(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _etiquetaDia(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(dia).inDays;
    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]}'
        '${fecha.year != ahora.year ? ' de ${fecha.year}' : ''}';
  }

  String _hora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------- Acciones ----------

  Future<void> _abrir(DocumentReference ref, {required bool editar}) async {
    FFAppState().update(() {
      FFAppState().entrenoGuardadoRef = ref;
    });
    if (editar) {
      await widget.onEditarEntreno();
    } else {
      await widget.onVerEntreno();
    }
  }

  Future<void> _confirmarBorrar(DocumentReference ref, String resumen) async {
    final tema = FlutterFlowTheme.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tema.secondaryBackground,
        title: Text('¿Borrar este entreno?',
            style: TextStyle(color: tema.primaryText)),
        content: Text(resumen, style: TextStyle(color: tema.secondaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar',
                  style: TextStyle(color: tema.secondaryText))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Borrar', style: TextStyle(color: tema.error))),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ref.delete();
      } catch (_) {
        if (mounted)
          _mostrarError('No se ha podido borrar. Inténtalo de nuevo.');
      }
    }
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
            child: Text('Historial',
                style: tema.titleLarge.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    final tema = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 44, color: tema.secondaryText),
            const SizedBox(height: 14),
            Text('Aún no has registrado ningún entreno.',
                textAlign: TextAlign.center,
                style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEntreno(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final tema = FlutterFlowTheme.of(context);
    final datos = doc.data();
    final fecha = datos['fecha'];
    final hora = fecha is Timestamp ? _hora(fecha.toDate()) : '';
    final abierto = (datos['estado'] ?? 'completo') == 'abierto';
    final ejercicios = ((datos['ejercicios'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => (e['nombre'] ?? 'Ejercicio').toString())
        .toList();
    final resumen = ejercicios.isEmpty
        ? 'Sin ejercicios registrados'
        : ejercicios.join(', ');

    double mejorRatio = 0;
    for (final e in (datos['ejercicios'] as List? ?? [])) {
      if (e is! Map) continue;
      final r = (e['ratioPeso'] as num?)?.toDouble() ?? 0;
      if (r > mejorRatio) mejorRatio = r;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.alternate),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _abrir(doc.reference, editar: false),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(hora,
                          style: tema.bodyMedium.copyWith(
                              color: tema.primaryText,
                              fontWeight: FontWeight.w600)),
                      if (abierto) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tinte(tema.secondary, 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Abierto',
                              style: tema.bodySmall.copyWith(
                                  color: tema.secondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                      if (mejorRatio > 0) ...[
                        const SizedBox(width: 8),
                        Text('${mejorRatio.toStringAsFixed(2)}×',
                            style: tema.bodySmall
                                .copyWith(color: tema.secondaryText)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumen,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.bodySmall.copyWith(color: tema.secondaryText),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _abrir(doc.reference, editar: true),
            icon: Icon(Icons.edit_rounded, size: 19, color: tema.secondaryText),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: () => _confirmarBorrar(doc.reference,
                '${_numeroCorto(ejercicios.length.toDouble())} ejercicio(s) del $hora. Esta acción no se puede deshacer.'),
            icon:
                Icon(Icons.delete_outline_rounded, size: 19, color: tema.error),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _lista(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final tema = FlutterFlowTheme.of(context);
    final grupos =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in docs) {
      final fecha = doc.data()['fecha'];
      final etiqueta =
          fecha is Timestamp ? _etiquetaDia(fecha.toDate()) : 'Sin fecha';
      grupos.putIfAbsent(etiqueta, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: grupos.entries.expand((grupo) sync* {
        yield Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Text(grupo.key,
              style: tema.bodySmall.copyWith(
                  color: tema.secondaryText, fontWeight: FontWeight.w600)),
        );
        for (final doc in grupo.value) {
          yield _tarjetaEntreno(doc);
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: tema.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(
              child: _stream == null
                  ? _estadoVacio()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: tema.primary));
                        }
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) return _estadoVacio();
                        return _lista(docs);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
