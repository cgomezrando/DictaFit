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

class ElegirHistorial extends StatelessWidget {
  const ElegirHistorial({
    super.key,
    this.width,
    this.height,
    required this.onEntrenos,
    required this.onComidas,
  });

  final double? width;
  final double? height;

  /// Navega al historial de entrenos (la página History ya existente).
  final Future Function() onEntrenos;

  /// Navega al historial de comidas (la página MealHistory).
  final Future Function() onComidas;

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  Widget _tarjetaOpcion(
    BuildContext context, {
    required IconData icono,
    required Color acento,
    required String titulo,
    required String descripcion,
    required VoidCallback onPulsar,
  }) {
    final tema = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: onPulsar,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tema.alternate),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _tinte(acento, 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icono, color: acento, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: tema.titleSmall.copyWith(
                          color: tema.primaryText,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(descripcion,
                      style:
                          tema.bodySmall.copyWith(color: tema.secondaryText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tema.secondaryText),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: tema.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
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
                            color: tema.primaryText,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tarjetaOpcion(
                    context,
                    icono: Icons.fitness_center_rounded,
                    acento: tema.primary,
                    titulo: 'Entrenos',
                    descripcion: 'Tus sesiones de entrenamiento pasadas.',
                    onPulsar: () => onEntrenos(),
                  ),
                  _tarjetaOpcion(
                    context,
                    icono: Icons.eco_rounded,
                    acento: tema.secondary,
                    titulo: 'Comidas',
                    descripcion: 'Lo que has ido registrando de alimentación.',
                    onPulsar: () => onComidas(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
