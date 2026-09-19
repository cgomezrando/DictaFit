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
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:health/health.dart';
import 'dart:async';

/// Si el compilador se queja de que no encuentra 'package:health/health.dart',
/// añádelo en Custom Pub Dependencies: health: ^11.1.1
/// Necesita además el permiso NSHealthShareUsageDescription en Info.plist y
/// la entitlement de HealthKit en Runner.entitlements — pendiente, junto con
/// lo de "aps-environment", para cuando toques el repositorio.

class HomeDictaFit extends StatefulWidget {
  const HomeDictaFit({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<HomeDictaFit> createState() => _HomeDictaFitState();
}

class _HomeDictaFitState extends State<HomeDictaFit> {
  static const Map<String, String> _nombresNivel = {
    'principiante': 'Principiante',
    'novato': 'Novato',
    'intermedio': 'Intermedio',
    'avanzado': 'Avanzado',
    'elite': 'Élite',
  };

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _usuarioStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _comidasHoyStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _ultimoEntrenoStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _entrenosSemanaStream;

  /// Pasos de hoy leídos de HealthKit. null = todavía no se sabe (cargando,
  /// sin permiso, o el dispositivo no lo admite); se muestra aparte de
  /// Firestore para que se vea al instante, sin esperar al guardado.
  int? _pasosHoy;
  bool _sinPermisoPasos = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    unawaited(_sincronizarPasos(uid));

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    final inicioSemana = inicioDia.subtract(Duration(days: ahora.weekday - 1));

    _usuarioStream = userRef.snapshots();
    _comidasHoyStream = userRef
        .collection('comidas')
        .where('fecha', isGreaterThanOrEqualTo: inicioDia)
        .where('fecha', isLessThan: finDia)
        .snapshots();
    _ultimoEntrenoStream = userRef
        .collection('entrenos')
        .where('ultimaActualizacion', isGreaterThanOrEqualTo: inicioDia)
        .where('ultimaActualizacion', isLessThan: finDia)
        .orderBy('ultimaActualizacion', descending: true)
        .limit(1)
        .snapshots();
    _entrenosSemanaStream = userRef
        .collection('entrenos')
        .where('fecha', isGreaterThanOrEqualTo: inicioSemana)
        .snapshots();
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

  double _numero(dynamic valor) {
    return valor is num ? valor.toDouble() : 0.0;
  }

  String _miles(num valor) {
    final negativo = valor < 0;
    final texto = valor.round().abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
      buffer.write(texto[i]);
    }
    return '${negativo ? '-' : ''}$buffer';
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 6) return 'Buenas noches';
    if (hora < 13) return 'Buenos días';
    if (hora < 21) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

  String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
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

  /// Lee tus pasos de hoy (desde medianoche) de HealthKit y los guarda en
  /// users/{uid}/pasos/{fecha}. No es sincronización en segundo plano de
  /// verdad: se hace cada vez que abres Home, así que el aviso de las 12:00
  /// y las 18:00 usará el último dato que hayas subido así, no el pulso
  /// exacto de ese momento si no tenías la app abierta hace poco.
  Future<void> _sincronizarPasos(String uid) async {
    try {
      final salud = Health();
      await salud.configure();
      final autorizado =
          await salud.requestAuthorization([HealthDataType.STEPS]);
      if (!autorizado) {
        if (mounted) setState(() => _sinPermisoPasos = true);
        return;
      }

      final ahora = DateTime.now();
      final medianoche = DateTime(ahora.year, ahora.month, ahora.day);
      final pasos = await salud.getTotalStepsInInterval(medianoche, ahora);
      if (pasos == null) return;

      if (mounted) setState(() => _pasosHoy = pasos);

      final fechaId =
          '${medianoche.year.toString().padLeft(4, '0')}-${medianoche.month.toString().padLeft(2, '0')}-${medianoche.day.toString().padLeft(2, '0')}';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pasos')
          .doc(fechaId)
          .set({
        'fecha': Timestamp.fromDate(medianoche),
        'totalPasos': pasos,
        'actualizado': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Sin HealthKit disponible (simulador, permiso denegado del todo,
      // dispositivo bloqueado): no rompe Home, solo no se muestra el dato.
      if (mounted) setState(() => _sinPermisoPasos = true);
    }
  }

  void _proximamente(String funcion) {
    _mostrarMensaje('$funcion estará disponible muy pronto.');
  }

  // ---------- SVG Icons ----------

  Widget _svgPesa(double tamano, Color color) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0');
    final hexColorFormatted = '#${hexColor.substring(2)}';
    return SizedBox(
      width: tamano,
      height: tamano,
      child: SvgPicture.string(
        '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <g stroke="$hexColorFormatted" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <rect x="10" y="18" width="20" height="22" rx="3"/>
            <rect x="70" y="18" width="20" height="22" rx="3"/>
            <rect x="40" y="15" width="20" height="70" rx="3"/>
            <line x1="30" y1="29" x2="40" y2="29"/>
            <line x1="60" y1="29" x2="70" y2="29"/>
            <line x1="30" y1="71" x2="40" y2="71"/>
            <line x1="60" y1="71" x2="70" y2="71"/>
          </g>
        </svg>''',
      ),
    );
  }

  Widget _svgCubiertos(double tamano, Color color) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0');
    final hexColorFormatted = '#${hexColor.substring(2)}';
    return SizedBox(
      width: tamano,
      height: tamano,
      child: SvgPicture.string(
        '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <g stroke="$hexColorFormatted" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <line x1="25" y1="15" x2="25" y2="55"/>
            <path d="M 15 55 Q 15 68, 25 70 Q 35 68, 35 55" />
            <line x1="75" y1="15" x2="75" y2="50"/>
            <line x1="65" y1="50" x2="65" y2="70"/>
            <line x1="75" y1="50" x2="75" y2="70"/>
            <line x1="85" y1="50" x2="85" y2="70"/>
            <path d="M 65 50 Q 70 48, 75 48 Q 80 48, 85 50"/>
          </g>
        </svg>''',
      ),
    );
  }

  Widget _svgEcg(double tamano, Color color) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0');
    final hexColorFormatted = '#${hexColor.substring(2)}';
    return SizedBox(
      width: tamano,
      height: tamano,
      child: SvgPicture.string(
        '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <g stroke="$hexColorFormatted" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <line x1="5" y1="50" x2="25" y2="50"/>
            <line x1="25" y1="50" x2="32" y2="30"/>
            <line x1="32" y1="30" x2="38" y2="50"/>
            <line x1="38" y1="50" x2="42" y2="58"/>
            <line x1="42" y1="58" x2="48" y2="50"/>
            <line x1="48" y1="50" x2="58" y2="50"/>
            <line x1="58" y1="50" x2="63" y2="35"/>
            <line x1="63" y1="35" x2="68" y2="50"/>
            <line x1="68" y1="50" x2="95" y2="50"/>
          </g>
        </svg>''',
      ),
    );
  }

  /// Muslo de pollo, diseño de Carlos (generado con Recraft AI), extraído
  /// de un set que traía también una oreja; esta es solo la ruta del muslo.
  /// Muslo de pollo, diseño de Carlos (Recraft AI). El trazo original venía
  /// compuesto por tres sub-trazos que, combinados, dibujan un contorno
  /// hueco (como un donut) en vez de una silueta rellena; aquí se usa solo
  /// el sub-trazo exterior, que sí es una silueta sólida. Con una ligera
  /// rotación, a juego con la espiga de cereal.
  Widget _svgMuslo(double tamano, Color color) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0');
    final hexColorFormatted = '#${hexColor.substring(2)}';
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Transform.rotate(
        angle: -0.26,
        child: SvgPicture.string(
          '''<svg viewBox="152.0 -19.0 419.0 419.0" xmlns="http://www.w3.org/2000/svg">
            <path fill="$hexColorFormatted" d="M 332.407 0 L 390.574 0 C 391.884 1.00204 394.343 2.29575 395.824 3.1492 C 423.708 19.2156 417.058 51.5363 388.321 61.2285 C 387.581 73.4357 388.021 90.5808 387.872 103.288 C 413.884 110.488 395.895 131.47 403.346 145.537 C 421.924 180.608 456.209 206.701 466.209 246.735 C 473.063 274.656 468.622 304.154 453.853 328.821 C 439.227 353.189 415.497 370.729 387.91 377.563 C 359.785 384.478 330.064 379.88 305.343 364.791 C 282.126 350.712 263.014 326.537 257.07 299.961 C 245.084 246.374 267.364 216.878 298.359 177.223 C 305.16 168.759 311.051 161.116 316.746 151.899 C 327.857 133.919 310.265 109.132 335.708 103.295 C 335.712 89.3023 335.615 75.3097 335.417 61.3183 C 310.813 53.6936 301.121 31.898 318.213 10.2537 C 322.161 5.25399 327.03 3.22545 332.407 0 z"/>
          </svg>''',
        ),
      ),
    );
  }

  /// Espiga de cereal, diseño de Carlos (generado con Recraft AI); el
  /// archivo original traía dos espigas juntas, se usa solo una para que
  /// no se vea recargado a tamaño de icono pequeño.
  Widget _svgCereal(double tamano, Color color) {
    final hexColor = color.value.toRadixString(16).padLeft(8, '0');
    final hexColorFormatted = '#${hexColor.substring(2)}';
    return SizedBox(
      width: tamano,
      height: tamano,
      child: SvgPicture.string(
        '''<svg viewBox="-178.0 273.9 1633.3 1633.3" xmlns="http://www.w3.org/2000/svg">
          <path fill="$hexColorFormatted" d="M 494.622 346.721 C 515.956 362.823 545.689 393.104 560.916 414.554 C 590.9 456.79 601.387 498.817 593.017 549.884 C 596.723 566.119 585.547 579.86 581.897 594.898 C 580.822 599.329 581.392 609.525 581.504 614.47 C 585.616 607.916 595.9 570.97 595.899 563.405 L 596.591 562.582 L 599.922 562.673 C 622.983 477.672 701.85 420.803 778.928 388.194 C 797.34 459.887 811.626 584.758 772.492 651.793 C 751.543 687.675 704.701 735.498 666.596 752.725 C 652.878 758.927 633.229 763.994 624.241 773.488 C 636.066 809.062 646.473 853.129 656.257 889.757 C 667.532 792.052 712.062 723.574 797.159 674.381 C 815.448 663.808 829.927 654.461 851.509 651.017 C 867.053 729.958 885.926 848.942 838.48 919.655 C 802.639 973.074 756.331 1010.28 695.034 1030.81 C 708.134 1072.83 713.947 1105.69 730.503 1149.03 C 733.296 1045.69 798.058 970.847 885.67 924.943 C 900.066 917.4 907.876 913.252 923.958 910.419 L 924.099 912.359 C 925.669 932.69 931.739 954.862 934.08 976.1 C 940.302 1032.57 944.467 1098.25 923.875 1152.33 C 916.153 1172.61 898.808 1195.79 885.12 1212.31 C 859.161 1243.63 808.492 1280.96 767.851 1288.75 C 770.935 1317.19 783.027 1345.35 788.519 1373.61 C 789.563 1378.98 792.684 1396.09 794.745 1400.01 L 796.176 1400.96 L 797.188 1400.67 C 802.104 1387.96 803.614 1378.67 806.508 1365.45 C 825.638 1278.07 892.508 1214.3 971.659 1178.36 C 979.18 1174.94 985.761 1172.49 993.759 1170.54 C 997.492 1193.34 1004.09 1219.03 1005.78 1241.39 C 1011.28 1314.2 1019.27 1391.35 972.026 1452.8 C 933.804 1502.51 896.186 1530.94 837.256 1551.9 C 863.285 1642.54 886.546 1734.92 912.513 1825.45 C 901.072 1829.53 892.15 1830.18 882.116 1833.36 C 878.373 1811.84 868.811 1780.52 862.933 1758.75 C 852.115 1717.76 841.061 1676.82 829.772 1635.96 C 823.227 1612.04 814.473 1582.98 809.253 1559.25 C 789.224 1559.65 765.555 1561.28 745.983 1560.14 C 693.005 1557.04 623.878 1542.11 585.275 1504.51 C 543.514 1463.84 492.375 1363.57 482.267 1307.43 C 593.02 1300.04 669.681 1307.15 751.299 1393.11 C 756.452 1394.95 757.044 1397.04 760.193 1401.85 L 761.972 1402.48 L 764.704 1398.73 C 763.797 1392.09 760.054 1380.79 758.396 1374.01 C 752.584 1350.24 742.337 1322.13 739.204 1298.24 C 721.409 1299.21 701.472 1300.32 683.63 1299.98 C 635.531 1299.07 574.355 1286.32 534.49 1260.29 C 481.707 1225.83 422.724 1108.17 411.167 1047.75 C 438.376 1044.94 465.752 1044.11 493.081 1045.26 C 565.901 1049.03 632.276 1076.61 680.061 1133.45 C 685.181 1139.54 689.115 1146.5 694.48 1152.44 C 697.509 1140.48 670.391 1060.68 668.613 1038.99 C 647.424 1038.28 624.044 1040.15 602.549 1039.15 C 552.717 1036.83 495.933 1023.58 455.718 994.077 C 408.333 959.318 348.965 843.199 341.051 786.781 C 360.69 786.364 380.039 783.658 399.3 783.152 C 417.39 782.678 442.014 786.189 460.006 789.021 C 514.319 797.57 566.73 826.677 603.836 867.09 C 610.731 874.6 617.016 884.392 622.982 892.908 C 621.747 861.492 603.752 811.79 596.311 777.936 C 580.391 778.192 563.443 779.771 547.425 779.722 C 503.855 779.589 446.036 768.166 407.605 748.357 C 335.836 711.365 290.723 599.692 267.74 526.201 C 303.279 525.391 333.217 521.874 369.905 525.785 C 422.338 531.373 474.557 553.418 514.408 588.159 C 524.831 597.246 548.534 625.293 557.739 636.46 C 552.71 604.87 542.905 603.39 521.635 583.996 C 498.155 562.586 477.928 527.951 472.234 496.528 C 465.412 458.888 469.25 419.278 480.392 382.786 C 484.698 368.33 486.099 359.342 494.622 346.721 z"/>
        </svg>''',
      ),
    );
  }

  // ---------- Acciones ----------

  Future<void> _cerrarSesion() async {
    GoRouter.of(context).prepareAuthEvent();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth('Login', context.mounted);
  }

  Future<void> _abrirHojaRegistro() async {
    final tema = FlutterFlowTheme.of(context);
    final eleccion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: tema.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _asaHoja(),
                const SizedBox(height: 18),
                Text(
                  '¿Qué quieres registrar?',
                  style: tema.titleLarge.copyWith(
                    color: tema.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _opcionHoja(
                  icono: Icons.fitness_center_rounded,
                  acento: tema.primary,
                  titulo: 'Entrenamiento',
                  subtitulo: 'Dicta tus series y pesos',
                  alPulsar: () => Navigator.of(ctx).pop('entreno'),
                ),
                const SizedBox(height: 10),
                _opcionHoja(
                  icono: Icons.eco_rounded,
                  acento: tema.secondary,
                  titulo: 'Comida',
                  subtitulo: 'Dicta lo que has comido',
                  alPulsar: () => Navigator.of(ctx).pop('comida'),
                ),
                const SizedBox(height: 10),
                _opcionHoja(
                  icono: Icons.timer_rounded,
                  acento: tema.tertiary,
                  titulo: 'Intervalos',
                  subtitulo: 'Crea o inicia una sesión',
                  alPulsar: () => Navigator.of(ctx).pop('intervalos'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || eleccion == null) return;
    switch (eleccion) {
      case 'entreno':
        context.pushNamed('RecordWorkout');
        break;
      case 'comida':
        context.pushNamed('RecordMeal');
        break;
      case 'intervalos':
        _proximamente('El cronómetro de intervalos');
        break;
    }
  }

  // ---------- Componentes visuales ----------

  Widget _asaHoja() {
    final tema = FlutterFlowTheme.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: tema.alternate,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _opcionHoja({
    required IconData icono,
    required Color acento,
    required String titulo,
    required String subtitulo,
    required VoidCallback alPulsar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tema.primaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tema.alternate),
          ),
          child: Row(
            children: [
              _insignia(icono, acento, 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: tema.titleSmall.copyWith(
                        color: tema.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: tema.bodySmall.copyWith(color: tema.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tema.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

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
            color: _tinte(acento, 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icono, color: Colors.white, size: tamano * 0.5),
    );
  }

  BoxDecoration _decoracionTarjeta(Color acento, {double intensidad = 0.12}) {
    final tema = FlutterFlowTheme.of(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: tema.alternate),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.7],
        colors: [
          Color.alphaBlend(
              _tinte(acento, intensidad), tema.secondaryBackground),
          tema.secondaryBackground,
        ],
      ),
    );
  }

  Widget _cabecera(String nombre, String fotoUrl, String email) {
    final tema = FlutterFlowTheme.of(context);
    final primerNombre =
        _capitalizar(nombre.trim().split(RegExp(r'\s+')).first);
    final saludo = nombre.trim().isEmpty
        ? '¡${_saludo()}!'
        : '¡${_saludo()}, $primerNombre!';

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pushNamed('Profile'),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_aclarar(tema.primary, 0.10), tema.primary],
              ),
              border: Border.all(color: tema.alternate, width: 2),
              image: fotoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(fotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: fotoUrl.isEmpty
                ? Text(
                    _iniciales(nombre),
                    style: tema.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saludo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.headlineSmall.copyWith(
                  color: tema.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Listo para ser tu mejor versión.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.bodyMedium.copyWith(color: tema.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metrica({
    IconData? icono,
    Widget? iconoWidget,
    required Color acento,
    required String titulo,
    required double valor,
    required double objetivo,
    required String unidad,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final progreso =
        objetivo > 0 ? (valor / objetivo).clamp(0.0, 1.0).toDouble() : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconoWidget ?? Icon(icono, size: 16, color: acento),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.bodySmall.copyWith(color: tema.secondaryText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _miles(valor),
                  style: tema.titleLarge.copyWith(
                    color: tema.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text:
                      ' / ${_miles(objetivo)}${unidad.isEmpty ? '' : ' $unidad'}',
                  style: tema.bodySmall.copyWith(color: tema.secondaryText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 5,
            backgroundColor: tema.alternate,
            valueColor: AlwaysStoppedAnimation<Color>(acento),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaPasos(int objetivo) {
    final tema = FlutterFlowTheme.of(context);
    final pasos = _pasosHoy;
    final progreso = pasos == null || objetivo <= 0
        ? 0.0
        : (pasos / objetivo).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracionTarjeta(tema.secondary, intensidad: 0.08),
      child: Row(
        children: [
          Icon(Icons.directions_walk_rounded, color: tema.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Pasos de hoy',
                        style: tema.bodyMedium.copyWith(
                            color: tema.primaryText,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (pasos != null)
                      Text('${_miles(pasos)} / ${_miles(objetivo)}',
                          style: tema.bodyMedium.copyWith(
                              color: tema.secondary,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                if (pasos == null)
                  Text(
                    _sinPermisoPasos
                        ? 'Sin acceso a Salud. Puedes activarlo en Ajustes → Privacidad → Salud.'
                        : 'Leyendo tus pasos de hoy...',
                    style: tema.bodySmall.copyWith(color: tema.secondaryText),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 6,
                      backgroundColor: tema.alternate,
                      valueColor: AlwaysStoppedAnimation(tema.secondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenDiario({
    required double kcal,
    required double objetivoKcal,
    required double proteina,
    required double objetivoProteina,
    required double carbos,
    required double objetivoCarbos,
    required double grasa,
    required double objetivoGrasa,
  }) {
    final tema = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _decoracionTarjeta(tema.primary, intensidad: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 20, color: tema.primary),
              const SizedBox(width: 8),
              Text(
                'Resumen diario',
                style: tema.titleSmall.copyWith(
                  color: tema.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metrica(
                  icono: Icons.local_fire_department_rounded,
                  acento: tema.primary,
                  titulo: 'Calorías',
                  valor: kcal,
                  objetivo: objetivoKcal,
                  unidad: '',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _metrica(
                  iconoWidget: _svgMuslo(16, tema.secondary),
                  acento: tema.secondary,
                  titulo: 'Proteínas',
                  valor: proteina,
                  objetivo: objetivoProteina,
                  unidad: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _metrica(
                  iconoWidget: _svgCereal(16, tema.tertiary),
                  acento: tema.tertiary,
                  titulo: 'Carbos',
                  valor: carbos,
                  objetivo: objetivoCarbos,
                  unidad: 'g',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _metrica(
                  icono: Icons.water_drop_rounded,
                  acento: tema.error,
                  titulo: 'Grasas',
                  valor: grasa,
                  objetivo: objetivoGrasa,
                  unidad: 'g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonMicro(Color acento, VoidCallback alPulsar,
      {double tamano = 78}) {
    final medio = tamano * 0.82;
    final interior = tamano * 0.64;
    return GestureDetector(
      onTap: alPulsar,
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: tamano,
              height: tamano,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tinte(acento, 0.07),
              ),
            ),
            Container(
              width: medio,
              height: medio,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tinte(acento, 0.13),
              ),
            ),
            Container(
              width: interior,
              height: interior,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_aclarar(acento, 0.12), acento],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _tinte(acento, 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.mic_rounded,
                  color: Colors.white, size: interior * 0.52),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonPildora(String texto, Color acento, VoidCallback alPulsar) {
    final tema = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _tinte(acento, 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: tema.bodySmall.copyWith(
                  color: acento,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 18, color: acento),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaFuncion({
    required IconData icono,
    required Widget iconoFondo,
    required Color acento,
    required String titulo,
    required String descripcion,
    required String textoBoton,
    required VoidCallback alHablar,
    required VoidCallback alBoton,
  }) {
    final tema = FlutterFlowTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: _decoracionTarjeta(acento, intensidad: 0.16),
        child: Stack(
          children: [
            Positioned(
              right: 84,
              bottom: -18,
              child: IgnorePointer(
                child: Opacity(opacity: 0.18, child: iconoFondo),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _insignia(icono, acento, 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.titleMedium.copyWith(
                                  color: tema.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tema.bodySmall.copyWith(
                            color: tema.secondaryText,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _botonPildora(textoBoton, acento, alBoton),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _botonMicro(acento, alHablar, tamano: 72),
                      const SizedBox(height: 2),
                      Text(
                        'Registrar',
                        style: tema.bodySmall.copyWith(
                          color: acento,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaEnfoque({
    required IconData icono,
    required Color acento,
    required String titulo,
    required String valor,
    required Color colorValor,
    String extra = '',
    bool ultima = false,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border:
            ultima ? null : Border(bottom: BorderSide(color: tema.alternate)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tinte(acento, 0.16),
            ),
            child: Icon(icono, size: 16, color: acento),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: tema.bodyMedium.copyWith(color: tema.primaryText),
            ),
          ),
          Text(
            valor,
            style: tema.bodyLarge.copyWith(
              color: colorValor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (extra.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              extra,
              style: tema.bodySmall.copyWith(color: tema.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _enfoqueHoy({
    required double kcal,
    required double objetivoKcal,
    required int numComidas,
    required double? mejorRatio,
    required String nivel,
    required int entrenosSemana,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final progreso = objetivoKcal > 0 ? kcal / objetivoKcal : 0.0;
    final porcentaje = (progreso * 100).round();
    final balance = kcal - objetivoKcal;

    String titular;
    String detalle;
    if (numComidas == 0) {
      titular = 'Empieza tu día';
      detalle = 'Dicta tu primera comida y verás aquí tu progreso.';
    } else if (progreso < 0.9) {
      titular = 'Vas por buen camino';
      detalle = 'Te quedan ${_miles(-balance)} kcal para tu objetivo.';
    } else if (progreso <= 1.1) {
      titular = 'Objetivo cumplido';
      detalle = 'Estás dentro de tu rango de calorías de hoy.';
    } else {
      titular = 'Por encima del objetivo';
      detalle = 'Llevas ${_miles(balance)} kcal más de lo previsto.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _decoracionTarjeta(tema.primary, intensidad: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, size: 20, color: tema.primary),
              const SizedBox(width: 8),
              Text(
                'Tu enfoque de hoy',
                style: tema.titleSmall.copyWith(
                  color: tema.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: progreso.clamp(0.0, 1.0).toDouble(),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: tema.alternate,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progreso > 1.1 ? tema.error : tema.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$porcentaje%',
                      style: tema.titleLarge.copyWith(
                        color: tema.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titular,
                      style: tema.titleMedium.copyWith(
                        color: tema.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      style: tema.bodySmall.copyWith(
                        color: tema.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _filaEnfoque(
            icono: Icons.fitness_center_rounded,
            acento: tema.primary,
            titulo: 'Fuerza (hoy)',
            valor:
                mejorRatio == null ? '—' : '${mejorRatio.toStringAsFixed(2)}×',
            colorValor: tema.primaryText,
            extra: nivel,
          ),
          _filaEnfoque(
            icono: Icons.local_fire_department_rounded,
            acento: tema.secondary,
            titulo: 'Balance calórico',
            valor: numComidas == 0
                ? '—'
                : '${balance > 0 ? '+' : ''}${_miles(balance)} kcal',
            colorValor: balance > 0 ? tema.error : tema.secondary,
          ),
          _filaEnfoque(
            icono: Icons.calendar_month_rounded,
            acento: tema.tertiary,
            titulo: 'Entrenos esta semana',
            valor: '$entrenosSemana',
            colorValor: tema.tertiary,
            ultima: true,
          ),
        ],
      ),
    );
  }

  Widget _itemNavegacion({
    required IconData icono,
    required String texto,
    required bool activo,
    required VoidCallback alPulsar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    final color = activo ? tema.primary : tema.secondaryText;
    return Expanded(
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 26, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  texto,
                  style: tema.bodySmall.copyWith(
                    color: color,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraNavegacion(String nombre, String email) {
    final tema = FlutterFlowTheme.of(context);
    final inferior = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + inferior),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        border: Border(top: BorderSide(color: tema.alternate)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _itemNavegacion(
            icono: Icons.home_rounded,
            texto: 'Inicio',
            activo: true,
            alPulsar: () {},
          ),
          _itemNavegacion(
            icono: Icons.history_rounded,
            texto: 'Historial',
            activo: false,
            alPulsar: () => context.pushNamed('SelectHistory'),
          ),
          SizedBox(
            width: 76,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -20,
                  child: GestureDetector(
                    onTap: _abrirHojaRegistro,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_aclarar(tema.primary, 0.12), tema.primary],
                        ),
                        border: Border.all(
                          color: tema.primaryBackground,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _tinte(tema.primary, 0.5),
                            blurRadius: 22,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _itemNavegacion(
            icono: Icons.bar_chart_rounded,
            texto: 'Estadísticas',
            activo: false,
            alPulsar: () => context.pushNamed('Statistics'),
          ),
          _itemNavegacion(
            icono: Icons.person_rounded,
            texto: 'Perfil',
            activo: false,
            alPulsar: () => context.pushNamed('Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _usuarioStream,
        builder: (context, snapUsuario) {
          final usuario = snapUsuario.data?.data() ?? <String, dynamic>{};
          final nombre = (usuario['display_name'] ?? '').toString();
          final email = (usuario['email'] ??
                  FirebaseAuth.instance.currentUser?.email ??
                  '')
              .toString();
          final fotoUrl = (usuario['photo_url'] ?? '').toString();
          final objetivoKcal = _numero(usuario['objetivoKcal']);
          final objetivoProteina = _numero(usuario['objetivoProteinaG']);
          final objetivoCarbos = _numero(usuario['objetivoCarbosG']);
          final objetivoGrasa = _numero(usuario['objetivoGrasaG']);
          final objetivoPasos =
              (usuario['objetivoPasos'] as num?)?.toInt() ?? 10000;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _comidasHoyStream,
            builder: (context, snapComidas) {
              double kcal = 0;
              double proteina = 0;
              double carbos = 0;
              double grasa = 0;
              final comidas = snapComidas.data?.docs ?? [];
              for (final doc in comidas) {
                final datos = doc.data();
                kcal += _numero(datos['kcal']);
                proteina += _numero(datos['proteinaG']);
                carbos += _numero(datos['carbosG']);
                grasa += _numero(datos['grasaG']);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ultimoEntrenoStream,
                builder: (context, snapUltimo) {
                  double? mejorRatio;
                  String nivel = '';
                  final ultimos = snapUltimo.data?.docs ?? [];
                  if (ultimos.isNotEmpty) {
                    final ejercicios = ultimos.first.data()['ejercicios'];
                    if (ejercicios is List) {
                      for (final ejercicio in ejercicios) {
                        if (ejercicio is Map) {
                          final ratio = _numero(ejercicio['ratioPeso']);
                          final ratioActual = mejorRatio;
                          if (ratio > 0 &&
                              (ratioActual == null || ratio > ratioActual)) {
                            mejorRatio = ratio;
                            nivel = _nombresNivel[
                                    (ejercicio['nivel'] ?? '').toString()] ??
                                '';
                          }
                        }
                      }
                    }
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _entrenosSemanaStream,
                    builder: (context, snapSemana) {
                      final entrenosSemana = snapSemana.data?.docs.length ?? 0;

                      return Column(
                        children: [
                          Expanded(
                            child: SafeArea(
                              bottom: false,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 44),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _cabecera(nombre, fotoUrl, email),
                                    const SizedBox(height: 20),
                                    _resumenDiario(
                                      kcal: kcal,
                                      objetivoKcal: objetivoKcal,
                                      proteina: proteina,
                                      objetivoProteina: objetivoProteina,
                                      carbos: carbos,
                                      objetivoCarbos: objetivoCarbos,
                                      grasa: grasa,
                                      objetivoGrasa: objetivoGrasa,
                                    ),
                                    const SizedBox(height: 14),
                                    _tarjetaPasos(objetivoPasos),
                                    const SizedBox(height: 14),
                                    _tarjetaFuncion(
                                      icono: Icons.fitness_center_rounded,
                                      iconoFondo: _svgPesa(
                                          84, _tinte(tema.primary, 0.35)),
                                      acento: tema.primary,
                                      titulo: 'Entrenamiento',
                                      descripcion:
                                          'Dicta tu rutina y calculamos tu fuerza y los músculos trabajados.',
                                      textoBoton: 'Ver último entrenamiento',
                                      alHablar: () =>
                                          context.pushNamed('RecordWorkout'),
                                      alBoton: () =>
                                          context.pushNamed('WorkoutAnalysis'),
                                    ),
                                    const SizedBox(height: 10),
                                    _tarjetaFuncion(
                                      icono: Icons.eco_rounded,
                                      iconoFondo: _svgCubiertos(
                                          84, _tinte(tema.secondary, 0.35)),
                                      acento: tema.secondary,
                                      titulo: 'Nutrición',
                                      descripcion:
                                          'Cuéntame lo que comes y calculamos calorías y macros.',
                                      textoBoton: 'Ver macros',
                                      alHablar: () =>
                                          context.pushNamed('RecordMeal'),
                                      alBoton: () =>
                                          _proximamente('El detalle de macros'),
                                    ),
                                    const SizedBox(height: 10),
                                    _tarjetaFuncion(
                                      icono: Icons.timer_rounded,
                                      iconoFondo: _svgEcg(
                                          84, _tinte(tema.tertiary, 0.35)),
                                      acento: tema.tertiary,
                                      titulo: 'Cronómetro',
                                      descripcion:
                                          'Intervalos inteligentes por tiempo o por frecuencia cardiaca.',
                                      textoBoton: 'Crear intervalo',
                                      alHablar: () => _proximamente(
                                          'Crear intervalos por voz'),
                                      alBoton: () => _proximamente(
                                          'El cronómetro de intervalos'),
                                    ),
                                    const SizedBox(height: 14),
                                    _enfoqueHoy(
                                      kcal: kcal,
                                      objetivoKcal: objetivoKcal,
                                      numComidas: comidas.length,
                                      mejorRatio: mejorRatio,
                                      nivel: nivel,
                                      entrenosSemana: entrenosSemana,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _barraNavegacion(nombre, email),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
