// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SerieStruct extends FFFirebaseStruct {
  SerieStruct({
    double? kg,
    int? reps,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _kg = kg,
        _reps = reps,
        super(firestoreUtilData);

  // "kg" field.
  double? _kg;
  double get kg => _kg ?? 0.0;
  set kg(double? val) => _kg = val;

  void incrementKg(double amount) => kg = kg + amount;

  bool hasKg() => _kg != null;

  // "reps" field.
  int? _reps;
  int get reps => _reps ?? 0;
  set reps(int? val) => _reps = val;

  void incrementReps(int amount) => reps = reps + amount;

  bool hasReps() => _reps != null;

  static SerieStruct fromMap(Map<String, dynamic> data) => SerieStruct(
        kg: castToType<double>(data['kg']),
        reps: castToType<int>(data['reps']),
      );

  static SerieStruct? maybeFromMap(dynamic data) =>
      data is Map ? SerieStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'kg': _kg,
        'reps': _reps,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'kg': serializeParam(
          _kg,
          ParamType.double,
        ),
        'reps': serializeParam(
          _reps,
          ParamType.int,
        ),
      }.withoutNulls;

  static SerieStruct fromSerializableMap(Map<String, dynamic> data) =>
      SerieStruct(
        kg: deserializeParam(
          data['kg'],
          ParamType.double,
          false,
        ),
        reps: deserializeParam(
          data['reps'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'SerieStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SerieStruct && kg == other.kg && reps == other.reps;
  }

  @override
  int get hashCode => const ListEquality().hash([kg, reps]);
}

SerieStruct createSerieStruct({
  double? kg,
  int? reps,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    SerieStruct(
      kg: kg,
      reps: reps,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

SerieStruct? updateSerieStruct(
  SerieStruct? serie, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    serie
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addSerieStructData(
  Map<String, dynamic> firestoreData,
  SerieStruct? serie,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (serie == null) {
    return;
  }
  if (serie.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && serie.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final serieData = getSerieFirestoreData(serie, forFieldValue);
  final nestedData = serieData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = serie.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getSerieFirestoreData(
  SerieStruct? serie, [
  bool forFieldValue = false,
]) {
  if (serie == null) {
    return {};
  }
  final firestoreData = mapToFirestore(serie.toMap());

  // Add any Firestore field values
  mapToFirestore(serie.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getSerieListFirestoreData(
  List<SerieStruct>? series,
) =>
    series?.map((e) => getSerieFirestoreData(e, true)).toList() ?? [];
