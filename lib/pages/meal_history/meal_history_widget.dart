import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'meal_history_model.dart';
export 'meal_history_model.dart';

class MealHistoryWidget extends StatefulWidget {
  const MealHistoryWidget({super.key});

  static String routeName = 'MealHistory';
  static String routePath = '/mealHistory';

  @override
  State<MealHistoryWidget> createState() => _MealHistoryWidgetState();
}

class _MealHistoryWidgetState extends State<MealHistoryWidget> {
  late MealHistoryModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MealHistoryModel());
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
          child: custom_widgets.HistorialComidas(
            width: double.infinity,
            height: double.infinity,
            onEditarComida: () async {
              context.pushNamed(
                RecordMealWidget.routeName,
                queryParameters: {
                  'comidaParaEditar': serializeParam(
                    FFAppState().comidaGuardadaRef,
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
