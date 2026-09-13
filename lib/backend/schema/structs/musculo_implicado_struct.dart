// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MusculoImplicadoStruct extends FFFirebaseStruct {
  MusculoImplicadoStruct({
    String? musculo,
    String? rol,
    double? peso,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _musculo = musculo,
        _rol = rol,
        _peso = peso,
        super(firestoreUtilData);

  // "musculo" field.
  String? _musculo;
  String get musculo => _musculo ?? '';
  set musculo(String? val) => _musculo = val;

  bool hasMusculo() => _musculo != null;

  // "rol" field.
  String? _rol;
  String get rol => _rol ?? '';
  set rol(String? val) => _rol = val;

  bool hasRol() => _rol != null;

  // "peso" field.
  double? _peso;
  double get peso => _peso ?? 0.0;
  set peso(double? val) => _peso = val;

  void incrementPeso(double amount) => peso = peso + amount;

  bool hasPeso() => _peso != null;

  static MusculoImplicadoStruct fromMap(Map<String, dynamic> data) =>
      MusculoImplicadoStruct(
        musculo: data['musculo'] as String?,
        rol: data['rol'] as String?,
        peso: castToType<double>(data['peso']),
      );

  static MusculoImplicadoStruct? maybeFromMap(dynamic data) => data is Map
      ? MusculoImplicadoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'musculo': _musculo,
        'rol': _rol,
        'peso': _peso,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'musculo': serializeParam(
          _musculo,
          ParamType.String,
        ),
        'rol': serializeParam(
          _rol,
          ParamType.String,
        ),
        'peso': serializeParam(
          _peso,
          ParamType.double,
        ),
      }.withoutNulls;

  static MusculoImplicadoStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      MusculoImplicadoStruct(
        musculo: deserializeParam(
          data['musculo'],
          ParamType.String,
          false,
        ),
        rol: deserializeParam(
          data['rol'],
          ParamType.String,
          false,
        ),
        peso: deserializeParam(
          data['peso'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'MusculoImplicadoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MusculoImplicadoStruct &&
        musculo == other.musculo &&
        rol == other.rol &&
        peso == other.peso;
  }

  @override
  int get hashCode => const ListEquality().hash([musculo, rol, peso]);
}

MusculoImplicadoStruct createMusculoImplicadoStruct({
  String? musculo,
  String? rol,
  double? peso,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MusculoImplicadoStruct(
      musculo: musculo,
      rol: rol,
      peso: peso,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MusculoImplicadoStruct? updateMusculoImplicadoStruct(
  MusculoImplicadoStruct? musculoImplicado, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    musculoImplicado
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMusculoImplicadoStructData(
  Map<String, dynamic> firestoreData,
  MusculoImplicadoStruct? musculoImplicado,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (musculoImplicado == null) {
    return;
  }
  if (musculoImplicado.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && musculoImplicado.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final musculoImplicadoData =
      getMusculoImplicadoFirestoreData(musculoImplicado, forFieldValue);
  final nestedData =
      musculoImplicadoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = musculoImplicado.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMusculoImplicadoFirestoreData(
  MusculoImplicadoStruct? musculoImplicado, [
  bool forFieldValue = false,
]) {
  if (musculoImplicado == null) {
    return {};
  }
  final firestoreData = mapToFirestore(musculoImplicado.toMap());

  // Add any Firestore field values
  mapToFirestore(musculoImplicado.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMusculoImplicadoListFirestoreData(
  List<MusculoImplicadoStruct>? musculoImplicados,
) =>
    musculoImplicados
        ?.map((e) => getMusculoImplicadoFirestoreData(e, true))
        .toList() ??
    [];
