import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SesionesIntervalosRecord extends FirestoreRecord {
  SesionesIntervalosRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "fecha" field.
  DateTime? _fecha;
  DateTime? get fecha => _fecha;
  bool hasFecha() => _fecha != null;

  // "plantillaNombre" field.
  String? _plantillaNombre;
  String get plantillaNombre => _plantillaNombre ?? '';
  bool hasPlantillaNombre() => _plantillaNombre != null;

  // "duracionSegundos" field.
  int? _duracionSegundos;
  int get duracionSegundos => _duracionSegundos ?? 0;
  bool hasDuracionSegundos() => _duracionSegundos != null;

  // "fases" field.
  List<FaseRealizadaStruct>? _fases;
  List<FaseRealizadaStruct> get fases => _fases ?? const [];
  bool hasFases() => _fases != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _fecha = snapshotData['fecha'] as DateTime?;
    _plantillaNombre = snapshotData['plantillaNombre'] as String?;
    _duracionSegundos = castToType<int>(snapshotData['duracionSegundos']);
    _fases = getStructList(
      snapshotData['fases'],
      FaseRealizadaStruct.fromMap,
    );
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('sesionesIntervalos')
          : FirebaseFirestore.instance.collectionGroup('sesionesIntervalos');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('sesionesIntervalos').doc(id);

  static Stream<SesionesIntervalosRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SesionesIntervalosRecord.fromSnapshot(s));

  static Future<SesionesIntervalosRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => SesionesIntervalosRecord.fromSnapshot(s));

  static SesionesIntervalosRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SesionesIntervalosRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SesionesIntervalosRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SesionesIntervalosRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SesionesIntervalosRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SesionesIntervalosRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSesionesIntervalosRecordData({
  DateTime? fecha,
  String? plantillaNombre,
  int? duracionSegundos,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'fecha': fecha,
      'plantillaNombre': plantillaNombre,
      'duracionSegundos': duracionSegundos,
    }.withoutNulls,
  );

  return firestoreData;
}

class SesionesIntervalosRecordDocumentEquality
    implements Equality<SesionesIntervalosRecord> {
  const SesionesIntervalosRecordDocumentEquality();

  @override
  bool equals(SesionesIntervalosRecord? e1, SesionesIntervalosRecord? e2) {
    const listEquality = ListEquality();
    return e1?.fecha == e2?.fecha &&
        e1?.plantillaNombre == e2?.plantillaNombre &&
        e1?.duracionSegundos == e2?.duracionSegundos &&
        listEquality.equals(e1?.fases, e2?.fases);
  }

  @override
  int hash(SesionesIntervalosRecord? e) => const ListEquality()
      .hash([e?.fecha, e?.plantillaNombre, e?.duracionSegundos, e?.fases]);

  @override
  bool isValidKey(Object? o) => o is SesionesIntervalosRecord;
}
