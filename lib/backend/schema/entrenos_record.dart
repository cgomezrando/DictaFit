import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EntrenosRecord extends FirestoreRecord {
  EntrenosRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "fecha" field.
  DateTime? _fecha;
  DateTime? get fecha => _fecha;
  bool hasFecha() => _fecha != null;

  // "transcripcion" field.
  String? _transcripcion;
  String get transcripcion => _transcripcion ?? '';
  bool hasTranscripcion() => _transcripcion != null;

  // "pesoCorporalKg" field.
  double? _pesoCorporalKg;
  double get pesoCorporalKg => _pesoCorporalKg ?? 0.0;
  bool hasPesoCorporalKg() => _pesoCorporalKg != null;

  // "ejercicios" field.
  List<EjercicioRealizadoStruct>? _ejercicios;
  List<EjercicioRealizadoStruct> get ejercicios => _ejercicios ?? const [];
  bool hasEjercicios() => _ejercicios != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _fecha = snapshotData['fecha'] as DateTime?;
    _transcripcion = snapshotData['transcripcion'] as String?;
    _pesoCorporalKg = castToType<double>(snapshotData['pesoCorporalKg']);
    _ejercicios = getStructList(
      snapshotData['ejercicios'],
      EjercicioRealizadoStruct.fromMap,
    );
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('entrenos')
          : FirebaseFirestore.instance.collectionGroup('entrenos');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('entrenos').doc(id);

  static Stream<EntrenosRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EntrenosRecord.fromSnapshot(s));

  static Future<EntrenosRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EntrenosRecord.fromSnapshot(s));

  static EntrenosRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EntrenosRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EntrenosRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EntrenosRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EntrenosRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EntrenosRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEntrenosRecordData({
  DateTime? fecha,
  String? transcripcion,
  double? pesoCorporalKg,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'fecha': fecha,
      'transcripcion': transcripcion,
      'pesoCorporalKg': pesoCorporalKg,
    }.withoutNulls,
  );

  return firestoreData;
}

class EntrenosRecordDocumentEquality implements Equality<EntrenosRecord> {
  const EntrenosRecordDocumentEquality();

  @override
  bool equals(EntrenosRecord? e1, EntrenosRecord? e2) {
    const listEquality = ListEquality();
    return e1?.fecha == e2?.fecha &&
        e1?.transcripcion == e2?.transcripcion &&
        e1?.pesoCorporalKg == e2?.pesoCorporalKg &&
        listEquality.equals(e1?.ejercicios, e2?.ejercicios);
  }

  @override
  int hash(EntrenosRecord? e) => const ListEquality()
      .hash([e?.fecha, e?.transcripcion, e?.pesoCorporalKg, e?.ejercicios]);

  @override
  bool isValidKey(Object? o) => o is EntrenosRecord;
}
