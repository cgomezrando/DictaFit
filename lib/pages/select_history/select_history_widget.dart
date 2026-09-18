import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'select_history_model.dart';
export 'select_history_model.dart';

class SelectHistoryWidget extends StatefulWidget {
  const SelectHistoryWidget({super.key});

  static String routeName = 'SelectHistory';
  static String routePath = '/selectHistory';

  @override
  State<SelectHistoryWidget> createState() => _SelectHistoryWidgetState();
}

class _SelectHistoryWidgetState extends State<SelectHistoryWidget> {
  late SelectHistoryModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SelectHistoryModel());
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
          child: custom_widgets.ElegirHistorial(
            width: double.infinity,
            height: double.infinity,
            onEntrenos: () async {
              context.pushNamed(HistoryWidget.routeName);
            },
            onComidas: () async {
              context.pushNamed(MealHistoryWidget.routeName);
            },
          ),
        ),
      ),
    );
  }
}
