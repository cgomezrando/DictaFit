import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ComidasRecord extends FirestoreRecord {
  ComidasRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "fecha" field.
  DateTime? _fecha;
  DateTime? get fecha => _fecha;
  bool hasFecha() => _fecha != null;

  // "tipo" field.
  String? _tipo;
  String get tipo => _tipo ?? '';
  bool hasTipo() => _tipo != null;

  // "transcripcion" field.
  String? _transcripcion;
  String get transcripcion => _transcripcion ?? '';
  bool hasTranscripcion() => _transcripcion != null;

  // "items" field.
  List<AlimentoConsumidoStruct>? _items;
  List<AlimentoConsumidoStruct> get items => _items ?? const [];
  bool hasItems() => _items != null;

  // "kcal" field.
  double? _kcal;
  double get kcal => _kcal ?? 0.0;
  bool hasKcal() => _kcal != null;

  // "proteinaG" field.
  double? _proteinaG;
  double get proteinaG => _proteinaG ?? 0.0;
  bool hasProteinaG() => _proteinaG != null;

  // "carbosG" field.
  double? _carbosG;
  double get carbosG => _carbosG ?? 0.0;
  bool hasCarbosG() => _carbosG != null;

  // "grasaG" field.
  double? _grasaG;
  double get grasaG => _grasaG ?? 0.0;
  bool hasGrasaG() => _grasaG != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _fecha = snapshotData['fecha'] as DateTime?;
    _tipo = snapshotData['tipo'] as String?;
    _transcripcion = snapshotData['transcripcion'] as String?;
    _items = getStructList(
      snapshotData['items'],
      AlimentoConsumidoStruct.fromMap,
    );
    _kcal = castToType<double>(snapshotData['kcal']);
    _proteinaG = castToType<double>(snapshotData['proteinaG']);
    _carbosG = castToType<double>(snapshotData['carbosG']);
    _grasaG = castToType<double>(snapshotData['grasaG']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('comidas')
          : FirebaseFirestore.instance.collectionGroup('comidas');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('comidas').doc(id);

  static Stream<ComidasRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ComidasRecord.fromSnapshot(s));

  static Future<ComidasRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ComidasRecord.fromSnapshot(s));

  static ComidasRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ComidasRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ComidasRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ComidasRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ComidasRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ComidasRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createComidasRecordData({
  DateTime? fecha,
  String? tipo,
  String? transcripcion,
  double? kcal,
  double? proteinaG,
  double? carbosG,
  double? grasaG,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'fecha': fecha,
      'tipo': tipo,
      'transcripcion': transcripcion,
      'kcal': kcal,
      'proteinaG': proteinaG,
      'carbosG': carbosG,
      'grasaG': grasaG,
    }.withoutNulls,
  );

  return firestoreData;
}

class ComidasRecordDocumentEquality implements Equality<ComidasRecord> {
  const ComidasRecordDocumentEquality();

  @override
  bool equals(ComidasRecord? e1, ComidasRecord? e2) {
    const listEquality = ListEquality();
    return e1?.fecha == e2?.fecha &&
        e1?.tipo == e2?.tipo &&
        e1?.transcripcion == e2?.transcripcion &&
        listEquality.equals(e1?.items, e2?.items) &&
        e1?.kcal == e2?.kcal &&
        e1?.proteinaG == e2?.proteinaG &&
        e1?.carbosG == e2?.carbosG &&
        e1?.grasaG == e2?.grasaG;
  }

  @override
  int hash(ComidasRecord? e) => const ListEquality().hash([
        e?.fecha,
        e?.tipo,
        e?.transcripcion,
        e?.items,
        e?.kcal,
        e?.proteinaG,
        e?.carbosG,
        e?.grasaG
      ]);

  @override
  bool isValidKey(Object? o) => o is ComidasRecord;
}
