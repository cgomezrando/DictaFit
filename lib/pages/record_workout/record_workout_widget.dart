import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'record_workout_model.dart';
export 'record_workout_model.dart';

class RecordWorkoutWidget extends StatefulWidget {
  const RecordWorkoutWidget({
    super.key,
    this.entrenoParaEditar,
  });

  final DocumentReference? entrenoParaEditar;

  static String routeName = 'RecordWorkout';
  static String routePath = '/recordWorkout';

  @override
  State<RecordWorkoutWidget> createState() => _RecordWorkoutWidgetState();
}

class _RecordWorkoutWidgetState extends State<RecordWorkoutWidget> {
  late RecordWorkoutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecordWorkoutModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: custom_widgets.RegistroEntreno(
            width: double.infinity,
            height: double.infinity,
            entrenoParaEditar: widget!.entrenoParaEditar,
            onGuardado: () async {
              if (Navigator.of(context).canPop()) {
                context.pop();
              }
              context.pushNamed(
                WorkoutAnalysisWidget.routeName,
                queryParameters: {
                  'entrenoRef': serializeParam(
                    FFAppState().entrenoGuardadoRef,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              );
            },
          ),
        ),
      ),
    );
  }
}
