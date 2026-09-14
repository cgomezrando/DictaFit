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

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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
        _proximamente('El registro de comidas');
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
    required IconData icono,
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
            Icon(icono, size: 16, color: acento),
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

  Widget _resumenDiario({
    required double kcal,
    required double objetivoKcal,
    required double proteina,
    required double objetivoProteina,
    required double carbos,
    required double objetivoCarbos,
  }) {
    final tema = FlutterFlowTheme.of(context);

    Widget separador() => Container(
          width: 1,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: tema.alternate,
        );

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
          const SizedBox(height: 14),
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
              separador(),
              Expanded(
                child: _metrica(
                  icono: Icons.bolt_rounded,
                  acento: tema.secondary,
                  titulo: 'Proteínas',
                  valor: proteina,
                  objetivo: objetivoProteina,
                  unidad: 'g',
                ),
              ),
              separador(),
              Expanded(
                child: _metrica(
                  icono: Icons.grain_rounded,
                  acento: tema.tertiary,
                  titulo: 'Carbos',
                  valor: carbos,
                  objetivo: objetivoCarbos,
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
                        'Hablar',
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
            alPulsar: () => _proximamente('El historial'),
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
            alPulsar: () => _proximamente('Las estadísticas'),
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

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _comidasHoyStream,
            builder: (context, snapComidas) {
              double kcal = 0;
              double proteina = 0;
              double carbos = 0;
              final comidas = snapComidas.data?.docs ?? [];
              for (final doc in comidas) {
                final datos = doc.data();
                kcal += _numero(datos['kcal']);
                proteina += _numero(datos['proteinaG']);
                carbos += _numero(datos['carbosG']);
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
                                    ),
                                    const SizedBox(height: 14),
                                    _tarjetaFuncion(
                                      icono: Icons.fitness_center_rounded,
                                      iconoFondo: _svgPesa(
                                          84, _tinte(tema.primary, 0.35)),
                                      acento: tema.primary,
                                      titulo: 'Entrenamiento',
                                      descripcion:
                                          'Dicta tu rutina y calculamos tu fuerza y los músculos trabajados.',
                                      textoBoton: 'Ver análisis',
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
                                      alHablar: () => _proximamente(
                                          'El registro de comidas'),
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
