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
import 'package:fl_chart/fl_chart.dart';

/// Si el compilador se queja de que no encuentra 'package:fl_chart/fl_chart.dart',
/// añádelo en Custom Pub Dependencies: fl_chart: ^0.69.0

class EstadisticasEntreno extends StatefulWidget {
  const EstadisticasEntreno({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<EstadisticasEntreno> createState() => _EstadisticasEntrenoState();
}

class _EstadisticasEntrenoState extends State<EstadisticasEntreno> {
  static const Map<String, String> _grupoMuscular = {
    'pectoral_clavicular': 'pecho',
    'pectoral_esternal': 'pecho',
    'deltoides_anterior': 'hombro',
    'deltoides_lateral': 'hombro',
    'deltoides_posterior': 'hombro',
    'trapecio': 'hombro',
    'triceps': 'brazo',
    'biceps': 'brazo',
    'antebrazo': 'brazo',
    'dorsal': 'espalda',
    'romboides': 'espalda',
    'lumbar': 'espalda',
    'abdominal': 'core',
    'oblicuos': 'core',
    'gluteo': 'pierna',
    'cuadriceps': 'pierna',
    'isquiotibiales': 'pierna',
    'aductores': 'pierna',
    'gemelos': 'pierna',
  };

  static const Map<String, String> _nombreGrupo = {
    'pecho': 'Pecho',
    'hombro': 'Hombros',
    'brazo': 'Brazos',
    'espalda': 'Espalda',
    'core': 'Abdomen',
    'pierna': 'Piernas',
  };

  // Orden fijo en el que se listan los grupos en el resumen.
  static const List<String> _ordenGrupos = [
    'pecho',
    'espalda',
    'hombro',
    'brazo',
    'pierna',
    'core',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>>? _pesosStream;

  /// Últimos entrenos, para el resumen de "hace cuántos días" por grupo y
  /// el conteo semanal. Se cargan una vez, no hace falta que sea en vivo.
  List<Map<String, dynamic>>? _entrenosRecientes;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _pesosStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pesos')
          .orderBy('fecha', descending: false)
          .limit(200)
          .snapshots();
      _cargarEntrenosRecientes(uid);
    }
  }

  void _cargarEntrenosRecientes(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entrenos')
        .orderBy('fecha', descending: true)
        .limit(60)
        .get()
        .then((snap) {
      if (!mounted) return;
      setState(
          () => _entrenosRecientes = snap.docs.map((d) => d.data()).toList());
    }).catchError((_) {
      if (mounted) setState(() => _entrenosRecientes = []);
    });
  }

  // ---------- Utilidades ----------

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  String _numeroCorto(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _fecha(DateTime f) {
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
      'dic'
    ];
    return '${f.day} ${meses[f.month - 1]}';
  }

  // ---------- Cabecera ----------

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
            child: Text('Estadísticas',
                style: tema.titleLarge.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------- Sección 1: peso y % de grasa ----------

  Widget _tarjetaGrafica({
    required String titulo,
    required Color acento,
    required List<FlSpot> puntos,
    required String sufijo,
    required String? etiquetaVacio,
    DateTime? primeraFecha,
    DateTime? ultimaFecha,
  }) {
    final tema = FlutterFlowTheme.of(context);

    Widget cuerpo;
    if (puntos.length < 2) {
      cuerpo = SizedBox(
        height: 140,
        child: Center(
          child: Text(
            etiquetaVacio ??
                'Necesitas al menos dos registros para ver la evolución.',
            textAlign: TextAlign.center,
            style: tema.bodySmall.copyWith(color: tema.secondaryText),
          ),
        ),
      );
    } else {
      final minY = puntos.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final maxY = puntos.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      final margen = ((maxY - minY).abs() * 0.15).clamp(0.5, double.infinity);
      cuerpo = SizedBox(
        height: 140,
        child: LineChart(
          LineChartData(
            minX: puntos.first.x,
            maxX: puntos.last.x,
            minY: minY - margen,
            maxY: maxY + margen,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              show: false,
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tema.primaryBackground,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${_numeroCorto(s.y)} $sufijo',
                          tema.bodySmall.copyWith(
                              color: tema.primaryText,
                              fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: puntos,
                isCurved: true,
                curveSmoothness: 0.2,
                color: acento,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData:
                    BarAreaData(show: true, color: _tinte(acento, 0.12)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
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
              if (puntos.isNotEmpty) ...[
                const Spacer(),
                Text('${_numeroCorto(puntos.last.y)} $sufijo',
                    style: tema.titleSmall
                        .copyWith(color: acento, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          cuerpo,
          if (puntos.length >= 2 &&
              primeraFecha != null &&
              ultimaFecha != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fecha(primeraFecha),
                    style: tema.bodySmall.copyWith(color: tema.secondaryText)),
                Text(_fecha(ultimaFecha),
                    style: tema.bodySmall.copyWith(color: tema.secondaryText)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _seccionPesoYGrasa(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final tema = FlutterFlowTheme.of(context);
    final puntosPeso = <FlSpot>[];
    final puntosGrasa = <FlSpot>[];
    DateTime? primeraPeso, ultimaPeso, primeraGrasa, ultimaGrasa;

    for (var i = 0; i < docs.length; i++) {
      final datos = docs[i].data();
      final fechaTs = datos['fecha'];
      if (fechaTs is! Timestamp) continue;
      final x = i.toDouble();

      final peso = (datos['pesoKg'] as num?)?.toDouble();
      if (peso != null && peso > 0) {
        puntosPeso.add(FlSpot(x, peso));
        primeraPeso ??= fechaTs.toDate();
        ultimaPeso = fechaTs.toDate();
      }

      final grasa = (datos['grasaCorporalPct'] as num?)?.toDouble();
      if (grasa != null && grasa > 0) {
        puntosGrasa.add(FlSpot(x, grasa));
        primeraGrasa ??= fechaTs.toDate();
        ultimaGrasa = fechaTs.toDate();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaGrafica(
          titulo: 'Peso corporal',
          acento: tema.primary,
          puntos: puntosPeso,
          sufijo: 'kg',
          etiquetaVacio:
              'Registra tu peso más de una vez en Perfil para ver aquí su evolución.',
          primeraFecha: primeraPeso,
          ultimaFecha: ultimaPeso,
        ),
        _tarjetaGrafica(
          titulo: '% de grasa estimado',
          acento: tema.tertiary,
          puntos: puntosGrasa,
          sufijo: '%',
          etiquetaVacio:
              'Rellena cuello y cintura (y cadera si aplica) en Perfil, más de una vez, '
              'para ver aquí la evolución. Es una estimación (método de la Marina de '
              'EE. UU.), no una medición real.',
          primeraFecha: primeraGrasa,
          ultimaFecha: ultimaGrasa,
        ),
      ],
    );
  }

  // ---------- Sección 4: resumen rápido ----------

  int _contarEntrenosEn(DateTime inicio, DateTime fin) {
    if (_entrenosRecientes == null) return 0;
    var total = 0;
    for (final entreno in _entrenosRecientes!) {
      final f = entreno['fecha'];
      if (f is! Timestamp) continue;
      final fecha = f.toDate();
      if (!fecha.isBefore(fin) || fecha.isBefore(inicio)) continue;
      total++;
    }
    return total;
  }

  /// Días desde la última vez que cada grupo muscular apareció como motor
  /// principal en un entreno, a partir de los mismos entrenos recientes.
  Map<String, int?> _diasDesdeGrupo() {
    final resultado = <String, int?>{for (final g in _ordenGrupos) g: null};
    if (_entrenosRecientes == null) return resultado;
    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);

    for (final entreno in _entrenosRecientes!) {
      final f = entreno['fecha'];
      if (f is! Timestamp) continue;
      final fecha = f.toDate();
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      final dias = hoyFecha.difference(dia).inDays;

      final ejercicios = entreno['ejercicios'];
      if (ejercicios is! List) continue;
      final gruposDeEsteEntreno = <String>{};
      for (final ej in ejercicios) {
        if (ej is! Map) continue;
        final musculos = ej['musculos'];
        if (musculos is! List) continue;
        for (final m in musculos) {
          if (m is! Map) continue;
          if ((m['rol'] ?? '').toString().toLowerCase() != 'principal')
            continue;
          final grupo =
              _grupoMuscular[(m['musculo'] ?? '').toString().toLowerCase()];
          if (grupo != null) gruposDeEsteEntreno.add(grupo);
        }
      }
      for (final grupo in gruposDeEsteEntreno) {
        final actual = resultado[grupo];
        if (actual == null || dias < actual) resultado[grupo] = dias;
      }
    }
    return resultado;
  }

  String _textoDias(int? dias) {
    if (dias == null) return 'sin datos';
    if (dias == 0) return 'hoy';
    if (dias == 1) return 'ayer';
    return 'hace $dias días';
  }

  Widget _resumenRapido() {
    final tema = FlutterFlowTheme.of(context);

    if (_entrenosRecientes == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Center(child: CircularProgressIndicator(color: tema.primary)),
      );
    }

    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final inicioSemana =
        hoyFecha.subtract(Duration(days: hoyFecha.weekday - 1));
    final inicioSemanaAnterior = inicioSemana.subtract(const Duration(days: 7));
    final estaSemana =
        _contarEntrenosEn(inicioSemana, hoyFecha.add(const Duration(days: 1)));
    final semanaAnterior =
        _contarEntrenosEn(inicioSemanaAnterior, inicioSemana);
    final dias = _diasDesdeGrupo();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen rápido',
              style: tema.titleSmall.copyWith(
                  color: tema.primaryText, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: tema.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Entrenos esta semana',
                    style: tema.bodyMedium.copyWith(color: tema.primaryText)),
              ),
              Text('$estaSemana',
                  style: tema.bodyLarge.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('(semana pasada: $semanaAnterior)',
                  style: tema.bodySmall.copyWith(color: tema.secondaryText)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: tema.alternate),
          const SizedBox(height: 8),
          Text('Última vez que trabajaste cada grupo',
              style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          const SizedBox(height: 10),
          for (final grupo in _ordenGrupos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_nombreGrupo[grupo]!,
                        style:
                            tema.bodyMedium.copyWith(color: tema.primaryText)),
                  ),
                  Text(
                    _textoDias(dias[grupo]),
                    style: tema.bodyMedium.copyWith(
                      color: (dias[grupo] ?? 99) >= 8
                          ? tema.warning
                          : tema.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Build ----------

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
              child: _pesosStream == null
                  ? Center(
                      child: Text('Inicia sesión para ver tus estadísticas.',
                          style: tema.bodyMedium
                              .copyWith(color: tema.secondaryText)),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _pesosStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: tema.primary));
                        }
                        final docs = snap.data?.docs ?? [];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _seccionPesoYGrasa(docs),
                              _resumenRapido(),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
