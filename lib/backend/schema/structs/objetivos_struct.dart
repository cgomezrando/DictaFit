// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ObjetivosStruct extends FFFirebaseStruct {
  ObjetivosStruct({
    int? kcal,
    int? proteinaG,
    int? carbosG,
    int? grasaG,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _kcal = kcal,
        _proteinaG = proteinaG,
        _carbosG = carbosG,
        _grasaG = grasaG,
        super(firestoreUtilData);

  // "kcal" field.
  int? _kcal;
  int get kcal => _kcal ?? 0;
  set kcal(int? val) => _kcal = val;

  void incrementKcal(int amount) => kcal = kcal + amount;

  bool hasKcal() => _kcal != null;

  // "proteinaG" field.
  int? _proteinaG;
  int get proteinaG => _proteinaG ?? 0;
  set proteinaG(int? val) => _proteinaG = val;

  void incrementProteinaG(int amount) => proteinaG = proteinaG + amount;

  bool hasProteinaG() => _proteinaG != null;

  // "carbosG" field.
  int? _carbosG;
  int get carbosG => _carbosG ?? 0;
  set carbosG(int? val) => _carbosG = val;

  void incrementCarbosG(int amount) => carbosG = carbosG + amount;

  bool hasCarbosG() => _carbosG != null;

  // "grasaG" field.
  int? _grasaG;
  int get grasaG => _grasaG ?? 0;
  set grasaG(int? val) => _grasaG = val;

  void incrementGrasaG(int amount) => grasaG = grasaG + amount;

  bool hasGrasaG() => _grasaG != null;

  static ObjetivosStruct fromMap(Map<String, dynamic> data) => ObjetivosStruct(
        kcal: castToType<int>(data['kcal']),
        proteinaG: castToType<int>(data['proteinaG']),
        carbosG: castToType<int>(data['carbosG']),
        grasaG: castToType<int>(data['grasaG']),
      );

  static ObjetivosStruct? maybeFromMap(dynamic data) => data is Map
      ? ObjetivosStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'kcal': _kcal,
        'proteinaG': _proteinaG,
        'carbosG': _carbosG,
        'grasaG': _grasaG,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'kcal': serializeParam(
          _kcal,
          ParamType.int,
        ),
        'proteinaG': serializeParam(
          _proteinaG,
          ParamType.int,
        ),
        'carbosG': serializeParam(
          _carbosG,
          ParamType.int,
        ),
        'grasaG': serializeParam(
          _grasaG,
          ParamType.int,
        ),
      }.withoutNulls;

  static ObjetivosStruct fromSerializableMap(Map<String, dynamic> data) =>
      ObjetivosStruct(
        kcal: deserializeParam(
          data['kcal'],
          ParamType.int,
          false,
        ),
        proteinaG: deserializeParam(
          data['proteinaG'],
          ParamType.int,
          false,
        ),
        carbosG: deserializeParam(
          data['carbosG'],
          ParamType.int,
          false,
        ),
        grasaG: deserializeParam(
          data['grasaG'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'ObjetivosStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ObjetivosStruct &&
        kcal == other.kcal &&
        proteinaG == other.proteinaG &&
        carbosG == other.carbosG &&
        grasaG == other.grasaG;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([kcal, proteinaG, carbosG, grasaG]);
}

ObjetivosStruct createObjetivosStruct({
  int? kcal,
  int? proteinaG,
  int? carbosG,
  int? grasaG,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ObjetivosStruct(
      kcal: kcal,
      proteinaG: proteinaG,
      carbosG: carbosG,
      grasaG: grasaG,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ObjetivosStruct? updateObjetivosStruct(
  ObjetivosStruct? objetivos, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    objetivos
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addObjetivosStructData(
  Map<String, dynamic> firestoreData,
  ObjetivosStruct? objetivos,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (objetivos == null) {
    return;
  }
  if (objetivos.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && objetivos.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final objetivosData = getObjetivosFirestoreData(objetivos, forFieldValue);
  final nestedData = objetivosData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = objetivos.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getObjetivosFirestoreData(
  ObjetivosStruct? objetivos, [
  bool forFieldValue = false,
]) {
  if (objetivos == null) {
    return {};
  }
  final firestoreData = mapToFirestore(objetivos.toMap());

  // Add any Firestore field values
  mapToFirestore(objetivos.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getObjetivosListFirestoreData(
  List<ObjetivosStruct>? objetivoss,
) =>
    objetivoss?.map((e) => getObjetivosFirestoreData(e, true)).toList() ?? [];
