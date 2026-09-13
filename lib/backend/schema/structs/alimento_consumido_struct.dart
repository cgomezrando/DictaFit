// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AlimentoConsumidoStruct extends FFFirebaseStruct {
  AlimentoConsumidoStruct({
    String? alimentoId,
    String? nombre,
    double? gramos,
    String? preparacion,
    double? kcal100,
    double? proteina100,
    double? carbos100,
    double? grasa100,
    double? kcal,
    double? proteinaG,
    double? carbosG,
    double? grasaG,
    bool? supuesto,
    String? notaSupuesto,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _alimentoId = alimentoId,
        _nombre = nombre,
        _gramos = gramos,
        _preparacion = preparacion,
        _kcal100 = kcal100,
        _proteina100 = proteina100,
        _carbos100 = carbos100,
        _grasa100 = grasa100,
        _kcal = kcal,
        _proteinaG = proteinaG,
        _carbosG = carbosG,
        _grasaG = grasaG,
        _supuesto = supuesto,
        _notaSupuesto = notaSupuesto,
        super(firestoreUtilData);

  // "alimentoId" field.
  String? _alimentoId;
  String get alimentoId => _alimentoId ?? '';
  set alimentoId(String? val) => _alimentoId = val;

  bool hasAlimentoId() => _alimentoId != null;

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "gramos" field.
  double? _gramos;
  double get gramos => _gramos ?? 0.0;
  set gramos(double? val) => _gramos = val;

  void incrementGramos(double amount) => gramos = gramos + amount;

  bool hasGramos() => _gramos != null;

  // "preparacion" field.
  String? _preparacion;
  String get preparacion => _preparacion ?? '';
  set preparacion(String? val) => _preparacion = val;

  bool hasPreparacion() => _preparacion != null;

  // "kcal100" field.
  double? _kcal100;
  double get kcal100 => _kcal100 ?? 0.0;
  set kcal100(double? val) => _kcal100 = val;

  void incrementKcal100(double amount) => kcal100 = kcal100 + amount;

  bool hasKcal100() => _kcal100 != null;

  // "proteina100" field.
  double? _proteina100;
  double get proteina100 => _proteina100 ?? 0.0;
  set proteina100(double? val) => _proteina100 = val;

  void incrementProteina100(double amount) =>
      proteina100 = proteina100 + amount;

  bool hasProteina100() => _proteina100 != null;

  // "carbos100" field.
  double? _carbos100;
  double get carbos100 => _carbos100 ?? 0.0;
  set carbos100(double? val) => _carbos100 = val;

  void incrementCarbos100(double amount) => carbos100 = carbos100 + amount;

  bool hasCarbos100() => _carbos100 != null;

  // "grasa100" field.
  double? _grasa100;
  double get grasa100 => _grasa100 ?? 0.0;
  set grasa100(double? val) => _grasa100 = val;

  void incrementGrasa100(double amount) => grasa100 = grasa100 + amount;

  bool hasGrasa100() => _grasa100 != null;

  // "kcal" field.
  double? _kcal;
  double get kcal => _kcal ?? 0.0;
  set kcal(double? val) => _kcal = val;

  void incrementKcal(double amount) => kcal = kcal + amount;

  bool hasKcal() => _kcal != null;

  // "proteinaG" field.
  double? _proteinaG;
  double get proteinaG => _proteinaG ?? 0.0;
  set proteinaG(double? val) => _proteinaG = val;

  void incrementProteinaG(double amount) => proteinaG = proteinaG + amount;

  bool hasProteinaG() => _proteinaG != null;

  // "carbosG" field.
  double? _carbosG;
  double get carbosG => _carbosG ?? 0.0;
  set carbosG(double? val) => _carbosG = val;

  void incrementCarbosG(double amount) => carbosG = carbosG + amount;

  bool hasCarbosG() => _carbosG != null;

  // "grasaG" field.
  double? _grasaG;
  double get grasaG => _grasaG ?? 0.0;
  set grasaG(double? val) => _grasaG = val;

  void incrementGrasaG(double amount) => grasaG = grasaG + amount;

  bool hasGrasaG() => _grasaG != null;

  // "supuesto" field.
  bool? _supuesto;
  bool get supuesto => _supuesto ?? false;
  set supuesto(bool? val) => _supuesto = val;

  bool hasSupuesto() => _supuesto != null;

  // "notaSupuesto" field.
  String? _notaSupuesto;
  String get notaSupuesto => _notaSupuesto ?? '';
  set notaSupuesto(String? val) => _notaSupuesto = val;

  bool hasNotaSupuesto() => _notaSupuesto != null;

  static AlimentoConsumidoStruct fromMap(Map<String, dynamic> data) =>
      AlimentoConsumidoStruct(
        alimentoId: data['alimentoId'] as String?,
        nombre: data['nombre'] as String?,
        gramos: castToType<double>(data['gramos']),
        preparacion: data['preparacion'] as String?,
        kcal100: castToType<double>(data['kcal100']),
        proteina100: castToType<double>(data['proteina100']),
        carbos100: castToType<double>(data['carbos100']),
        grasa100: castToType<double>(data['grasa100']),
        kcal: castToType<double>(data['kcal']),
        proteinaG: castToType<double>(data['proteinaG']),
        carbosG: castToType<double>(data['carbosG']),
        grasaG: castToType<double>(data['grasaG']),
        supuesto: data['supuesto'] as bool?,
        notaSupuesto: data['notaSupuesto'] as String?,
      );

  static AlimentoConsumidoStruct? maybeFromMap(dynamic data) => data is Map
      ? AlimentoConsumidoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'alimentoId': _alimentoId,
        'nombre': _nombre,
        'gramos': _gramos,
        'preparacion': _preparacion,
        'kcal100': _kcal100,
        'proteina100': _proteina100,
        'carbos100': _carbos100,
        'grasa100': _grasa100,
        'kcal': _kcal,
        'proteinaG': _proteinaG,
        'carbosG': _carbosG,
        'grasaG': _grasaG,
        'supuesto': _supuesto,
        'notaSupuesto': _notaSupuesto,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'alimentoId': serializeParam(
          _alimentoId,
          ParamType.String,
        ),
        'nombre': serializeParam(
          _nombre,
          ParamType.String,
        ),
        'gramos': serializeParam(
          _gramos,
          ParamType.double,
        ),
        'preparacion': serializeParam(
          _preparacion,
          ParamType.String,
        ),
        'kcal100': serializeParam(
          _kcal100,
          ParamType.double,
        ),
        'proteina100': serializeParam(
          _proteina100,
          ParamType.double,
        ),
        'carbos100': serializeParam(
          _carbos100,
          ParamType.double,
        ),
        'grasa100': serializeParam(
          _grasa100,
          ParamType.double,
        ),
        'kcal': serializeParam(
          _kcal,
          ParamType.double,
        ),
        'proteinaG': serializeParam(
          _proteinaG,
          ParamType.double,
        ),
        'carbosG': serializeParam(
          _carbosG,
          ParamType.double,
        ),
        'grasaG': serializeParam(
          _grasaG,
          ParamType.double,
        ),
        'supuesto': serializeParam(
          _supuesto,
          ParamType.bool,
        ),
        'notaSupuesto': serializeParam(
          _notaSupuesto,
          ParamType.String,
        ),
      }.withoutNulls;

  static AlimentoConsumidoStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      AlimentoConsumidoStruct(
        alimentoId: deserializeParam(
          data['alimentoId'],
          ParamType.String,
          false,
        ),
        nombre: deserializeParam(
          data['nombre'],
          ParamType.String,
          false,
        ),
        gramos: deserializeParam(
          data['gramos'],
          ParamType.double,
          false,
        ),
        preparacion: deserializeParam(
          data['preparacion'],
          ParamType.String,
          false,
        ),
        kcal100: deserializeParam(
          data['kcal100'],
          ParamType.double,
          false,
        ),
        proteina100: deserializeParam(
          data['proteina100'],
          ParamType.double,
          false,
        ),
        carbos100: deserializeParam(
          data['carbos100'],
          ParamType.double,
          false,
        ),
        grasa100: deserializeParam(
          data['grasa100'],
          ParamType.double,
          false,
        ),
        kcal: deserializeParam(
          data['kcal'],
          ParamType.double,
          false,
        ),
        proteinaG: deserializeParam(
          data['proteinaG'],
          ParamType.double,
          false,
        ),
        carbosG: deserializeParam(
          data['carbosG'],
          ParamType.double,
          false,
        ),
        grasaG: deserializeParam(
          data['grasaG'],
          ParamType.double,
          false,
        ),
        supuesto: deserializeParam(
          data['supuesto'],
          ParamType.bool,
          false,
        ),
        notaSupuesto: deserializeParam(
          data['notaSupuesto'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AlimentoConsumidoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AlimentoConsumidoStruct &&
        alimentoId == other.alimentoId &&
        nombre == other.nombre &&
        gramos == other.gramos &&
        preparacion == other.preparacion &&
        kcal100 == other.kcal100 &&
        proteina100 == other.proteina100 &&
        carbos100 == other.carbos100 &&
        grasa100 == other.grasa100 &&
        kcal == other.kcal &&
        proteinaG == other.proteinaG &&
        carbosG == other.carbosG &&
        grasaG == other.grasaG &&
        supuesto == other.supuesto &&
        notaSupuesto == other.notaSupuesto;
  }

  @override
  int get hashCode => const ListEquality().hash([
        alimentoId,
        nombre,
        gramos,
        preparacion,
        kcal100,
        proteina100,
        carbos100,
        grasa100,
        kcal,
        proteinaG,
        carbosG,
        grasaG,
        supuesto,
        notaSupuesto
      ]);
}

AlimentoConsumidoStruct createAlimentoConsumidoStruct({
  String? alimentoId,
  String? nombre,
  double? gramos,
  String? preparacion,
  double? kcal100,
  double? proteina100,
  double? carbos100,
  double? grasa100,
  double? kcal,
  double? proteinaG,
  double? carbosG,
  double? grasaG,
  bool? supuesto,
  String? notaSupuesto,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AlimentoConsumidoStruct(
      alimentoId: alimentoId,
      nombre: nombre,
      gramos: gramos,
      preparacion: preparacion,
      kcal100: kcal100,
      proteina100: proteina100,
      carbos100: carbos100,
      grasa100: grasa100,
      kcal: kcal,
      proteinaG: proteinaG,
      carbosG: carbosG,
      grasaG: grasaG,
      supuesto: supuesto,
      notaSupuesto: notaSupuesto,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AlimentoConsumidoStruct? updateAlimentoConsumidoStruct(
  AlimentoConsumidoStruct? alimentoConsumido, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    alimentoConsumido
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAlimentoConsumidoStructData(
  Map<String, dynamic> firestoreData,
  AlimentoConsumidoStruct? alimentoConsumido,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (alimentoConsumido == null) {
    return;
  }
  if (alimentoConsumido.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && alimentoConsumido.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final alimentoConsumidoData =
      getAlimentoConsumidoFirestoreData(alimentoConsumido, forFieldValue);
  final nestedData =
      alimentoConsumidoData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = alimentoConsumido.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAlimentoConsumidoFirestoreData(
  AlimentoConsumidoStruct? alimentoConsumido, [
  bool forFieldValue = false,
]) {
  if (alimentoConsumido == null) {
    return {};
  }
  final firestoreData = mapToFirestore(alimentoConsumido.toMap());

  // Add any Firestore field values
  mapToFirestore(alimentoConsumido.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAlimentoConsumidoListFirestoreData(
  List<AlimentoConsumidoStruct>? alimentoConsumidos,
) =>
    alimentoConsumidos
        ?.map((e) => getAlimentoConsumidoFirestoreData(e, true))
        .toList() ??
    [];
