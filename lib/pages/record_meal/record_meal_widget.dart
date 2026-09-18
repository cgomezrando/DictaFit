import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'record_meal_model.dart';
export 'record_meal_model.dart';

class RecordMealWidget extends StatefulWidget {
  const RecordMealWidget({super.key});

  static String routeName = 'RecordMeal';
  static String routePath = '/recordMeal';

  @override
  State<RecordMealWidget> createState() => _RecordMealWidgetState();
}

class _RecordMealWidgetState extends State<RecordMealWidget> {
  late RecordMealModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecordMealModel());
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
          child: custom_widgets.RegistroComida(
            width: double.infinity,
            height: double.infinity,
            onGuardado: () async {
              if (Navigator.of(context).canPop()) {
                context.pop();
              }
              context.pushNamed(HomeWidget.routeName);
            },
          ),
        ),
      ),
    );
  }
}
