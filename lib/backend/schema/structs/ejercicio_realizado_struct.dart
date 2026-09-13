// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EjercicioRealizadoStruct extends FFFirebaseStruct {
  EjercicioRealizadoStruct({
    String? ejercicioId,
    String? nombre,
    int? inclinacionGrados,
    String? cargaPor,
    List<SerieStruct>? series,
    double? e1rmKg,
    double? ratioPeso,
    String? nivel,
    List<MusculoImplicadoStruct>? musculos,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _ejercicioId = ejercicioId,
        _nombre = nombre,
        _inclinacionGrados = inclinacionGrados,
        _cargaPor = cargaPor,
        _series = series,
        _e1rmKg = e1rmKg,
        _ratioPeso = ratioPeso,
        _nivel = nivel,
        _musculos = musculos,
        super(firestoreUtilData);

  // "ejercicioId" field.
  String? _ejercicioId;
  String get ejercicioId => _ejercicioId ?? '';
  set ejercicioId(String? val) => _ejercicioId = val;

  bool hasEjercicioId() => _ejercicioId != null;

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "inclinacionGrados" field.
  int? _inclinacionGrados;
  int get inclinacionGrados => _inclinacionGrados ?? 0;
  set inclinacionGrados(int? val) => _inclinacionGrados = val;

  void incrementInclinacionGrados(int amount) =>
      inclinacionGrados = inclinacionGrados + amount;

  bool hasInclinacionGrados() => _inclinacionGrados != null;

  // "cargaPor" field.
  String? _cargaPor;
  String get cargaPor => _cargaPor ?? '';
  set cargaPor(String? val) => _cargaPor = val;

  bool hasCargaPor() => _cargaPor != null;

  // "series" field.
  List<SerieStruct>? _series;
  List<SerieStruct> get series => _series ?? const [];
  set series(List<SerieStruct>? val) => _series = val;

  void updateSeries(Function(List<SerieStruct>) updateFn) {
    updateFn(_series ??= []);
  }

  bool hasSeries() => _series != null;

  // "e1rmKg" field.
  double? _e1rmKg;
  double get e1rmKg => _e1rmKg ?? 0.0;
  set e1rmKg(double? val) => _e1rmKg = val;

  void incrementE1rmKg(double amount) => e1rmKg = e1rmKg + amount;

  bool hasE1rmKg() => _e1rmKg != null;

  // "ratioPeso" field.
  double? _ratioPeso;
  double get ratioPeso => _ratioPeso ?? 0.0;
  set ratioPeso(double? val) => _ratioPeso = val;

  void incrementRatioPeso(double amount) => ratioPeso = ratioPeso + amount;

  bool hasRatioPeso() => _ratioPeso != null;

  // "nivel" field.
  String? _nivel;
  String get nivel => _nivel ?? '';
  set nivel(String? val) => _nivel = val;

  bool hasNivel() => _nivel != null;

  // "musculos" field.
  List<MusculoImplicadoStruct>? _musculos;
  List<MusculoImplicadoStruct> get musculos => _musculos ?? const [];
  set musculos(List<MusculoImplicadoStruct>? val) => _musculos = val;

  void updateMusculos(Function(List<MusculoImplicadoStruct>) updateFn) {
    updateFn(_musculos ??= []);
  }

  bool hasMusculos() => _musculos != null;

  static EjercicioRealizadoStruct fromMap(Map<String, dynamic> data) =>
      EjercicioRealizadoStruct(
        ejercicioId: data['ejercicioId'] as String?,
        nombre: data['nombre'] as String?,
        inclinacionGrados: castToType<int>(data['inclinacionGrados']),
        cargaPor: data['cargaPor'] as String?,
        series: getStructList(
          data['series'],
          SerieStruct.fromMap,
        ),
        e1rmKg: castToType<double>(data['e1rmKg']),
        ratioPeso: castToType<double>(data['ratioPeso']),
        nivel: data['nivel'] as String?,
        musculos: getStructList(
          data['musculos'],
          MusculoImplicadoStruct.fromMap,
        ),
      );

  static EjercicioRealizadoStruct? maybeFromMap(dynamic data) => data is Map
      ? EjercicioRealizadoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'ejercicioId': _ejercicioId,
        'nombre': _nombre,
        'inclinacionGrados': _inclinacionGrados,
        'cargaPor': _cargaPor,
        'series': _series?.map((e) => e.toMap()).toList(),
        'e1rmKg': _e1rmKg,
        'ratioPeso': _ratioPeso,
        'nivel': _nivel,
        'musculos': _musculos?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'ejercicioId': serializeParam(
          _ejercicioId,
          ParamType.String,
        ),
        'nombre': serializeParam(
          _nombre,
          ParamType.String,
        ),
        'inclinacionGrados': serializeParam(
          _inclinacionGrados,
          ParamType.int,
        ),
        'cargaPor': serializeParam(
          _cargaPor,
          ParamType.String,
        ),
        'series': serializeParam(
          _series,
          ParamType.DataStruct,
          isList: true,
        ),
        'e1rmKg': serializeParam(
          _e1rmKg,
          ParamType.double,
        ),
        'ratioPeso': serializeParam(
          _ratioPeso,
          ParamType.double,
        ),
        'nivel': serializeParam(
          _nivel,
          ParamType.String,
        ),
        'musculos': serializeParam(
          _musculos,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static EjercicioRealizadoStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      EjercicioRealizadoStruct(
        ejercicioId: deserializeParam(
          data['ejercicioId'],
          ParamType.String,
          false,
        ),
        nombre: deserializeParam(
          data['nombre'],
          ParamType.String,
          false,
        ),
        inclinacionGrados: deserializeParam(
          data['inclinacionGrados'],
          ParamType.int,
          false,
        ),
        cargaPor: deserializeParam(
          data['cargaPor'],
          ParamType.String,
          false,
        ),
        series: deserializeStructParam<SerieStruct>(
          data['series'],
          ParamType.DataStruct,
          true,
          structBuilder: SerieStruct.fromSerializableMap,
        ),
        e1rmKg: deserializeParam(
          data['e1rmKg'],
          ParamType.double,
          false,
        ),
        ratioPeso: deserializeParam(
          data['ratioPeso'],
          ParamType.double,
          false,
        ),
        nivel: deserializeParam(
          data['nivel'],
          ParamType.String,
          false,
        ),
        musculos: deserializeStructParam<MusculoImplicadoStruct>(
          data['musculos'],
          ParamType.DataStruct,
          true,
          structBuilder: MusculoImplicadoStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'EjercicioRealizadoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is EjercicioRealizadoStruct &&
        ejercicioId == other.ejercicioId &&
        nombre == other.nombre &&
        inclinacionGrados == other.inclinacionGrados &&
        cargaPor == other.cargaPor &&
        listEquality.equals(series, other.series) &&
        e1rmKg == other.e1rmKg &&
        ratioPeso == other.ratioPeso &&
        nivel == other.nivel &&
        listEquality.equals(musculos, other.musculos);
  }

  @override
  int get hashCode => const ListEquality().hash([
        ejercicioId,
        nombre,
        inclinacionGrados,
        cargaPor,
        series,
        e1rmKg,
        ratioPeso,
        nivel,
        musculos
      ]);
}

EjercicioRealizadoStruct createEjercicioRealizadoStruct({
  String? ejercicioId,
  String? nombre,
  int? inclinacionGrados,
  String? cargaPor,
  double? e1rmKg,
  double? ratioPeso,
  String? nivel,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    EjercicioRealizadoStruct(
      ejercicioId: ejercicioId,
      nombre: nombre,
      inclinacionGrados: inclinacionGrados,
      cargaPor: cargaPor,
      e1rmKg: e1rmKg,
      ratioPeso: ratioPeso,
      nivel: nivel,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

EjercicioRealizadoStruct? updateEjercicioRealizadoStruct(
  EjercicioRealizadoStruct? ejercicioRealizado, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    ejercicioRealizado
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addEjercicioRealizadoStructData(
  Map<String, dynamic> firestoreData,
  EjercicioRealizadoStruct? ejercicioRealizado,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (ejercicioRealizado == null) {
    return;
  }
  if (ejercicioRealizado.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && ejercicioRealizado.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final ejercicioRealizadoData =
      getEjercicioRealizadoFirestoreData(ejercicioRealizado, forFieldValue);
  final nestedData =
      ejercicioRealizadoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      ejercicioRealizado.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getEjercicioRealizadoFirestoreData(
  EjercicioRealizadoStruct? ejercicioRealizado, [
  bool forFieldValue = false,
]) {
  if (ejercicioRealizado == null) {
    return {};
  }
  final firestoreData = mapToFirestore(ejercicioRealizado.toMap());

  // Add any Firestore field values
  mapToFirestore(ejercicioRealizado.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getEjercicioRealizadoListFirestoreData(
  List<EjercicioRealizadoStruct>? ejercicioRealizados,
) =>
    ejercicioRealizados
        ?.map((e) => getEjercicioRealizadoFirestoreData(e, true))
        .toList() ??
    [];
