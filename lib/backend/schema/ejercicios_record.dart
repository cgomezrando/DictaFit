import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EjerciciosRecord extends FirestoreRecord {
  EjerciciosRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  bool hasNombre() => _nombre != null;

  // "aliases" field.
  List<String>? _aliases;
  List<String> get aliases => _aliases ?? const [];
  bool hasAliases() => _aliases != null;

  // "equipamiento" field.
  String? _equipamiento;
  String get equipamiento => _equipamiento ?? '';
  bool hasEquipamiento() => _equipamiento != null;

  // "cargaPor" field.
  String? _cargaPor;
  String get cargaPor => _cargaPor ?? '';
  bool hasCargaPor() => _cargaPor != null;

  // "musculos" field.
  List<MusculoImplicadoStruct>? _musculos;
  List<MusculoImplicadoStruct> get musculos => _musculos ?? const [];
  bool hasMusculos() => _musculos != null;

  // "tieneEstandar" field.
  bool? _tieneEstandar;
  bool get tieneEstandar => _tieneEstandar ?? false;
  bool hasTieneEstandar() => _tieneEstandar != null;

  void _initializeFields() {
    _nombre = snapshotData['nombre'] as String?;
    _aliases = getDataList(snapshotData['aliases']);
    _equipamiento = snapshotData['equipamiento'] as String?;
    _cargaPor = snapshotData['cargaPor'] as String?;
    _musculos = getStructList(
      snapshotData['musculos'],
      MusculoImplicadoStruct.fromMap,
    );
    _tieneEstandar = snapshotData['tieneEstandar'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ejercicios');

  static Stream<EjerciciosRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EjerciciosRecord.fromSnapshot(s));

  static Future<EjerciciosRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EjerciciosRecord.fromSnapshot(s));

  static EjerciciosRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EjerciciosRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EjerciciosRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EjerciciosRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EjerciciosRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EjerciciosRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEjerciciosRecordData({
  String? nombre,
  String? equipamiento,
  String? cargaPor,
  bool? tieneEstandar,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'nombre': nombre,
      'equipamiento': equipamiento,
      'cargaPor': cargaPor,
      'tieneEstandar': tieneEstandar,
    }.withoutNulls,
  );

  return firestoreData;
}

class EjerciciosRecordDocumentEquality implements Equality<EjerciciosRecord> {
  const EjerciciosRecordDocumentEquality();

  @override
  bool equals(EjerciciosRecord? e1, EjerciciosRecord? e2) {
    const listEquality = ListEquality();
    return e1?.nombre == e2?.nombre &&
        listEquality.equals(e1?.aliases, e2?.aliases) &&
        e1?.equipamiento == e2?.equipamiento &&
        e1?.cargaPor == e2?.cargaPor &&
        listEquality.equals(e1?.musculos, e2?.musculos) &&
        e1?.tieneEstandar == e2?.tieneEstandar;
  }

  @override
  int hash(EjerciciosRecord? e) => const ListEquality().hash([
        e?.nombre,
        e?.aliases,
        e?.equipamiento,
        e?.cargaPor,
        e?.musculos,
        e?.tieneEstandar
      ]);

  @override
  bool isValidKey(Object? o) => o is EjerciciosRecord;
}
