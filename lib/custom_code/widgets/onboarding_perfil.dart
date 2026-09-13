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
import '/auth/firebase_auth/auth_util.dart';

class OnboardingPerfil extends StatefulWidget {
  const OnboardingPerfil({
    super.key,
    this.width,
    this.height,
    required this.onCompletado,
  });

  final double? width;
  final double? height;
  final Future Function() onCompletado;

  @override
  State<OnboardingPerfil> createState() => _OnboardingPerfilState();
}

class _OnboardingPerfilState extends State<OnboardingPerfil> {
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

  static const Map<String, String> _descripcionesActividad = {
    'sedentario': 'Trabajo sentado y poco o ningún ejercicio.',
    'ligero': 'Ejercicio 1–3 días por semana.',
    'moderado': 'Ejercicio 3–5 días por semana.',
    'alto': 'Ejercicio intenso 6–7 días por semana.',
    'muy_alto': 'Entrenamientos dobles o trabajo físico exigente.',
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

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  final TextEditingController _proteinaController = TextEditingController();
  final TextEditingController _carbosController = TextEditingController();
  final TextEditingController _grasaController = TextEditingController();

  String? _sexo;
  DateTime? _fechaNacimiento;
  String? _actividad;
  String? _objetivo;
  String? _pesoAlimentos;

  bool _calculado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _kcalController.dispose();
    _proteinaController.dispose();
    _carbosController.dispose();
    _grasaController.dispose();
    super.dispose();
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

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Color _tinte(Color color, double opacidad) {
    return color.withAlpha((255 * opacidad).round());
  }

  Color _aclarar(Color color, double cantidad) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + cantidad).clamp(0.0, 1.0))
        .toColor();
  }

  void _invalidarCalculo() {
    if (_calculado) {
      setState(() => _calculado = false);
    }
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

  // ---------- Acciones ----------

  Future<void> _elegirFecha() async {
    FocusScope.of(context).unfocus();
    final tema = FlutterFlowTheme.of(context);
    final ahora = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(ahora.year - 30, 1, 1),
      firstDate: DateTime(ahora.year - 100, 1, 1),
      lastDate: DateTime(ahora.year - 14, ahora.month, ahora.day),
      helpText: 'Fecha de nacimiento',
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
    if (seleccion != null && mounted) {
      setState(() {
        _fechaNacimiento = seleccion;
        _calculado = false;
      });
    }
  }

  void _calcular() {
    FocusScope.of(context).unfocus();

    final nombre = _nombreController.text.trim();
    final altura = _leerInt(_alturaController.text);
    final peso = _leerDouble(_pesoController.text);

    final errores = <String>[];
    if (nombre.isEmpty || nombre.length > 40) errores.add('nombre');
    if (_sexo == null) errores.add('sexo');
    if (_fechaNacimiento == null) errores.add('fecha de nacimiento');
    if (altura == null || altura < 120 || altura > 230) {
      errores.add('altura (120–230 cm)');
    }
    if (peso == null || peso < 30 || peso > 250) {
      errores.add('peso (30–250 kg)');
    }
    if (_actividad == null) errores.add('nivel de actividad');
    if (_objetivo == null) errores.add('objetivo');
    if (_pesoAlimentos == null) errores.add('cómo pesas los alimentos');

    if (errores.isNotEmpty) {
      _mostrarMensaje('Revisa: ${errores.join(', ')}');
      return;
    }

    final resultado = calcularObjetivos(
      _sexo!,
      peso!,
      altura!,
      _fechaNacimiento!,
      _actividad!,
      _objetivo!,
    );

    setState(() {
      _kcalController.text = resultado.kcal.toString();
      _proteinaController.text = resultado.proteinaG.toString();
      _carbosController.text = resultado.carbosG.toString();
      _grasaController.text = resultado.grasaG.toString();
      _calculado = true;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final nombre = _nombreController.text.trim();
    final altura = _leerInt(_alturaController.text);
    final peso = _leerDouble(_pesoController.text);
    final kcal = _leerInt(_kcalController.text);
    final proteina = _leerInt(_proteinaController.text);
    final carbos = _leerInt(_carbosController.text);
    final grasa = _leerInt(_grasaController.text);

    if (nombre.isEmpty || nombre.length > 40) {
      _mostrarMensaje('Escribe tu nombre (máximo 40 caracteres).');
      return;
    }
    if (altura == null ||
        peso == null ||
        _sexo == null ||
        _fechaNacimiento == null ||
        _pesoAlimentos == null) {
      _mostrarMensaje('Faltan datos del perfil. Vuelve a calcular.');
      return;
    }
    if (kcal == null || kcal < 1000 || kcal > 6000) {
      _mostrarMensaje('Las calorías deben estar entre 1000 y 6000.');
      return;
    }
    if (proteina == null ||
        carbos == null ||
        grasa == null ||
        proteina < 0 ||
        carbos < 0 ||
        grasa < 0) {
      _mostrarMensaje('Revisa los gramos de proteína, carbohidratos y grasa.');
      return;
    }

    final userRef = currentUserReference;
    if (userRef == null) {
      _mostrarMensaje('No hay ninguna sesión iniciada.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await userRef.set(
        {
          'display_name': nombre,
          'pesoKg': peso,
          'alturaCm': altura,
          'fechaNacimiento': _fechaNacimiento,
          'sexo': _sexo,
          'pesoAlimentos': _pesoAlimentos,
          'objetivoKcal': kcal,
          'objetivoProteinaG': proteina,
          'objetivoCarbosG': carbos,
          'objetivoGrasaG': grasa,
        },
        SetOptions(merge: true),
      );

      await userRef.collection('pesos').add({
        'fecha': DateTime.now(),
        'pesoKg': peso,
      });

      if (!mounted) return;
      await widget.onCompletado();
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
            'No se pudo guardar. Comprueba la conexión e inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
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
            color: _tinte(acento, 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icono, color: Colors.white, size: tamano * 0.5),
    );
  }

  Widget _tarjetaSeccion({
    required IconData icono,
    required Color acento,
    required String titulo,
    required List<Widget> hijos,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6],
          colors: [
            Color.alphaBlend(_tinte(acento, 0.14), tema.secondaryBackground),
            tema.secondaryBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _insignia(icono, acento, 36),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: tema.titleMedium.copyWith(
                  color: tema.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ...hijos,
        ],
      ),
    );
  }

  Widget _etiqueta(String texto) {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        texto,
        style: tema.bodyMedium.copyWith(
          color: tema.secondaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _pildoras(
    Map<String, String> opciones,
    String? seleccionado,
    Color acento,
    ValueChanged<String> alElegir,
  ) {
    final tema = FlutterFlowTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones.entries.map((opcion) {
        final activo = opcion.key == seleccionado;
        return GestureDetector(
          onTap: _guardando ? null : () => alElegir(opcion.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: activo ? _tinte(acento, 0.20) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: activo ? acento : tema.alternate,
                width: activo ? 1.5 : 1.0,
              ),
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

  InputDecoration _decoracionCampo(
    String pista, {
    String? sufijo,
    Color? acento,
  }) {
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
    bool invalida = true,
    TextAlign alineacion = TextAlign.start,
    Color? acento,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return TextField(
      controller: controller,
      enabled: !_guardando,
      keyboardType: teclado,
      keyboardAppearance: Brightness.dark,
      textCapitalization: capitalizacion,
      textAlign: alineacion,
      cursorColor: acento ?? tema.primary,
      onChanged: invalida ? (_) => _invalidarCalculo() : null,
      style: tema.bodyLarge.copyWith(color: tema.primaryText),
      decoration: _decoracionCampo(pista, sufijo: sufijo, acento: acento),
    );
  }

  Widget _selectorFecha() {
    final tema = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _guardando ? null : _elegirFecha,
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
                  _fechaNacimiento == null
                      ? 'Elegir fecha'
                      : _formatearFecha(_fechaNacimiento!),
                  style: tema.bodyLarge.copyWith(
                    color: _fechaNacimiento == null
                        ? _tinte(tema.secondaryText, 0.7)
                        : tema.primaryText,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: tema.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaObjetivo({
    required IconData icono,
    required Color acento,
    required String etiqueta,
    required String unidad,
    required TextEditingController controller,
    bool ultima = false,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border:
            ultima ? null : Border(bottom: BorderSide(color: tema.alternate)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tinte(acento, 0.18),
            ),
            child: Icon(icono, size: 18, color: acento),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              etiqueta,
              style: tema.bodyLarge.copyWith(color: tema.primaryText),
            ),
          ),
          SizedBox(
            width: 128,
            child: _campoTexto(
              controller,
              '0',
              teclado: const TextInputType.numberWithOptions(decimal: false),
              sufijo: unidad,
              invalida: false,
              alineacion: TextAlign.right,
              acento: acento,
            ),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera
              Row(
                children: [
                  _insignia(Icons.graphic_eq_rounded, tema.primary, 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuéntanos sobre ti',
                          style: tema.headlineSmall.copyWith(
                            color: tema.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Calculamos tus objetivos diarios de calorías y macros.',
                          style: tema.bodyMedium
                              .copyWith(color: tema.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Tus datos
              _tarjetaSeccion(
                icono: Icons.person_rounded,
                acento: tema.primary,
                titulo: 'Tus datos',
                hijos: [
                  _etiqueta('¿Cómo te llamas?'),
                  _campoTexto(
                    _nombreController,
                    'Tu nombre',
                    teclado: TextInputType.name,
                    capitalizacion: TextCapitalization.words,
                    invalida: false,
                  ),
                  _etiqueta('Sexo'),
                  _pildoras(_opcionesSexo, _sexo, tema.primary, (valor) {
                    setState(() {
                      _sexo = valor;
                      _calculado = false;
                    });
                  }),
                  _etiqueta('Fecha de nacimiento'),
                  _selectorFecha(),
                  _etiqueta('Altura y peso'),
                  Row(
                    children: [
                      Expanded(
                        child: _campoTexto(
                          _alturaController,
                          'Altura',
                          teclado: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          sufijo: 'cm',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campoTexto(
                          _pesoController,
                          'Peso',
                          teclado: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          sufijo: 'kg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Tu actividad
              _tarjetaSeccion(
                icono: Icons.bolt_rounded,
                acento: tema.tertiary,
                titulo: 'Tu actividad',
                hijos: [
                  _etiqueta('Nivel de actividad'),
                  _pildoras(_opcionesActividad, _actividad, tema.tertiary,
                      (valor) {
                    setState(() {
                      _actividad = valor;
                      _calculado = false;
                    });
                  }),
                  if (_actividad != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _descripcionesActividad[_actividad] ?? '',
                        style:
                            tema.bodySmall.copyWith(color: tema.secondaryText),
                      ),
                    ),
                  _etiqueta('Objetivo'),
                  _pildoras(_opcionesObjetivo, _objetivo, tema.tertiary,
                      (valor) {
                    setState(() {
                      _objetivo = valor;
                      _calculado = false;
                    });
                  }),
                ],
              ),

              // Nutrición
              _tarjetaSeccion(
                icono: Icons.eco_rounded,
                acento: tema.secondary,
                titulo: 'Nutrición',
                hijos: [
                  _etiqueta('¿Cómo pesas los alimentos?'),
                  _pildoras(
                      _opcionesPesoAlimentos, _pesoAlimentos, tema.secondary,
                      (valor) {
                    setState(() {
                      _pesoAlimentos = valor;
                      _calculado = false;
                    });
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Así interpretamos bien los gramos que dictes.',
                      style: tema.bodySmall.copyWith(color: tema.secondaryText),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _botonGradiente(
                texto: _calculado ? 'Recalcular' : 'Calcular objetivos',
                icono: Icons.auto_awesome_rounded,
                acento: tema.primary,
                alPulsar: _guardando ? null : _calcular,
              ),

              if (_calculado) ...[
                _tarjetaSeccion(
                  icono: Icons.insights_rounded,
                  acento: tema.primary,
                  titulo: 'Tus objetivos diarios',
                  hijos: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Text(
                        'Calculados con la fórmula de Mifflin-St Jeor. Puedes ajustarlos.',
                        style:
                            tema.bodySmall.copyWith(color: tema.secondaryText),
                      ),
                    ),
                    _filaObjetivo(
                      icono: Icons.local_fire_department_rounded,
                      acento: tema.error,
                      etiqueta: 'Calorías',
                      unidad: 'kcal',
                      controller: _kcalController,
                    ),
                    _filaObjetivo(
                      icono: Icons.bolt_rounded,
                      acento: tema.secondary,
                      etiqueta: 'Proteína',
                      unidad: 'g',
                      controller: _proteinaController,
                    ),
                    _filaObjetivo(
                      icono: Icons.grain_rounded,
                      acento: tema.tertiary,
                      etiqueta: 'Carbohidratos',
                      unidad: 'g',
                      controller: _carbosController,
                    ),
                    _filaObjetivo(
                      icono: Icons.water_drop_rounded,
                      acento: tema.primary,
                      etiqueta: 'Grasa',
                      unidad: 'g',
                      controller: _grasaController,
                      ultima: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _botonGradiente(
                  texto: 'Guardar y empezar',
                  icono: Icons.arrow_forward_rounded,
                  acento: tema.secondary,
                  alPulsar: _guardando ? null : _guardar,
                  cargando: _guardando,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
