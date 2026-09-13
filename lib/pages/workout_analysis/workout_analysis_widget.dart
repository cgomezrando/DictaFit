import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'workout_analysis_model.dart';
export 'workout_analysis_model.dart';

class WorkoutAnalysisWidget extends StatefulWidget {
  const WorkoutAnalysisWidget({
    super.key,
    this.entrenoRef,
  });

  final DocumentReference? entrenoRef;

  static String routeName = 'WorkoutAnalysis';
  static String routePath = '/workoutAnalysis';

  @override
  State<WorkoutAnalysisWidget> createState() => _WorkoutAnalysisWidgetState();
}

class _WorkoutAnalysisWidgetState extends State<WorkoutAnalysisWidget> {
  late WorkoutAnalysisModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutAnalysisModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: custom_widgets.MusculosEntrenamiento(
            width: double.infinity,
            height: double.infinity,
            entrenoRef: widget!.entrenoRef,
          ),
        ),
      ),
    );
  }
}
