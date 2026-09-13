import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PlantillasIntervalosRecord extends FirestoreRecord {
  PlantillasIntervalosRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  bool hasNombre() => _nombre != null;

  // "rondas" field.
  int? _rondas;
  int get rondas => _rondas ?? 0;
  bool hasRondas() => _rondas != null;

  // "fases" field.
  List<FaseStruct>? _fases;
  List<FaseStruct> get fases => _fases ?? const [];
  bool hasFases() => _fases != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _nombre = snapshotData['nombre'] as String?;
    _rondas = castToType<int>(snapshotData['rondas']);
    _fases = getStructList(
      snapshotData['fases'],
      FaseStruct.fromMap,
    );
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('plantillasIntervalos')
          : FirebaseFirestore.instance.collectionGroup('plantillasIntervalos');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('plantillasIntervalos').doc(id);

  static Stream<PlantillasIntervalosRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => PlantillasIntervalosRecord.fromSnapshot(s));

  static Future<PlantillasIntervalosRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => PlantillasIntervalosRecord.fromSnapshot(s));

  static PlantillasIntervalosRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PlantillasIntervalosRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PlantillasIntervalosRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PlantillasIntervalosRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PlantillasIntervalosRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PlantillasIntervalosRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPlantillasIntervalosRecordData({
  String? nombre,
  int? rondas,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'nombre': nombre,
      'rondas': rondas,
    }.withoutNulls,
  );

  return firestoreData;
}

class PlantillasIntervalosRecordDocumentEquality
    implements Equality<PlantillasIntervalosRecord> {
  const PlantillasIntervalosRecordDocumentEquality();

  @override
  bool equals(PlantillasIntervalosRecord? e1, PlantillasIntervalosRecord? e2) {
    const listEquality = ListEquality();
    return e1?.nombre == e2?.nombre &&
        e1?.rondas == e2?.rondas &&
        listEquality.equals(e1?.fases, e2?.fases);
  }

  @override
  int hash(PlantillasIntervalosRecord? e) =>
      const ListEquality().hash([e?.nombre, e?.rondas, e?.fases]);

  @override
  bool isValidKey(Object? o) => o is PlantillasIntervalosRecord;
}
