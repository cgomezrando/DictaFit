// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FaseStruct extends FFFirebaseStruct {
  FaseStruct({
    String? nombre,
    String? tipo,
    String? modo,
    int? segundos,
    int? fcObjetivo,
    int? minSegundos,
    int? maxSegundos,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _nombre = nombre,
        _tipo = tipo,
        _modo = modo,
        _segundos = segundos,
        _fcObjetivo = fcObjetivo,
        _minSegundos = minSegundos,
        _maxSegundos = maxSegundos,
        super(firestoreUtilData);

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "tipo" field.
  String? _tipo;
  String get tipo => _tipo ?? '';
  set tipo(String? val) => _tipo = val;

  bool hasTipo() => _tipo != null;

  // "modo" field.
  String? _modo;
  String get modo => _modo ?? '';
  set modo(String? val) => _modo = val;

  bool hasModo() => _modo != null;

  // "segundos" field.
  int? _segundos;
  int get segundos => _segundos ?? 0;
  set segundos(int? val) => _segundos = val;

  void incrementSegundos(int amount) => segundos = segundos + amount;

  bool hasSegundos() => _segundos != null;

  // "fcObjetivo" field.
  int? _fcObjetivo;
  int get fcObjetivo => _fcObjetivo ?? 0;
  set fcObjetivo(int? val) => _fcObjetivo = val;

  void incrementFcObjetivo(int amount) => fcObjetivo = fcObjetivo + amount;

  bool hasFcObjetivo() => _fcObjetivo != null;

  // "minSegundos" field.
  int? _minSegundos;
  int get minSegundos => _minSegundos ?? 0;
  set minSegundos(int? val) => _minSegundos = val;

  void incrementMinSegundos(int amount) => minSegundos = minSegundos + amount;

  bool hasMinSegundos() => _minSegundos != null;

  // "maxSegundos" field.
  int? _maxSegundos;
  int get maxSegundos => _maxSegundos ?? 0;
  set maxSegundos(int? val) => _maxSegundos = val;

  void incrementMaxSegundos(int amount) => maxSegundos = maxSegundos + amount;

  bool hasMaxSegundos() => _maxSegundos != null;

  static FaseStruct fromMap(Map<String, dynamic> data) => FaseStruct(
        nombre: data['nombre'] as String?,
        tipo: data['tipo'] as String?,
        modo: data['modo'] as String?,
        segundos: castToType<int>(data['segundos']),
        fcObjetivo: castToType<int>(data['fcObjetivo']),
        minSegundos: castToType<int>(data['minSegundos']),
        maxSegundos: castToType<int>(data['maxSegundos']),
      );

  static FaseStruct? maybeFromMap(dynamic data) =>
      data is Map ? FaseStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'nombre': _nombre,
        'tipo': _tipo,
        'modo': _modo,
        'segundos': _segundos,
        'fcObjetivo': _fcObjetivo,
        'minSegundos': _minSegundos,
        'maxSegundos': _maxSegundos,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'nombre': serializeParam(
          _nombre,
          ParamType.String,
        ),
        'tipo': serializeParam(
          _tipo,
          ParamType.String,
        ),
        'modo': serializeParam(
          _modo,
          ParamType.String,
        ),
        'segundos': serializeParam(
          _segundos,
          ParamType.int,
        ),
        'fcObjetivo': serializeParam(
          _fcObjetivo,
          ParamType.int,
        ),
        'minSegundos': serializeParam(
          _minSegundos,
          ParamType.int,
        ),
        'maxSegundos': serializeParam(
          _maxSegundos,
          ParamType.int,
        ),
      }.withoutNulls;

  static FaseStruct fromSerializableMap(Map<String, dynamic> data) =>
      FaseStruct(
        nombre: deserializeParam(
          data['nombre'],
          ParamType.String,
          false,
        ),
        tipo: deserializeParam(
          data['tipo'],
          ParamType.String,
          false,
        ),
        modo: deserializeParam(
          data['modo'],
          ParamType.String,
          false,
        ),
        segundos: deserializeParam(
          data['segundos'],
          ParamType.int,
          false,
        ),
        fcObjetivo: deserializeParam(
          data['fcObjetivo'],
          ParamType.int,
          false,
        ),
        minSegundos: deserializeParam(
          data['minSegundos'],
          ParamType.int,
          false,
        ),
        maxSegundos: deserializeParam(
          data['maxSegundos'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'FaseStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is FaseStruct &&
        nombre == other.nombre &&
        tipo == other.tipo &&
        modo == other.modo &&
        segundos == other.segundos &&
        fcObjetivo == other.fcObjetivo &&
        minSegundos == other.minSegundos &&
        maxSegundos == other.maxSegundos;
  }

  @override
  int get hashCode => const ListEquality().hash(
      [nombre, tipo, modo, segundos, fcObjetivo, minSegundos, maxSegundos]);
}

FaseStruct createFaseStruct({
  String? nombre,
  String? tipo,
  String? modo,
  int? segundos,
  int? fcObjetivo,
  int? minSegundos,
  int? maxSegundos,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    FaseStruct(
      nombre: nombre,
      tipo: tipo,
      modo: modo,
      segundos: segundos,
      fcObjetivo: fcObjetivo,
      minSegundos: minSegundos,
      maxSegundos: maxSegundos,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

FaseStruct? updateFaseStruct(
  FaseStruct? fase, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    fase
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addFaseStructData(
  Map<String, dynamic> firestoreData,
  FaseStruct? fase,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (fase == null) {
    return;
  }
  if (fase.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && fase.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final faseData = getFaseFirestoreData(fase, forFieldValue);
  final nestedData = faseData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = fase.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getFaseFirestoreData(
  FaseStruct? fase, [
  bool forFieldValue = false,
]) {
  if (fase == null) {
    return {};
  }
  final firestoreData = mapToFirestore(fase.toMap());

  // Add any Firestore field values
  mapToFirestore(fase.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getFaseListFirestoreData(
  List<FaseStruct>? fases,
) =>
    fases?.map((e) => getFaseFirestoreData(e, true)).toList() ?? [];
