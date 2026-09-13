// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/widgets/index.dart';

bool _onboardingAbierto = false;

Future comprobarOnboarding(BuildContext context) async {
  if (_onboardingAbierto) return;

  final userRef = currentUserReference;
  if (userRef == null) return;

  bool tienePerfil = false;
  try {
    final snap = await userRef.get();
    final datos = snap.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final peso = datos['pesoKg'];
    tienePerfil = peso is num && peso > 0;
  } catch (e) {
    // Sin conexión o error de lectura: no bloqueamos la app.
    return;
  }

  if (tienePerfil) return;
  if (!context.mounted) return;

  _onboardingAbierto = true;
  try {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: FlutterFlowTheme.of(ctx).primaryBackground,
              body: SafeArea(
                child: OnboardingPerfil(
                  onCompletado: () async {
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  } finally {
    _onboardingAbierto = false;
  }
}
