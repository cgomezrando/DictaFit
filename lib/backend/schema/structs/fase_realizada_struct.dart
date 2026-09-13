// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FaseRealizadaStruct extends FFFirebaseStruct {
  FaseRealizadaStruct({
    String? nombre,
    String? tipo,
    int? ronda,
    int? segundos,
    int? fcInicio,
    int? fcFin,
    int? fcMax,
    String? finPor,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _nombre = nombre,
        _tipo = tipo,
        _ronda = ronda,
        _segundos = segundos,
        _fcInicio = fcInicio,
        _fcFin = fcFin,
        _fcMax = fcMax,
        _finPor = finPor,
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

  // "ronda" field.
  int? _ronda;
  int get ronda => _ronda ?? 0;
  set ronda(int? val) => _ronda = val;

  void incrementRonda(int amount) => ronda = ronda + amount;

  bool hasRonda() => _ronda != null;

  // "segundos" field.
  int? _segundos;
  int get segundos => _segundos ?? 0;
  set segundos(int? val) => _segundos = val;

  void incrementSegundos(int amount) => segundos = segundos + amount;

  bool hasSegundos() => _segundos != null;

  // "fcInicio" field.
  int? _fcInicio;
  int get fcInicio => _fcInicio ?? 0;
  set fcInicio(int? val) => _fcInicio = val;

  void incrementFcInicio(int amount) => fcInicio = fcInicio + amount;

  bool hasFcInicio() => _fcInicio != null;

  // "fcFin" field.
  int? _fcFin;
  int get fcFin => _fcFin ?? 0;
  set fcFin(int? val) => _fcFin = val;

  void incrementFcFin(int amount) => fcFin = fcFin + amount;

  bool hasFcFin() => _fcFin != null;

  // "fcMax" field.
  int? _fcMax;
  int get fcMax => _fcMax ?? 0;
  set fcMax(int? val) => _fcMax = val;

  void incrementFcMax(int amount) => fcMax = fcMax + amount;

  bool hasFcMax() => _fcMax != null;

  // "finPor" field.
  String? _finPor;
  String get finPor => _finPor ?? '';
  set finPor(String? val) => _finPor = val;

  bool hasFinPor() => _finPor != null;

  static FaseRealizadaStruct fromMap(Map<String, dynamic> data) =>
      FaseRealizadaStruct(
        nombre: data['nombre'] as String?,
        tipo: data['tipo'] as String?,
        ronda: castToType<int>(data['ronda']),
        segundos: castToType<int>(data['segundos']),
        fcInicio: castToType<int>(data['fcInicio']),
        fcFin: castToType<int>(data['fcFin']),
        fcMax: castToType<int>(data['fcMax']),
        finPor: data['finPor'] as String?,
      );

  static FaseRealizadaStruct? maybeFromMap(dynamic data) => data is Map
      ? FaseRealizadaStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'nombre': _nombre,
        'tipo': _tipo,
        'ronda': _ronda,
        'segundos': _segundos,
        'fcInicio': _fcInicio,
        'fcFin': _fcFin,
        'fcMax': _fcMax,
        'finPor': _finPor,
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
        'ronda': serializeParam(
          _ronda,
          ParamType.int,
        ),
        'segundos': serializeParam(
          _segundos,
          ParamType.int,
        ),
        'fcInicio': serializeParam(
          _fcInicio,
          ParamType.int,
        ),
        'fcFin': serializeParam(
          _fcFin,
          ParamType.int,
        ),
        'fcMax': serializeParam(
          _fcMax,
          ParamType.int,
        ),
        'finPor': serializeParam(
          _finPor,
          ParamType.String,
        ),
      }.withoutNulls;

  static FaseRealizadaStruct fromSerializableMap(Map<String, dynamic> data) =>
      FaseRealizadaStruct(
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
        ronda: deserializeParam(
          data['ronda'],
          ParamType.int,
          false,
        ),
        segundos: deserializeParam(
          data['segundos'],
          ParamType.int,
          false,
        ),
        fcInicio: deserializeParam(
          data['fcInicio'],
          ParamType.int,
          false,
        ),
        fcFin: deserializeParam(
          data['fcFin'],
          ParamType.int,
          false,
        ),
        fcMax: deserializeParam(
          data['fcMax'],
          ParamType.int,
          false,
        ),
        finPor: deserializeParam(
          data['finPor'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'FaseRealizadaStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is FaseRealizadaStruct &&
        nombre == other.nombre &&
        tipo == other.tipo &&
        ronda == other.ronda &&
        segundos == other.segundos &&
        fcInicio == other.fcInicio &&
        fcFin == other.fcFin &&
        fcMax == other.fcMax &&
        finPor == other.finPor;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([nombre, tipo, ronda, segundos, fcInicio, fcFin, fcMax, finPor]);
}

FaseRealizadaStruct createFaseRealizadaStruct({
  String? nombre,
  String? tipo,
  int? ronda,
  int? segundos,
  int? fcInicio,
  int? fcFin,
  int? fcMax,
  String? finPor,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    FaseRealizadaStruct(
      nombre: nombre,
      tipo: tipo,
      ronda: ronda,
      segundos: segundos,
      fcInicio: fcInicio,
      fcFin: fcFin,
      fcMax: fcMax,
      finPor: finPor,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

FaseRealizadaStruct? updateFaseRealizadaStruct(
  FaseRealizadaStruct? faseRealizada, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    faseRealizada
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addFaseRealizadaStructData(
  Map<String, dynamic> firestoreData,
  FaseRealizadaStruct? faseRealizada,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (faseRealizada == null) {
    return;
  }
  if (faseRealizada.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && faseRealizada.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final faseRealizadaData =
      getFaseRealizadaFirestoreData(faseRealizada, forFieldValue);
  final nestedData =
      faseRealizadaData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = faseRealizada.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getFaseRealizadaFirestoreData(
  FaseRealizadaStruct? faseRealizada, [
  bool forFieldValue = false,
]) {
  if (faseRealizada == null) {
    return {};
  }
  final firestoreData = mapToFirestore(faseRealizada.toMap());

  // Add any Firestore field values
  mapToFirestore(faseRealizada.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getFaseRealizadaListFirestoreData(
  List<FaseRealizadaStruct>? faseRealizadas,
) =>
    faseRealizadas
        ?.map((e) => getFaseRealizadaFirestoreData(e, true))
        .toList() ??
    [];
