import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "pesoKg" field.
  double? _pesoKg;
  double get pesoKg => _pesoKg ?? 0.0;
  bool hasPesoKg() => _pesoKg != null;

  // "alturaCm" field.
  int? _alturaCm;
  int get alturaCm => _alturaCm ?? 0;
  bool hasAlturaCm() => _alturaCm != null;

  // "fechaNacimiento" field.
  DateTime? _fechaNacimiento;
  DateTime? get fechaNacimiento => _fechaNacimiento;
  bool hasFechaNacimiento() => _fechaNacimiento != null;

  // "sexo" field.
  String? _sexo;
  String get sexo => _sexo ?? '';
  bool hasSexo() => _sexo != null;

  // "objetivoKcal" field.
  int? _objetivoKcal;
  int get objetivoKcal => _objetivoKcal ?? 0;
  bool hasObjetivoKcal() => _objetivoKcal != null;

  // "objetivoProteinaG" field.
  int? _objetivoProteinaG;
  int get objetivoProteinaG => _objetivoProteinaG ?? 0;
  bool hasObjetivoProteinaG() => _objetivoProteinaG != null;

  // "objetivoCarbosG" field.
  int? _objetivoCarbosG;
  int get objetivoCarbosG => _objetivoCarbosG ?? 0;
  bool hasObjetivoCarbosG() => _objetivoCarbosG != null;

  // "objetivoGrasaG" field.
  int? _objetivoGrasaG;
  int get objetivoGrasaG => _objetivoGrasaG ?? 0;
  bool hasObjetivoGrasaG() => _objetivoGrasaG != null;

  // "pesoAlimentos" field.
  String? _pesoAlimentos;
  String get pesoAlimentos => _pesoAlimentos ?? '';
  bool hasPesoAlimentos() => _pesoAlimentos != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  void _initializeFields() {
    _pesoKg = castToType<double>(snapshotData['pesoKg']);
    _alturaCm = castToType<int>(snapshotData['alturaCm']);
    _fechaNacimiento = snapshotData['fechaNacimiento'] as DateTime?;
    _sexo = snapshotData['sexo'] as String?;
    _objetivoKcal = castToType<int>(snapshotData['objetivoKcal']);
    _objetivoProteinaG = castToType<int>(snapshotData['objetivoProteinaG']);
    _objetivoCarbosG = castToType<int>(snapshotData['objetivoCarbosG']);
    _objetivoGrasaG = castToType<int>(snapshotData['objetivoGrasaG']);
    _pesoAlimentos = snapshotData['pesoAlimentos'] as String?;
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  double? pesoKg,
  int? alturaCm,
  DateTime? fechaNacimiento,
  String? sexo,
  int? objetivoKcal,
  int? objetivoProteinaG,
  int? objetivoCarbosG,
  int? objetivoGrasaG,
  String? pesoAlimentos,
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'pesoKg': pesoKg,
      'alturaCm': alturaCm,
      'fechaNacimiento': fechaNacimiento,
      'sexo': sexo,
      'objetivoKcal': objetivoKcal,
      'objetivoProteinaG': objetivoProteinaG,
      'objetivoCarbosG': objetivoCarbosG,
      'objetivoGrasaG': objetivoGrasaG,
      'pesoAlimentos': pesoAlimentos,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    return e1?.pesoKg == e2?.pesoKg &&
        e1?.alturaCm == e2?.alturaCm &&
        e1?.fechaNacimiento == e2?.fechaNacimiento &&
        e1?.sexo == e2?.sexo &&
        e1?.objetivoKcal == e2?.objetivoKcal &&
        e1?.objetivoProteinaG == e2?.objetivoProteinaG &&
        e1?.objetivoCarbosG == e2?.objetivoCarbosG &&
        e1?.objetivoGrasaG == e2?.objetivoGrasaG &&
        e1?.pesoAlimentos == e2?.pesoAlimentos &&
        e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.pesoKg,
        e?.alturaCm,
        e?.fechaNacimiento,
        e?.sexo,
        e?.objetivoKcal,
        e?.objetivoProteinaG,
        e?.objetivoCarbosG,
        e?.objetivoGrasaG,
        e?.pesoAlimentos,
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
