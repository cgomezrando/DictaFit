// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// Si el compilador se queja de que no encuentra 'package:fl_chart/fl_chart.dart',
/// añádelo en Custom Pub Dependencies: fl_chart: ^0.69.0

class EstadisticasEntreno extends StatefulWidget {
  const EstadisticasEntreno({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<EstadisticasEntreno> createState() => _EstadisticasEntrenoState();
}

class _EstadisticasEntrenoState extends State<EstadisticasEntreno> {
  static const Map<String, String> _grupoMuscular = {
    'pectoral_clavicular': 'pecho',
    'pectoral_esternal': 'pecho',
    'deltoides_anterior': 'hombro',
    'deltoides_lateral': 'hombro',
    'deltoides_posterior': 'hombro',
    'trapecio': 'hombro',
    'triceps': 'brazo',
    'biceps': 'brazo',
    'antebrazo': 'brazo',
    'dorsal': 'espalda',
    'romboides': 'espalda',
    'lumbar': 'espalda',
    'abdominal': 'core',
    'oblicuos': 'core',
    'gluteo': 'pierna',
    'cuadriceps': 'pierna',
    'isquiotibiales': 'pierna',
    'aductores': 'pierna',
    'gemelos': 'pierna',
  };

  static const Map<String, String> _nombreGrupo = {
    'pecho': 'Pecho',
    'hombro': 'Hombros',
    'brazo': 'Brazos',
    'espalda': 'Espalda',
    'core': 'Abdomen',
    'pierna': 'Piernas',
  };

  // Orden fijo en el que se listan los grupos en el resumen.
  static const List<String> _ordenGrupos = [
    'pecho',
    'espalda',
    'hombro',
    'brazo',
    'pierna',
    'core',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>>? _pesosStream;

  /// Últimos entrenos, para el resumen de "hace cuántos días" por grupo y
  /// el conteo semanal. Se cargan una vez, no hace falta que sea en vivo.
  List<Map<String, dynamic>>? _entrenosRecientes;

  /// Mejor 1RM histórico por ejercicio (para el mismo cálculo de intensidad
  /// que en "Ver último entrenamiento"), cargado bajo demanda.
  final Map<String, double> _marcasCache = {};
  final Set<String> _marcasEnCarga = {};
  String _vistaSemanal = 'frontal';

  /// Pasos diarios del último año (colección "pasos"; no confundir con
  /// "pesos", que es el peso corporal). Se cargan una vez, y de ahí se
  /// sacan las medias de semana/mes/6 meses/año.
  List<Map<String, dynamic>>? _pasosRecientes;

  /// Comidas del último año, para las medias de calorías/macros. A
  /// diferencia de "pasos" (un documento por día), puede haber varias
  /// comidas el mismo día (varias sesiones abiertas y cerradas), así que
  /// hay que sumarlas por día antes de sacar la media.
  List<Map<String, dynamic>>? _comidasRecientes;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _pesosStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pesos')
          .orderBy('fecha', descending: false)
          .limit(200)
          .snapshots();
      _cargarEntrenosRecientes(uid);
      _cargarPasosRecientes(uid);
      _cargarComidasRecientes(uid);
    }
  }

  void _cargarEntrenosRecientes(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entrenos')
        .orderBy('fecha', descending: true)
        .limit(60)
        .get()
        .then((snap) {
      if (!mounted) return;
      setState(
          () => _entrenosRecientes = snap.docs.map((d) => d.data()).toList());
    }).catchError((_) {
      if (mounted) setState(() => _entrenosRecientes = []);
    });
  }

  void _cargarPasosRecientes(String uid) {
    final desde = DateTime.now().subtract(const Duration(days: 370));
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pasos')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .get()
        .then((snap) {
      if (!mounted) return;
      setState(() => _pasosRecientes = snap.docs.map((d) => d.data()).toList());
    }).catchError((_) {
      if (mounted) setState(() => _pasosRecientes = []);
    });
  }

  void _cargarComidasRecientes(String uid) {
    final desde = DateTime.now().subtract(const Duration(days: 370));
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('comidas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .get()
        .then((snap) {
      if (!mounted) return;
      setState(
          () => _comidasRecientes = snap.docs.map((d) => d.data()).toList());
    }).catchError((_) {
      if (mounted) setState(() => _comidasRecientes = []);
    });
  }

  /// Media de pasos/día en los últimos [dias] días (solo cuenta los días
  /// que de verdad tienen un registro; si no hay ninguno, null).
  double? _mediaPasos(int dias) {
    if (_pasosRecientes == null || _pasosRecientes!.isEmpty) return null;
    final desde = DateTime.now().subtract(Duration(days: dias));
    final valores = _pasosRecientes!
        .where((d) {
          final f = d['fecha'];
          return f is Timestamp && f.toDate().isAfter(desde);
        })
        .map((d) => (d['totalPasos'] as num?)?.toDouble() ?? 0)
        .where((v) => v > 0)
        .toList();
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  /// Suma kcal/macros por día de calendario a partir de _comidasRecientes
  /// (puede haber más de una comida guardada el mismo día).
  Map<String, Map<String, double>> _totalesNutricionPorDia() {
    final porDia = <String, Map<String, double>>{};
    if (_comidasRecientes == null) return porDia;
    for (final c in _comidasRecientes!) {
      final f = c['fecha'];
      if (f is! Timestamp) continue;
      final dt = f.toDate();
      final clave = '${dt.year}-${dt.month}-${dt.day}';
      final actual = porDia.putIfAbsent(
          clave,
          () => {
                'kcal': 0,
                'proteinaG': 0,
                'carbosG': 0,
                'grasaG': 0,
                'ts': dt.millisecondsSinceEpoch.toDouble(),
              });
      actual['kcal'] =
          (actual['kcal'] ?? 0) + ((c['kcal'] as num?)?.toDouble() ?? 0);
      actual['proteinaG'] = (actual['proteinaG'] ?? 0) +
          ((c['proteinaG'] as num?)?.toDouble() ?? 0);
      actual['carbosG'] =
          (actual['carbosG'] ?? 0) + ((c['carbosG'] as num?)?.toDouble() ?? 0);
      actual['grasaG'] =
          (actual['grasaG'] ?? 0) + ((c['grasaG'] as num?)?.toDouble() ?? 0);
    }
    return porDia;
  }

  /// Media diaria de kcal/macros en los últimos [dias] días (solo cuenta
  /// los días que de verdad tienen alguna comida guardada).
  Map<String, double>? _mediaNutricion(int dias) {
    final porDia = _totalesNutricionPorDia();
    if (porDia.isEmpty) return null;
    final desde = DateTime.now().subtract(Duration(days: dias));
    final diasEnVentana = porDia.values
        .where((d) => DateTime.fromMillisecondsSinceEpoch(d['ts']!.toInt())
            .isAfter(desde))
        .toList();
    if (diasEnVentana.isEmpty) return null;
    double suma(String campo) =>
        diasEnVentana.fold(0.0, (s, d) => s + (d[campo] ?? 0));
    final n = diasEnVentana.length;
    return {
      'kcal': suma('kcal') / n,
      'proteinaG': suma('proteinaG') / n,
      'carbosG': suma('carbosG') / n,
      'grasaG': suma('grasaG') / n,
    };
  }

  void _cargarMarcasFaltantes(Iterable<String> ejercicioIds) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (final id in ejercicioIds) {
      if (id.isEmpty || id == 'desconocido') continue;
      if (_marcasCache.containsKey(id) || _marcasEnCarga.contains(id)) continue;
      _marcasEnCarga.add(id);
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('marcasPersonales')
          .doc(id)
          .get()
          .then((doc) {
        final mejor = (doc.data()?['mejorE1rmKg'] as num?)?.toDouble() ?? 0;
        if (mounted) setState(() => _marcasCache[id] = mejor);
      }).catchError((_) {
        if (mounted) setState(() => _marcasCache[id] = 0);
      });
    }
  }

  /// Series efectivas EN UNA SEMANA que dejan cada músculo "trabajado a
  /// fondo", a diferencia de _seriesAFondo en "Ver último entrenamiento"
  /// (que es por sesión). Aquí sí son los landmarks de volumen semanal
  /// habituales en la literatura de hipertrofia (Israetel et al.): ~16
  /// series/semana para los grupos grandes, ~12 para los medianos, ~8 para
  /// los pequeños.
  static const Map<String, double> _seriesAFondoSemanal = {
    'cuadriceps': 16,
    'gluteo': 16,
    'dorsal': 16,
    'pectoral_esternal': 16,
    'isquiotibiales': 12,
    'pectoral_clavicular': 12,
    'trapecio': 12,
    'romboides': 12,
    'biceps': 12,
    'triceps': 12,
    'gemelos': 12,
    'abdominal': 12,
    'deltoides_lateral': 12,
    'deltoides_posterior': 12,
    'deltoides_anterior': 8,
    'lumbar': 8,
    'oblicuos': 8,
    'antebrazo': 8,
    'aductores': 8,
  };
  static const double _seriesAFondoSemanalPorDefecto = 12;
  static const double _factorSecundarioSemanal = 0.08;

  /// Mismo cálculo que _intensidadesMusculos en "Ver último entrenamiento"
  /// (peso del catálogo × series × cercanía a tu marca personal × factor de
  /// rol), pero sumado a lo largo de los últimos 7 días en vez de un solo
  /// entreno, y comparado contra la referencia semanal, no la de sesión.
  Map<String, double> _intensidadesSemana() {
    final bruto = <String, double>{};
    if (_entrenosRecientes == null) return {};
    final hace7dias = DateTime.now().subtract(const Duration(days: 7));
    final entrenosSemana = _entrenosRecientes!.where((e) {
      final f = e['fecha'];
      return f is Timestamp && f.toDate().isAfter(hace7dias);
    }).toList();

    final idsEjercicios = <String>{};
    for (final entreno in entrenosSemana) {
      final ejercicios = entreno['ejercicios'];
      if (ejercicios is List) {
        idsEjercicios.addAll(ejercicios
            .whereType<Map>()
            .map((e) => (e['ejercicioId'] ?? '').toString()));
      }
    }
    _cargarMarcasFaltantes(idsEjercicios);

    for (final entreno in entrenosSemana) {
      final ejercicios = entreno['ejercicios'];
      if (ejercicios is! List) continue;
      for (final ejercicio in ejercicios) {
        if (ejercicio is! Map) continue;
        final musculos = ejercicio['musculos'];
        if (musculos is! List) continue;

        final series = ejercicio['series'];
        var numSeries = 0;
        if (series is List) {
          for (final s in series) {
            if (s is! Map) continue;
            final kg = (s['kg'] as num?)?.toDouble();
            final reps = (s['reps'] as num?)?.toInt();
            if (reps != null &&
                reps > 0 &&
                (kg != null || ejercicio['cargaPor'] == 'corporal')) {
              numSeries++;
            }
          }
        }
        if (numSeries == 0) continue;

        final ejercicioId = (ejercicio['ejercicioId'] ?? '').toString();
        final e1rm = (ejercicio['e1rmKg'] as num?)?.toDouble() ?? 0;
        final mejorHistorico = _marcasCache[ejercicioId];
        double factorCarga;
        if (e1rm <= 0) {
          factorCarga = 0.5;
        } else if (mejorHistorico == null || mejorHistorico <= 0) {
          factorCarga = 1.0;
        } else {
          factorCarga = (e1rm / mejorHistorico).clamp(0.0, 1.0);
        }

        for (final m in musculos) {
          if (m is! Map) continue;
          final id = (m['musculo'] ?? '').toString().trim().toLowerCase();
          if (id.isEmpty) continue;
          final peso = (m['peso'] as num?)?.toDouble() ?? 0.5;
          final rol = (m['rol'] ?? '').toString().trim().toLowerCase();
          final factorRol = rol == 'principal' ? 1.0 : _factorSecundarioSemanal;
          bruto[id] =
              (bruto[id] ?? 0) + peso * numSeries * factorCarga * factorRol;
        }
      }
    }
    if (bruto.isEmpty) return {};
    return bruto.map((id, valor) {
      final referencia =
          0.9 * (_seriesAFondoSemanal[id] ?? _seriesAFondoSemanalPorDefecto);
      return MapEntry(id, (valor / referencia).clamp(0.0, 1.0));
    });
  }

  // ---------- Utilidades ----------

  Color _tinte(Color color, double opacidad) =>
      color.withAlpha((255 * opacidad).round());

  String _numeroCorto(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _miles(int valor) {
    final texto = valor.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
      buffer.write(texto[i]);
    }
    return '${valor < 0 ? '-' : ''}$buffer';
  }

  // ------------------------------------------------------------
  // Datos del cuerpo (silueta y regiones musculares), copiados tal
  // cual de MusculosEntrenamiento para que el dibujo sea idéntico.
  // ------------------------------------------------------------
  static const String _viewBox = '90 20 588 1352';
  static const String _colorBase = '#1F1F2C';
  static const String _colorReposo = '#2A2A3B';

  static const String _siluetaFrontal =
      'M377 28 357 33 344 40 330 54 325 63 322 72 321 103 316 106 313 110 313 122 320 144 325 149 329 '
      '150 331 156 333 191 332 200 329 209 316 220 276 240 259 252 246 258 236 259 221 263 207 271 191 '
      '287 185 296 176 315 171 336 171 364 173 378 163 397 158 416 158 444 159 445 158 466 154 479 134 '
      '518 126 548 122 579 117 645 113 666 107 685 107 705 98 753 98 762 104 775 109 795 113 802 127 '
      '819 143 834 148 832 151 829 151 819 148 810 143 801 131 786 128 780 127 774 129 757 132 751 135 '
      '748 137 748 140 753 143 774 148 784 151 786 158 786 161 781 161 770 156 750 156 718 151 705 144 '
      '695 144 689 152 667 160 652 176 627 195 601 207 577 212 554 213 523 216 499 235 456 241 429 244 '
      '428 252 451 273 489 275 498 275 515 268 551 268 565 271 577 271 585 262 607 258 621 253 662 245 '
      '680 236 710 229 756 229 806 231 825 237 854 253 895 256 906 257 931 255 941 254 976 246 995 235 '
      '1016 229 1035 227 1047 227 1076 229 1087 236 1106 241 1125 248 1163 258 1202 264 1231 264 1244 '
      '260 1259 260 1268 262 1273 262 1278 248 1305 227 1329 223 1339 223 1347 226 1352 242 1360 253 '
      '1360 256 1362 269 1360 276 1363 282 1363 288 1360 298 1348 301 1341 301 1323 311 1312 315 1305 '
      '315 1295 311 1281 315 1268 315 1256 310 1245 307 1234 306 1210 311 1182 320 1149 323 1124 337 '
      '1097 342 1075 342 1057 340 1042 326 990 326 985 335 964 346 921 354 898 360 829 377 767 379 751 '
      '382 750 384 752 387 774 399 813 403 831 406 862 407 892 423 945 427 964 436 984 435 997 428 1018 '
      '422 1045 420 1071 424 1093 440 1125 442 1146 452 1184 456 1208 456 1233 447 1257 447 1266 451 '
      '1277 451 1283 447 1299 447 1306 448 1309 459 1320 462 1328 462 1343 467 1352 474 1360 480 1363 '
      '486 1363 493 1360 507 1362 510 1360 526 1358 534 1354 539 1347 539 1338 536 1330 529 1320 513 '
      '1303 500 1277 502 1269 502 1257 498 1241 500 1223 520 1137 524 1114 533 1087 536 1072 536 1050 '
      '533 1033 527 1015 511 983 508 974 507 966 508 948 505 925 505 915 508 900 525 856 531 828 534 '
      '797 533 751 530 728 524 701 519 685 509 661 505 623 491 583 494 565 494 549 488 519 488 495 491 '
      '485 503 466 510 452 518 430 520 430 522 433 527 455 546 497 549 516 550 552 555 576 570 605 592 '
      '635 602 651 613 673 619 691 619 695 613 703 606 721 606 753 602 768 601 779 602 783 607 787 613 '
      '785 616 782 619 776 622 755 625 748 627 748 633 756 635 777 631 787 619 802 613 813 613 820 611 '
      '824 611 828 616 833 619 834 621 833 639 815 651 800 665 759 665 755 656 710 656 687 646 651 641 '
      '588 635 541 628 517 614 492 606 473 604 460 604 434 605 433 604 414 600 399 589 376 592 362 592 '
      '340 590 328 585 312 579 299 572 288 557 272 542 263 533 260 517 258 509 255 488 241 452 223 440 '
      '215 432 207 430 198 430 169 432 153 435 149 439 148 442 144 449 124 449 108 446 105 441 104 442 '
      '79 440 70 433 55 420 41 406 33 397 30Z';

  static const Map<String, String> _regionesFrontal = {
    'trapecio': 'M432 213 432 216 437 228 456 254 455 255 452 253 438 234 446 250 445 251 442 248 434 234 430 220 '
        '425 249 425 257 428 261 437 262 450 259 456 259 459 257 463 258 507 257 483 242 452 227ZM445 251 '
        '446 250 448 253 447 254ZM330 213 321 221 280 242 256 257 301 258 317 241 318 243 313 250 304 258 '
        '324 262 335 261 338 253 333 221 332 221 329 232 321 247 318 250 317 249 324 234 318 242 317 240 '
        '328 223 330 218Z',
    'deltoides_lateral':
        'M509 261 507 262 524 265 538 272 548 281 559 298 565 315 568 332 568 343 569 344 568 387 575 403 '
            '582 387 589 361 588 334 581 310 573 295 565 284 553 273 540 266 531 263 516 261 510 262ZM255 262 '
            '248 261 233 263 219 268 212 272 196 286 190 294 182 309 175 333 174 363 187 403 195 384 194 335 '
            '196 320 202 301 212 284 223 273 236 266Z',
    'deltoides_anterior':
        'M484 266 494 285 517 321 553 363 564 380 565 376 564 326 559 306 549 287 536 274 520 267 499 263 '
            '492 263ZM277 265 270 263 264 263 245 266 236 269 224 276 212 289 205 302 199 323 197 339 198 380 '
            '208 365 234 336 251 313 272 279 278 267Z',
    'pectoral_clavicular': 'M384 336 390 328 401 320 418 314 433 312 451 312 475 315 493 319 509 324 517 328 517 327 494 306 '
        '455 278 433 268 423 268 415 270 407 274 394 287 390 295 386 309ZM378 336 377 312 374 299 369 288 '
        '363 280 357 275 350 271 340 268 327 269 303 281 262 311 246 327 259 322 288 315 314 312 339 313 '
        '355 317 368 324 376 332ZM437 266 465 281 493 301 506 312 484 274 476 266 471 263 472 262 481 263 '
        '484 261 487 261 466 261ZM469 262 470 261 472 262 471 263ZM326 266 296 261 285 261 284 260 276 '
        '261 281 263 289 262 292 263 286 266 280 272 264 300 255 313 280 293 302 278ZM291 262 292 261 295 '
        '262 294 263Z',
    'pectoral_esternal':
        'M389 333 384 346 384 372 386 381 391 390 400 397 408 401 426 406 444 408 468 406 487 396 496 387 '
            '508 369 519 347 523 335 516 330 502 324 481 319 458 316 420 317 406 321 398 325ZM240 335 246 353 '
            '253 367 265 385 278 398 284 402 295 406 328 407 349 403 366 395 373 388 377 380 379 365 379 352 '
            '376 338 369 328 351 319 336 316 306 316 288 318 255 326 246 330Z',
    'dorsal':
        'M521 351 512 370 504 383 506 419 507 420 505 454 511 441 517 419 518 378ZM241 350 244 376 245 '
            '418 252 442 258 455 256 442 256 408 259 384Z',
    'biceps': 'M526 339 523 380 522 381 522 414 528 447 534 464 547 487 574 514 574 491 575 490 574 468 567 428 '
        '556 394 543 367 534 353 535 351 544 363 556 386 569 423 574 444 578 473 578 502 577 503 578 516 '
        '583 531 582 532 580 530 580 528 572 516 557 503 548 493 551 508 556 519 575 544 585 544 586 523 '
        '595 489 596 470 592 456 591 485 587 506 586 499 589 479 590 460 589 459 588 439 584 423 578 406 '
        '578 410 576 412 562 383 555 372 544 358ZM236 339 209 370 200 384 186 414 184 408 178 424 173 449 '
        '173 473 177 499 176 504 174 501 170 456 166 468 166 481 176 522 177 544 188 544 192 537 207 519 '
        '213 502 214 494 187 520 182 531 180 533 179 532 185 513 184 479 186 459 192 428 204 392 212 375 '
        '221 361 222 363 206 395 194 434 188 472 188 514 217 485 228 465 234 448 239 424 241 404 241 '
        '388ZM223 358 224 360 222 362 221 360ZM225 355 226 357 224 359 223 357ZM225 354 226 353 227 355 '
        '226 356Z',
    'triceps':
        'M588 381 583 392 580 404 586 418 593 449 602 471 601 416 598 403ZM175 380 168 393 162 412 161 '
            '419 161 452 162 454 160 471 166 459 175 424 183 402Z',
    'antebrazo': 'M628 614 623 637 623 650 627 670 627 683 630 675 630 653 628 639 628 616 629 615ZM134 613 134 '
        '633 135 635 133 651 133 674 135 681 137 661 140 648 140 638ZM636 581 631 619 633 673 628 688 636 '
        '685 644 685 652 689 652 683 645 662 642 647 639 602ZM126 579 123 603 121 644 117 664 111 681 111 '
        '689 118 685 125 685 135 688 130 676 130 651 132 638 132 624ZM575 545 579 551 584 565 593 605 599 '
        '623 617 666 622 683 622 687 623 681 622 661 614 628 609 613 597 590 591 575 586 555 586 547 585 '
        '545ZM187 545 177 545 177 553 173 571 153 615 141 658 140 686 147 661 162 627 170 602 179 '
        '563ZM210 520 193 541 186 554 180 572 171 611 150 664 163 640 193 598 202 580 207 563 209 '
        '550ZM552 519 554 557 558 574 562 584 572 602 603 646 613 666 591 610 583 574 576 553 568 '
        '539ZM618 505 622 526 622 540 615 588 615 615 620 638 623 621 632 593 634 577 634 560 632 543 628 '
        '527ZM144 505 137 519 132 534 128 562 128 574 131 594 135 610 141 626 143 638 148 615 147 613 148 '
        '610 147 586 141 546 141 521ZM600 474 598 491 594 503 590 523 589 548 591 562 596 578 612 613 612 '
        '585 618 550 618 522 612 496ZM162 474 151 494 144 523 144 547 151 592 151 611 169 570 173 554 173 '
        '527 169 505 163 485Z',
    'abdominal': 'M338 532 333 534 329 538 326 549 328 581 337 621 345 643 359 673 367 684 374 690 385 691 391 688 '
        '398 681 404 672 414 652 422 632 431 600 436 567 436 545 434 539 429 534 419 531 395 532 391 534 '
        '386 541 383 556 383 656 381 671 380 670 380 578 379 577 378 544 374 536 365 531ZM328 528 328 534 '
        '333 531ZM381 522 376 533 380 540 381 545 386 534ZM391 478 388 481 384 491 383 512 386 525 390 '
        '528 430 528 435 522 438 508 437 495 434 489 428 483 417 478 407 476 396 476ZM373 479 365 476 350 '
        '477 335 483 328 489 325 498 325 513 327 521 331 527 336 529 373 528 377 525 379 519 379 492 377 '
        '485ZM381 469 380 473 376 477 380 484 381 489 386 479ZM391 432 386 438 383 451 383 461 386 473 '
        '390 475 394 473 405 472 420 476 428 480 434 480 438 476 441 466 441 456 438 447 427 437 410 430 '
        '399 429ZM371 431 363 429 349 431 336 437 327 444 323 450 321 461 324 475 328 480 334 480 342 476 '
        '353 473 368 473 369 474 377 473 379 466 379 446 375 435ZM381 423 379 428 375 431 379 435 381 442 '
        '382 442 382 439 387 430 382 426ZM385 402 383 408 383 420 387 427 408 426 415 428 431 437 439 437 '
        '441 435 444 427 444 417 442 412 417 408 405 404 391 396ZM377 401 372 396 347 408 320 412 318 418 '
        '318 425 324 438 323 443 327 440 326 439 351 427 355 426 370 428 376 427 379 423 380 417 379 405Z',
    'oblicuos': 'M484 500 473 519 455 542 443 561 438 575 434 601 429 621 412 663 437 630 486 580 489 574 491 565 '
        '491 553 484 516ZM278 500 278 518 273 541 271 558 272 570 274 576 277 581 321 625 350 662 333 619 '
        '328 599 325 578 319 560 309 544 289 519ZM482 442 476 451 463 464 441 479 440 483 441 509 440 512 '
        '442 513 439 517 438 522 439 562 448 547 471 517 482 498 486 483 486 464 485 462 481 471 467 491 '
        '449 509 443 513 441 512 464 490 479 469 485 454ZM465 412 446 412 448 424 443 438 444 445 442 446 '
        '444 454 444 468 442 476 460 463 473 450 480 439 481 432 476 423 459 438 450 443 447 442 462 433 '
        '475 421 470 415ZM443 444 444 443 446 444 445 445ZM445 443 446 442 448 443 447 444ZM298 412 290 '
        '417 288 421 299 432 306 437 304 438 299 435 286 423 281 433 282 437 291 452 303 464 320 476 319 '
        '477 316 476 298 463 288 453 281 442 278 451 278 456 280 463 287 476 293 484 317 508 315 509 292 '
        '487 282 473 277 462 277 486 284 505 295 522 314 546 323 563 323 546 325 526 322 517 322 479 319 '
        '477 321 476 318 464 320 440 315 427 316 412ZM315 443 316 442 318 443 317 444ZM313 442 314 441 '
        '316 442 315 443ZM311 441 312 440 314 441 313 442ZM309 440 310 439 312 440 311 441ZM307 439 308 '
        '438 310 439 309 440ZM305 438 306 437 308 438 307 439Z',
    'aductores': 'M390 693 387 695 385 707 385 741 390 771 402 811 404 823 410 784 394 708 392 693ZM372 693 370 '
        '694 362 739 352 783 357 810 358 823 373 768 378 738 378 707 376 696ZM397 688 394 691 412 780 416 '
        '762 426 729 426 722ZM366 688 346 710 336 725 340 744 348 769 350 781 368 695 368 690ZM434 640 '
        '399 686 418 707 427 720 429 719 439 687 438 660ZM328 640 324 665 324 690 335 722 342 710 363 687 '
        '363 685ZM462 609 448 623 437 637 440 653 442 681 456 638ZM301 609 305 633 321 681 322 658 326 '
        '638 319 628Z',
    'cuadriceps': 'M445 756 437 777 418 818 412 839 409 859 410 884 416 904 423 916 430 923 439 928 443 924 451 911 '
        '456 898 459 882 458 854 445 788 445 776 444 775ZM318 756 318 782 315 803 305 851 304 885 310 908 '
        '318 922 324 928 331 924 340 915 347 903 351 891 353 879 353 856 350 838 344 817 325 776ZM496 700 '
        '500 725 500 753 499 754 498 774 488 823 473 867 473 878 476 888 488 909 493 921 516 872 525 842 '
        '528 822 528 790 523 762 511 729ZM266 700 251 730 240 760 235 785 234 816 238 844 244 865 270 921 '
        '287 887 290 876 290 868 276 829 265 777 262 747 262 727ZM477 655 476 655 475 663 467 691 454 727 '
        '448 754 449 791 462 858 461 888 474 856 484 825 493 785 497 750 497 727 493 699ZM286 654 284 662 '
        '274 685 268 705 265 731 265 745 269 783 277 819 289 857 301 887 300 861 313 795 315 778 315 758 '
        '310 732 294 686Z',
    'gemelos': 'M465 1070 459 1093 447 1123 445 1134 447 1154 458 1196 459 1212 463 1150 468 1110 468 1090ZM297 '
        '1069 295 1084 295 1116 300 1155 303 1211 307 1184 317 1147 317 1129 313 1115 303 1092ZM440 992 '
        '431 1020 426 1042 424 1056 424 1073 429 1096 443 1125 461 1078 463 1069 463 1051 456 1023 448 '
        '1005ZM323 992 316 1003 306 1024 299 1051 299 1064 302 1078 315 1111 319 1125 334 1095 337 1086 '
        '339 1070 338 1052 334 1031ZM254 985 240 1013 234 1030 230 1051 230 1072 236 1098 267 1168 256 '
        '1118 250 1071 249 1041 250 1040 250 1023 254 994ZM508 984 513 1035 513 1060 508 1106 496 1166 '
        '525 1102 531 1082 533 1067 532 1047 529 1033 522 1013Z',
    '_base': 'M453 1286 451 1293 451 1306 453 1310 460 1316 460 1311ZM463 1265 456 1274 455 1282 465 1320 465 '
        '1342 471 1349 473 1354 480 1359 489 1359 494 1356 495 1352 486 1337 486 1335 490 1333 496 1342 '
        '500 1356 504 1359 508 1358 511 1355 508 1345 503 1335 504 1333 509 1339 514 1356 516 1357 520 '
        '1356 521 1351 518 1338 513 1333 514 1331 520 1336 525 1353 530 1352 527 1337 522 1332 523 1330 '
        '529 1335 532 1347 534 1349 536 1345 536 1341 533 1331 509 1303 493 1270 486 1263 479 1260 473 '
        '1260ZM301 1266 293 1261 283 1260 278 1262 271 1268 262 1284 255 1301 229 1332 226 1342 228 1349 '
        '230 1348 234 1335 240 1329 241 1332 235 1338 232 1352 234 1353 239 1352 242 1337 247 1332 248 '
        '1335 244 1342 241 1355 245 1357 248 1356 252 1342 259 1332 260 1334 256 1341 252 1353 253 1357 '
        '259 1359 262 1357 265 1350 267 1340 273 1332 274 1334 276 1333 277 1335 268 1350 269 1357 273 '
        '1359 283 1359 288 1356 292 1348 297 1343 298 1317 302 1305 303 1306 302 1317 309 1310 312 1302 '
        '312 1297 309 1286 306 1295 305 1294 307 1284 307 1275ZM303 1301 304 1302 303 1306 302 1305ZM304 '
        '1298 305 1299 304 1302 303 1301ZM305 1294 306 1295 305 1299 304 1298ZM496 1247 494 1254 494 1263 '
        '498 1271 499 1259ZM267 1247 264 1256 264 1270 265 1271 268 1264ZM519 1122 499 1165 488 1200 485 '
        '1219 485 1236 488 1251 491 1258 497 1220 511 1164ZM244 1122 249 1153 268 1232 271 1251 271 1260 '
        '274 1252 277 1236 276 1208 272 1190 266 1172ZM293 1114 290 1144 290 1190 291 1191 292 1214 298 '
        '1243 310 1273 312 1267 312 1257 306 1243 302 1228 299 1186 298 1185 296 1144 295 1143 295 '
        '1127ZM470 1113 461 1223 459 1236 453 1250 450 1261 451 1269 453 1273 464 1244 471 1210 472 1136 '
        '471 1135ZM505 981 484 1016 479 1035 477 1054 477 1132 478 1133 477 1190 474 1216 470 1235 459 '
        '1266 466 1260 474 1257 482 1258 489 1262 482 1240 482 1216 489 1176 501 1128 508 1080 509 1025 '
        '508 1024 508 1011ZM258 981 254 1017 253 1061 254 1062 255 1087 260 1120 276 1188 280 1213 280 '
        '1225 281 1226 280 1243 274 1262 280 1258 289 1257 297 1260 303 1265 293 1237 286 1198 284 1040 '
        '279 1017 273 1005 261 988ZM494 960 488 973 483 991 480 1019 490 990ZM427 947 428 954 435 974 459 '
        '1020 462 1029 469 1068 474 1128 473 1046 470 1023 466 1006 459 989 438 965 429 952ZM336 946 327 '
        '962 309 982 301 993 294 1013 289 1052 288 1140 291 1089 298 1039 306 1015 327 976ZM502 932 497 '
        '956 494 985 490 999 496 991 501 981 504 969 504 940ZM260 931 258 944 259 972 264 988 272 999 268 '
        '981 264 945ZM331 928 323 932 317 926 319 937 319 947ZM300 926 288 926 283 928 277 934 274 943 '
        '275 964 284 999 287 1042 293 1003 302 983 312 967 316 955 316 941 314 936 310 931ZM467 925 456 '
        '929 449 935 447 941 447 957 449 964 463 988 469 1002 474 1027 475 1042 475 1028 479 996 488 960 '
        '488 941 486 935 480 928ZM431 927 443 948 446 925 440 932ZM417 912 422 931 432 952 442 966 450 '
        '974 438 944ZM346 912 324 945 312 975 320 966 333 947 340 932ZM504 905 497 919 493 932 491 962 '
        '498 939ZM259 905 264 938 271 960 270 962 269 961 269 966 273 989 282 1018 282 1008 279 988 274 '
        '970 271 965 272 960 271 959 270 934 265 917ZM270 962 271 961 272 963 271 964ZM470 876 453 913 '
        '448 932 455 926 467 922 478 924 485 929 487 932 488 932 489 926 490 929 489 918 488 917 489 920 '
        '488 924 483 909 474 891ZM293 876 289 890 278 914 275 932 280 927 288 923 300 923 309 927 315 932 '
        '311 917ZM627 805 622 808 616 815 619 814ZM136 805 138 809 146 815 145 812ZM634 789 622 804 631 '
        '797ZM129 789 131 796 141 805 140 802ZM634 689 627 692 616 704 611 715 609 727 610 751 605 771 '
        '605 781 607 783 610 783 613 780 617 769 618 757 621 747 626 740 631 729 632 733 630 739 632 746 '
        '636 753 638 762 638 793 621 821 619 830 627 823 644 799 647 792 649 777 655 758 653 745 641 '
        '702ZM129 689 122 701 118 712 110 743 108 760 113 775 117 797 137 825 141 829 144 830 139 817 125 '
        '793 124 768 126 753 132 741 131 734 132 730 143 751 148 778 152 783 155 783 157 781 158 776 157 '
        '767 152 748 153 721 151 713 145 702 137 693ZM637 688 646 707 658 754 658 759 652 777 649 796 655 '
        '775 662 758 654 719 652 694 644 688ZM125 688 119 688 113 691 111 694 108 722 101 752 101 761 116 '
        '801 113 794 111 780 104 756 109 740 113 719ZM483 610 479 634 480 654 490 681 513 725 521 744 528 '
        '768 530 784 531 773 530 772 529 745 520 699 512 676 492 634ZM279 610 271 632 250 677 240 708 233 '
        '748 232 787 234 770 242 743 270 687 282 657 284 648 284 637ZM484 588 469 603 458 643 425 743 415 '
        '781 409 810 407 827 408 847 409 837 414 819 440 761 466 682 474 650 478 618ZM279 588 287 642 297 '
        '684 323 762 347 815 355 847 355 824 352 801 336 737 303 638 293 601ZM488 586 485 602 487 613 492 '
        '627 505 652 500 619ZM274 585 274 588 264 612 260 627 258 652 270 628 276 610 277 596ZM503 441 '
        '497 452 489 460 489 482 499 464 502 453ZM260 441 262 459 273 481 273 458 264 450ZM503 418 497 '
        '430 485 441 489 456 496 449 501 440 503 432ZM259 417 259 429 261 438 269 452 274 455 278 440 268 '
        '432ZM502 397 500 397 498 403 492 412 480 422 484 430 484 438 495 428 499 422 503 409ZM261 394 '
        '260 406 262 417 268 428 278 438 279 428 282 421 270 410ZM264 390 265 396 270 406 283 419 295 410 '
        '281 405 275 401ZM500 389 485 403 468 410 473 413 479 420 490 410 497 398ZM380 383 373 394 382 '
        '402 389 393 383 383 381 388 380 387ZM397 278 391 278 387 281 384 292 383 309 386 296 391 '
        '286ZM365 278 372 287 377 297 379 307 379 295 376 283 373 278ZM427 202 419 227 405 254 391 275 '
        '400 275 413 267 425 264 421 257 421 248 426 223ZM335 201 336 221 341 244 341 259 338 264 347 266 '
        '364 275 372 276 359 257 347 235 340 218ZM416 186 397 198 383 201 367 199 359 195 347 186 367 243 '
        '381 290 404 217ZM368 189 371 195 377 197 390 196 395 191 395 188 389 181 385 188 382 197 380 196 '
        '378 188 379 187 382 191 384 184 387 180 376 180 379 187 378 188 376 184 373 182ZM427 175 420 184 '
        '415 195 398 245 392 268 409 240 419 218 426 193ZM336 175 336 190 342 214 357 247 371 269 367 253 '
        '350 202 341 181ZM409 169 407 174 403 178 399 180 391 180 398 189 397 194 400 193 406 187 408 '
        '183ZM354 169 354 183 362 192 366 194 365 190 366 186 372 180 365 180 360 178 355 173ZM426 165 '
        '412 170 412 179 410 185 423 174 427 167ZM367 163 371 162 393 162 395 163 387 159 377 159ZM421 '
        '148 413 158 412 163 414 162 416 163 413 166 426 163 426 162 418 163 415 162 420 159ZM341 147 342 '
        '158 345 161 350 162 347 154ZM356 160 356 169 358 173 367 177 377 178 398 177 403 175 406 170 406 '
        '159 397 143 393 148 388 146 383 150 380 150 374 146 370 148 366 143 359 153ZM365 168 367 167 373 '
        '170 390 170 396 167 398 168 393 172 389 173 374 173 368 171ZM403 165 402 166 392 166 391 165 361 '
        '166 360 165 370 158 383 156 391 157ZM430 138 424 145 423 159 427 160 429 158ZM332 138 334 161 '
        '337 160 338 161 336 163 348 167 344 168 335 166 343 178 353 186 350 176 350 169 347 168 350 167 '
        '350 165 337 160 339 159 338 144ZM341 134 356 151 354 145ZM344 133 354 141 359 149 360 148 359 '
        '142 353 137ZM420 129 409 130 397 125 398 141 400 143 403 140 404 141 402 145 404 149 406 144 420 '
        '132 411 136 406 140 404 139 410 134ZM333 113 330 123 330 129 335 137 351 155 353 164 356 154 336 '
        '132 334 128 336 123ZM399 111 399 113 401 114 412 114 415 112 411 109 402 109ZM444 108 440 111 '
        '439 116 441 114 442 116 437 124 434 137 435 145 438 144 443 132 441 134 440 133 442 130 441 122 '
        '442 119 445 125 446 112ZM348 111 351 114 363 113 362 110 355 108ZM318 108 316 111 317 124 319 '
        '120 321 130 320 135 323 142 327 145 328 136 326 131 325 122 317 111 318 110 320 111 324 117 322 '
        '110ZM324 125 327 132 326 137 323 136 325 135 323 130ZM417 98 403 99 395 102 390 107 390 112 393 '
        '118 398 123 404 126 417 127 422 125 425 122 426 124 428 123 429 124 427 128 408 146 406 152 425 '
        '131 426 132 407 154 409 162 415 150 426 139 432 130 432 120 429 114 429 118 428 119 427 118 427 '
        '106 422 100ZM427 118 428 121 426 123 425 121ZM392 114 400 105 405 103 412 104 419 109 418 114 '
        '409 118 395 116ZM342 99 335 106 337 120 340 125 347 128 342 129 356 136 363 143 365 137 365 125 '
        '360 128 357 127 363 124 370 117 372 113 372 105 365 101 353 98ZM347 129 348 128 354 129 353 '
        '130ZM353 128 354 127 358 128 357 129ZM343 111 348 105 358 103 365 107 369 112 369 114 366 116 '
        '355 118 347 116ZM435 68 432 75 430 86 430 102 434 118 438 102 438 92 439 91 438 76ZM327 68 324 '
        '81 324 100 328 118 332 105 333 87 331 75ZM430 57 424 76 424 88 427 96 429 74 434 66ZM333 56 329 '
        '63 329 66 333 73 335 81 335 97 339 86 339 77ZM373 32 358 36 347 42 336 52 335 55 341 49 351 43 '
        '355 42 363 43 368 46 374 53 381 70 381 75 385 59 394 46 402 42 407 42 414 45 413 46 408 45 399 '
        '46 391 53 386 64 383 81 381 85 377 66 370 51 367 48 360 45 355 45 346 48 341 52 337 58 337 62 '
        '342 78 342 88 337 100 345 94 356 93 365 95 373 101 377 109 376 131 374 136 373 129 375 112 369 '
        '123 367 129 367 136 370 134 372 135 369 140 370 144 376 143 382 147 387 143 393 144 393 139 391 '
        '135 392 134 395 136 396 135 394 124 389 115 389 129 390 130 389 140 386 129 386 107 391 99 401 '
        '94 413 93 421 96 427 102 421 90 421 76 426 58 419 50 421 49 427 55 428 54 422 47 407 37 389 '
        '32ZM415 47 417 46 419 48 417 49ZM413 46 414 45 416 46 415 47Z',
  };

  static const String _siluetaDorsal =
      'M381 29 359 34 344 42 333 53 325 69 323 78 324 104 316 106 315 115 321 138 327 148 334 153 334 '
      '163 338 178 338 195 334 204 319 216 285 233 261 251 248 255 231 258 222 261 210 268 196 283 184 '
      '305 177 332 177 352 181 369 184 376 184 380 174 397 167 419 166 443 169 456 168 467 161 484 146 '
      '504 138 519 131 542 128 576 124 594 121 641 117 663 109 686 109 707 104 742 101 754 101 766 108 '
      '781 111 796 116 805 126 818 136 828 143 833 148 834 150 832 150 824 148 816 143 805 136 798 132 '
      '791 129 773 132 756 135 753 137 753 141 759 144 772 149 783 152 785 158 785 161 781 161 771 156 '
      '755 156 724 152 712 146 702 146 696 149 683 154 670 167 645 200 604 212 582 217 562 218 528 220 '
      '523 221 498 231 482 237 465 239 455 246 437 248 427 251 426 262 456 274 479 279 507 279 533 270 '
      '568 271 597 264 611 258 629 252 672 241 715 234 756 234 795 238 824 245 853 264 904 267 922 266 '
      '938 263 952 265 981 263 989 250 1017 242 1040 239 1055 238 1076 240 1091 251 1131 259 1176 271 '
      '1217 273 1228 273 1251 267 1275 268 1286 258 1296 249 1299 240 1304 237 1309 237 1314 246 1325 '
      '252 1328 260 1329 267 1332 278 1342 288 1345 315 1344 322 1340 327 1332 328 1325 322 1305 322 '
      '1291 325 1281 325 1270 316 1243 314 1228 314 1207 319 1177 326 1154 328 1136 344 1108 350 1084 '
      '349 1054 335 1008 334 991 338 977 346 958 352 937 354 919 354 877 356 863 376 781 377 743 374 '
      '724 379 718 381 713 385 711 393 724 390 747 390 771 394 795 408 846 412 866 413 888 414 889 414 '
      '926 416 940 421 957 428 973 434 994 431 1014 422 1039 418 1057 417 1082 423 1107 431 1123 439 '
      '1135 441 1152 450 1184 453 1202 452 1240 442 1271 442 1280 446 1293 446 1302 440 1322 440 1331 '
      '443 1338 452 1344 480 1345 491 1341 502 1331 521 1325 528 1319 531 1312 530 1307 525 1302 508 '
      '1295 499 1285 500 1271 494 1247 494 1232 497 1214 510 1169 519 1119 526 1096 529 1081 529 1060 '
      '524 1035 503 983 504 950 501 935 501 916 507 893 513 880 523 851 530 821 534 783 533 751 528 723 '
      '515 670 510 634 504 613 497 598 497 584 498 583 497 566 488 531 488 511 493 480 508 450 516 426 '
      '519 427 536 481 546 497 550 537 550 558 555 581 566 602 592 633 601 646 614 671 619 685 621 694 '
      '621 703 615 713 611 727 612 752 607 768 606 780 608 784 612 786 615 786 618 784 621 779 626 760 '
      '630 754 635 755 638 774 636 789 622 810 618 819 617 830 619 834 622 834 628 831 653 804 657 790 '
      '666 768 667 754 659 719 658 686 650 662 647 647 643 593 638 567 635 536 626 512 607 485 599 465 '
      '599 453 601 445 600 417 593 396 583 379 589 359 591 346 590 329 584 307 571 282 556 267 543 260 '
      '529 256 511 253 503 249 481 232 450 217 441 211 433 203 429 194 429 180 433 165 434 153 439 150 '
      '442 146 448 133 452 117 452 109 450 105 443 104 444 101 443 71 436 55 422 41 409 34 390 29Z';

  static const Map<String, String> _regionesDorsal = {
    'trapecio': 'M488 259 461 258 460 257 444 257 426 259 415 262 404 267 397 272 389 282 386 291 386 365 385 366 '
        '386 444 395 406 406 370 416 345 427 323 452 283 463 272ZM279 259 298 267 311 278 324 296 343 328 '
        '354 351 362 372 374 412 380 440 382 442 382 296 377 280 364 267 346 260 322 257ZM396 132 391 141 '
        '388 150 385 170 386 281 389 276 398 267 410 260 423 256 435 254 510 255 501 251 482 236 448 219 '
        '438 212 423 197 413 183 405 168 400 154ZM371 132 367 154 361 171 350 190 339 203 321 218 287 235 '
        '269 249 258 255 334 254 346 256 365 264 379 277 382 282 382 171 378 145Z',
    'deltoides_lateral':
        'M515 258 526 262 543 274 553 285 561 297 568 311 573 326 576 346 575 370 581 376 586 358 588 336 '
            '585 318 574 292 566 280 551 267 538 261 523 258ZM253 258 239 259 218 266 208 273 195 289 184 313 '
            '180 330 180 352 186 375 189 374 193 370 192 369 193 332 199 312 208 294 216 283 227 272 238 264Z',
    'deltoides_posterior':
        'M477 268 485 276 491 293 498 307 509 322 522 333 559 356 571 367 572 342 569 325 565 313 558 299 '
            '547 283 531 269 522 264 510 260 496 260ZM290 267 271 260 255 261 246 264 235 270 218 286 206 305 '
            '198 326 195 342 196 367 211 354 248 331 262 318 269 308 284 274Z',
    'romboides':
        'M453 388 442 387 431 384 419 378 410 371 403 391 394 427 399 420 415 406 443 391ZM315 388 331 '
            '394 348 403 360 412 373 426 365 393 357 371 353 375 339 383 326 387ZM446 299 430 325 418 349 411 '
            '367 424 377 437 382 446 384 464 384 459 373 453 351 447 316ZM321 299 320 319 316 343 311 364 303 '
            '384 323 384 331 382 347 375 356 368 349 349 338 326Z',
    'dorsal': 'M519 366 513 371 499 378 462 388 430 401 410 414 401 423 391 439 386 458 386 483 388 495 396 518 '
        '405 537 414 566 424 588 432 584 443 546 450 532 484 487 496 468 504 452 511 433 516 411 519 '
        '384ZM248 366 249 391 252 417 256 433 262 449 275 474 318 533 324 545 335 583 344 588 354 565 359 '
        '547 379 497 381 486 381 458 375 436 368 425 355 412 345 405 314 391 264 376ZM525 339 519 335 516 '
        '335 470 360 461 368 466 380 468 382 472 382 502 373 513 367 519 361ZM242 339 245 347 247 359 255 '
        '367 268 374 296 382 301 381 306 367 296 359 250 334Z',
    'lumbar':
        'M382 498 376 516 367 535 354 574 347 588 347 590 355 596 369 611 378 627 382 640ZM385 496 386 '
            '638 388 630 400 609 410 598 420 591 421 589 414 576 409 559 387 504Z',
    'oblicuos':
        'M489 485 466 515 451 538 445 551 436 582 451 577 466 576 475 578 485 583 494 592 495 587 494 565 '
            '485 530 485 513ZM278 484 282 509 282 532 273 567 273 593 278 587 286 581 301 576 312 576 331 582 '
            '321 547 315 535Z',
    'triceps': 'M531 453 536 473 543 488 563 512 561 489 557 475 552 469ZM237 452 227 461 214 470 210 475 207 '
        '483 205 511 216 499 226 485 231 474ZM572 425 573 428 572 447 564 483 565 505 571 525 589 543 594 '
        '551 593 547 593 475 592 468 586 447 582 439ZM195 425 185 440 179 452 176 463 174 478 174 509 175 '
        '510 174 550 176 546 195 527 199 519 202 507 203 481 195 448ZM545 351 560 379 573 418 581 434 590 '
        '447 595 463 598 445 598 422 596 412 590 396 578 378 559 360ZM222 351 210 359 192 375 180 391 175 '
        '401 171 413 169 426 169 441 173 462 180 442 195 419 202 392ZM528 341 524 357 522 374 522 387 520 '
        '400 521 426 525 438 530 447 539 456 550 463 560 473 562 477 569 442 568 414 560 389 541 349ZM239 '
        '341 227 348 209 386 200 411 198 421 198 444 202 464 206 476 208 472 216 464 226 458 236 448 243 '
        '436 246 426 247 394 245 384 243 353Z',
    'antebrazo': 'M638 580 640 599 639 638 638 639 639 668 642 681 644 685 649 689 644 658 645 646 643 636 642 '
        '611ZM130 578 126 601 122 652 113 683 113 687 114 687 119 669 121 654 123 651 124 655 118 689 124 '
        '685 128 672 129 636 128 635 127 603ZM588 568 596 603 622 664 627 680 629 692 631 685 632 669 628 '
        '646 617 618ZM179 568 159 601 148 623 141 641 136 662 136 685 138 692 140 680 145 665 162 627 173 '
        '598ZM552 532 553 560 556 575 560 586 571 604 596 634 605 647 619 676 622 685 623 695 625 698 625 '
        '686 616 658 595 611 582 562 577 553ZM215 532 199 545 188 556 181 575 174 607 153 654 144 679 142 '
        '688 143 698 148 677 162 648 196 604 209 582 215 560ZM611 526 606 558 607 576 613 599 628 635 634 '
        '656 635 663 635 683 633 688 633 693 643 689 638 680 635 667 635 637 636 636 635 583 633 572 627 '
        '554 613 527ZM156 525 140 555 136 566 132 585 131 595 132 669 128 683 124 689 134 693 134 687 132 '
        '681 132 665 134 653 140 633 153 604 160 578 161 551ZM550 502 550 520 553 528 576 548 565 '
        '520ZM218 502 210 510 202 521 196 533 192 547 206 536 215 526 218 519ZM162 488 146 510 139 524 '
        '133 545 132 563 153 522ZM605 487 614 522 625 541 636 564 633 540 626 518 614 498ZM597 479 596 '
        '544 601 567 600 571 590 550 575 534 575 536 581 551 608 595 603 570 603 548 608 525 608 514 604 '
        '495ZM600 571 601 570 602 572 601 573ZM171 478 165 490 159 514 160 528 165 558 164 574 159 596 '
        '170 576 185 553 193 534 188 538 179 548 167 572 166 568 171 542Z',
    'gluteo': 'M343 592 337 592 317 602 305 611 291 625 281 638 267 664 262 678 258 698 258 721 265 752 266 772 '
        '276 761 287 755 299 751 339 742 358 734 364 730 374 720 379 711 382 692 382 660 378 637 370 619 '
        '363 609 352 598ZM426 591 417 597 404 610 398 618 389 638 386 652 386 682 385 683 386 702 389 713 '
        '394 721 403 730 409 734 432 743 453 747 480 755 495 764 501 771 502 754 510 716 509 693 501 666 '
        '488 641 473 621 464 612 448 600 437 594ZM279 591 272 600 263 622 257 651 255 671 249 697 260 674 '
        '266 657 270 635 272 614ZM487 590 489 593 495 613 498 639 502 659 507 673 518 696 518 692 513 675 '
        '508 636 505 624 496 601 490 592ZM431 589 446 595 467 610 484 629 497 651 491 611 486 594 481 585 '
        '468 580 455 580 440 584ZM337 589 325 583 313 580 301 580 287 585 282 593 278 604 275 617 271 649 '
        '284 628 304 607 323 594Z',
    'isquiotibiales': 'M469 755 483 782 490 800 494 814 498 837 498 869 491 914 491 940 492 940 493 927 504 886 510 847 '
        '509 812 503 786 497 772 486 762ZM298 755 283 761 277 765 271 772 262 793 258 813 257 839 258 840 '
        '259 861 264 888 274 924 276 942 276 913 269 859 270 832 275 808 281 790ZM462 753 466 778 467 808 '
        '468 809 467 839 462 875 463 906 469 926 479 946 498 977 490 953 487 936 488 908 495 862 493 828 '
        '489 809 479 781 469 761ZM305 753 299 760 286 787 279 807 274 830 273 869 280 914 280 940 270 976 '
        '285 952 297 929 305 903 306 883 300 832 300 793ZM447 750 441 779 423 835 419 853 417 870 417 883 '
        '419 893 436 935 437 948 438 948 445 930 457 888 463 848 463 834 464 833 464 800 458 752ZM310 752 '
        '307 762 304 786 304 806 303 807 304 840 311 891 316 911 330 949 332 933 335 924 344 906 349 890 '
        '350 865 343 830 326 778 320 750Z',
    'aductores':
        'M396 728 393 745 393 772 399 804 413 857 414 868 416 851 420 833 439 773 443 756 443 749 420 743 '
            '410 738ZM371 728 364 734 350 742 324 750 327 768 350 844 353 868 356 850 371 793 374 775 375 753 '
            '373 734Z',
    'cuadriceps':
        'M254 704 248 742 248 771 254 826 256 805 263 781 263 763 254 718ZM513 703 513 720 506 751 504 '
            '769 504 780 509 794 512 809 513 827 519 773 519 734Z',
    'gemelos': 'M269 984 255 1012 246 1036 242 1054 241 1077 243 1091 250 1113 272 1160 280 1173 285 1187 284 '
        '1176 282 1172 283 1170 277 1146 276 1131 268 1123 260 1108 254 1091 250 1068 250 1051 253 1031 '
        '258 1013ZM497 981 508 1009 514 1030 517 1049 517 1070 515 1084 509 1104 500 1122 491 1132 491 '
        '1143 484 1173 482 1188 487 1175 517 1114 523 1096 526 1080 526 1058 522 1038 512 1011ZM438 964 '
        '437 965 438 997 422 1051 420 1063 420 1082 422 1094 427 1109 435 1124 444 1135 455 1104 459 1086 '
        '460 1076 459 998 457 984 454 975 450 969 442 964ZM329 964 325 964 321 966 314 974 310 986 308 '
        '1004 308 1083 313 1107 323 1135 325 1134 334 1121 341 1107 346 1091 348 1076 346 1053 330 999 '
        '329 993 330 965ZM478 963 470 970 466 979 464 989 463 1017 462 1018 463 1054 466 1079 471 1097 '
        '483 1118 489 1126 492 1127 500 1115 509 1093 513 1075 514 1051 509 1025 492 976 486 964ZM289 963 '
        '283 963 280 966 276 974 272 989 259 1022 254 1046 254 1072 258 1093 268 1117 276 1127 281 1123 '
        '287 1115 295 1100 301 1081 304 1058 305 1005 303 987 301 978 297 969Z',
    '_base': 'M297 1302 288 1310 283 1318 279 1328 279 1337 281 1340 287 1342 301 1343 315 1341 318 1339 320 '
        '1334 317 1318 313 1310 307 1303ZM462 1302 455 1309 451 1317 448 1327 449 1338 456 1342 465 1343 '
        '481 1342 486 1340 488 1338 489 1332 483 1315 479 1309 471 1302 466 1301ZM449 1298 448 1298 448 '
        '1305 443 1321 443 1333 445 1336 444 1333 445 1326 450 1312ZM489 1297 485 1304 485 1313 491 1327 '
        '492 1336 495 1331 495 1322 490 1303 490 1297ZM319 1297 317 1311 322 1323 323 1335 325 1325 319 '
        '1303ZM278 1297 278 1304 272 1323 272 1330 275 1336 278 1322 283 1313 282 1304ZM273 1293 272 1293 '
        '271 1301 263 1317 263 1324 267 1328 270 1323 274 1306ZM495 1292 493 1302 499 1328 501 1328 505 '
        '1323 505 1317 496 1300ZM499 1289 499 1298 508 1316 508 1324 506 1327 518 1324 524 1319 525 1317 '
        '524 1312 513 1304ZM269 1289 257 1302 246 1309 243 1313 244 1320 249 1324 261 1327 259 1324 259 '
        '1318 268 1300ZM482 1244 477 1256 474 1272 476 1293 481 1306 489 1290 489 1282 483 1264ZM285 1244 '
        '285 1262 279 1278 278 1290 285 1302 286 1307 292 1289 293 1265 290 1253ZM456 1224 453 1249 445 '
        '1270 445 1281 453 1301 456 1288 457 1265 458 1264 458 1240ZM312 1224 310 1239 310 1280 313 1298 '
        '315 1301 317 1293 322 1283 323 1273 314 1247ZM275 1172 280 1195 284 1232 293 1255 292 1233 289 '
        '1212 283 1189ZM493 1170 485 1189 480 1206 475 1241 475 1253 483 1235 487 1199ZM325 1139 321 1162 '
        '325 1146ZM515 1125 506 1143 497 1167 487 1221 485 1253 486 1261 493 1285 492 1290 495 1287 498 '
        '1278 497 1269 492 1254 491 1246 492 1226 495 1211 507 1170ZM252 1124 263 1181 275 1222 276 1248 '
        '270 1274 270 1282 275 1290 275 1282 282 1258 282 1240 279 1210 270 1165 264 1149ZM463 1079 458 '
        '1107 447 1136 448 1155 455 1195 461 1244 461 1272 456 1303 459 1300 464 1298 471 1298 475 1301 '
        '471 1281 472 1235 481 1170 488 1141 487 1129 472 1107 468 1099ZM305 1079 299 1099 292 1113 280 '
        '1129 280 1141 289 1185 296 1243 297 1271 295 1290 292 1301 297 1298 303 1298 311 1302 307 1279 '
        '307 1238 315 1178 320 1152 320 1135 307 1099ZM498 921 496 930 496 955 500 971 501 969 501 949 '
        '498 932ZM269 919 269 935 266 950 267 971 272 950 272 934ZM458 898 454 915 437 961 444 961 448 '
        '963 455 970 460 982 461 990 463 977 468 967 475 961 481 960 483 958 477 949 467 929 461 911 459 '
        '898ZM309 897 307 910 301 928 284 959 291 960 299 966 305 979 306 988 307 988 309 977 314 968 323 '
        '961 330 961 326 947 313 914ZM416 893 416 914 418 933 422 951 431 975 434 951 433 938 428 923 420 '
        '907ZM351 893 350 899 340 921 334 939 334 961 336 976 341 964 349 937 352 908ZM615 743 614 755 '
        '610 768 610 780 612 783 618 779 623 760 627 752 621 749ZM153 743 141 753 145 762 149 778 151 781 '
        '156 783 158 780 158 771 154 758ZM658 721 658 728 662 751 662 766 657 776 653 792 648 800 637 812 '
        '622 821 620 827 633 819 652 800 658 778 664 765 664 756 660 738ZM110 718 103 764 108 775 116 801 '
        '132 817 147 827 146 821 130 811 118 799 114 792 111 778 105 766 105 753 109 733ZM141 701 144 710 '
        '145 720 141 736 133 751 147 745 151 741 154 733 151 716 147 708ZM627 700 620 709 615 719 614 735 '
        '617 741 621 745 626 748 634 750 629 742 623 725 623 711ZM252 698 244 717 240 733 237 754 236 781 '
        '237 782 238 806 242 830 248 853 260 886 250 826 245 778 245 756 244 755 246 726ZM515 697 522 731 '
        '523 768 516 837 507 887 521 847 528 816 531 792 531 758 529 742 524 720ZM646 692 639 694 645 698 '
        '651 709 656 732 657 754 656 755 655 754 652 727 647 708 641 698 634 697 631 699 627 709 626 715 '
        '627 727 630 736 640 754 648 758 644 760 643 762 643 770 644 771 649 769 652 770 645 774 642 787 '
        '644 790 641 791 625 809 624 815 634 810 645 799 649 793 655 773 660 762 655 731 652 696ZM122 692 '
        '117 694 114 701 111 741 107 762 112 772 119 795 130 807 138 813 143 815 143 810 141 807 134 802 '
        '129 793 123 791 125 788 123 775 116 770 117 769 124 770 125 766 124 761 119 758 124 756 132 747 '
        '140 728 141 723 140 707 136 699 132 696 127 698 120 708 114 735 113 753 112 754 110 751 112 728 '
        '116 710 121 699 128 694ZM648 662 651 681 654 687 655 685 650 672ZM515 332 500 317 497 317 481 '
        '333 472 346 464 361 478 351ZM253 332 288 350 302 359 288 335 281 326 272 318 267 316ZM461 279 '
        '452 289 449 298 454 337 460 361 479 330 494 315 483 309 477 303ZM307 279 290 303 274 315 290 332 '
        '308 362 316 321 318 294 314 287ZM467 273 464 276 464 278 476 296 485 306 497 312 488 295 484 282 '
        '480 275 474 270ZM303 275 296 270 293 270 289 273 283 283 279 296 271 311 278 309 289 299 304 '
        '277ZM352 127 345 133 338 144 341 168 341 194 345 187 348 174ZM415 126 419 173 423 188 427 194 '
        '426 170 430 145 421 131ZM405 125 400 128 401 143 408 166 418 184 413 153 412 126ZM363 125 356 '
        '125 355 129 354 157 349 185 359 166 367 141 368 131 367 128ZM448 107 445 108 443 111 433 147 434 '
        '149 438 147 446 130 449 118 449 108ZM319 107 318 116 323 135 328 145 332 149 334 149 325 112 322 '
        '108ZM437 65 431 73 424 87 421 96 419 109 422 126 431 141 439 113 442 93 441 75ZM330 65 326 79 '
        '326 101 329 117 336 141 346 124 348 115 348 107 342 84 337 74ZM392 32 379 32 356 38 343 46 337 '
        '52 332 60 332 62 342 76 349 94 351 103 350 123 356 121 362 121 368 124 376 133 380 141 383 153 '
        '384 153 390 135 399 124 405 121 412 121 418 124 416 111 417 110 417 99 420 87 426 74 436 62 430 '
        '52 420 43 407 36Z',
  };

  static const List<Color> _paradasCalor = [
    Color(0xFF22C55E), // verde
    Color(0xFFEAB308), // amarillo
    Color(0xFFF97316), // naranja
    Color(0xFFDC2626), // rojo
    Color(0xFF550000), // granate
  ];

  Color _colorCalor(double intensidad) {
    final t = math.sqrt(intensidad.clamp(0.0, 1.0));
    final escalado = t * (_paradasCalor.length - 1);
    final indice = escalado.floor().clamp(0, _paradasCalor.length - 2);
    final fraccion = escalado - indice;
    return Color.lerp(
        _paradasCalor[indice], _paradasCalor[indice + 1], fraccion)!;
  }

  String _hexColor(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  String _construirSvgSemana(Map<String, double> intensidades) {
    final tema = FlutterFlowTheme.of(context);
    final frontal = _vistaSemanal == 'frontal';
    final silueta = frontal ? _siluetaFrontal : _siluetaDorsal;
    final regiones = frontal ? _regionesFrontal : _regionesDorsal;
    final colorLineas = _hexColor(tema.primaryBackground);

    final svg = StringBuffer()
      ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="$_viewBox">')
      ..write('<path d="$silueta" fill="$colorLineas"/>');

    regiones.forEach((id, d) {
      String relleno;
      String opacidad = '1';
      if (id == '_base') {
        relleno = _colorBase;
      } else {
        final intensidad = intensidades[id] ?? 0;
        if (intensidad <= 0) {
          relleno = _colorReposo;
        } else {
          relleno = _hexColor(_colorCalor(intensidad));
          opacidad = (0.18 + 0.82 * intensidad).toStringAsFixed(2);
        }
      }
      svg.write(
          '<path d="$d" fill="$relleno" fill-opacity="$opacidad" fill-rule="evenodd"/>');
    });

    svg.write('</svg>');
    return svg.toString();
  }

  Widget _selectorVistaSemanal() {
    final tema = FlutterFlowTheme.of(context);

    Widget opcion(String valor, String texto) {
      final activo = _vistaSemanal == valor;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _vistaSemanal = valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo ? tema.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              texto,
              style: tema.bodyMedium.copyWith(
                color: activo ? Colors.white : tema.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tema.primaryBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tema.alternate),
      ),
      child: Row(
          children: [opcion('frontal', 'Frente'), opcion('dorsal', 'Espalda')]),
    );
  }

  Widget _leyendaSemanal() {
    final tema = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Text('Menos',
            style: tema.bodySmall.copyWith(color: tema.secondaryText)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                  colors: List.generate(6, (i) => _colorCalor(i / 5))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Más trabajado',
            style: tema.bodySmall.copyWith(color: tema.secondaryText)),
      ],
    );
  }

  Widget _tarjetaCuerpoSemana() {
    final tema = FlutterFlowTheme.of(context);

    if (_entrenosRecientes == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Center(child: CircularProgressIndicator(color: tema.primary)),
      );
    }

    final intensidades = _intensidadesSemana();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.accessibility_new_rounded,
                size: 20, color: tema.primary),
            const SizedBox(width: 8),
            Text('Cuerpo trabajado esta semana',
                style: tema.titleSmall.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text('Últimos 7 días · acumulado de todos tus entrenos',
              style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          const SizedBox(height: 14),
          if (intensidades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Todavía no hay entrenos esta semana.',
                  textAlign: TextAlign.center,
                  style: tema.bodyMedium.copyWith(color: tema.secondaryText)),
            )
          else ...[
            _selectorVistaSemanal(),
            const SizedBox(height: 14),
            Container(
              height: 400,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: tema.primaryBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Builder(
                  key: ValueKey(_vistaSemanal),
                  builder: (context) {
                    final svg = _construirSvgSemana(intensidades);
                    return SvgPicture.string(svg, fit: BoxFit.contain);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _leyendaSemanal(),
          ],
        ],
      ),
    );
  }

  String _fecha(DateTime f) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${f.day} ${meses[f.month - 1]}';
  }

  // ---------- Cabecera ----------

  Widget _cabecera() {
    final tema = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.safePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: tema.primaryText, size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Estadísticas',
                style: tema.titleLarge.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------- Sección 1: peso y % de grasa ----------

  Widget _tarjetaGrafica({
    required String titulo,
    required Color acento,
    required List<FlSpot> puntos,
    required String sufijo,
    required String? etiquetaVacio,
    DateTime? primeraFecha,
    DateTime? ultimaFecha,
  }) {
    final tema = FlutterFlowTheme.of(context);

    Widget cuerpo;
    if (puntos.length < 2) {
      cuerpo = SizedBox(
        height: 140,
        child: Center(
          child: Text(
            etiquetaVacio ??
                'Necesitas al menos dos registros para ver la evolución.',
            textAlign: TextAlign.center,
            style: tema.bodySmall.copyWith(color: tema.secondaryText),
          ),
        ),
      );
    } else {
      final minY = puntos.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final maxY = puntos.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      final margen = ((maxY - minY).abs() * 0.15).clamp(0.5, double.infinity);
      cuerpo = SizedBox(
        height: 140,
        child: LineChart(
          LineChartData(
            minX: puntos.first.x,
            maxX: puntos.last.x,
            minY: minY - margen,
            maxY: maxY + margen,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              show: false,
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tema.primaryBackground,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${_numeroCorto(s.y)} $sufijo',
                          tema.bodySmall.copyWith(
                              color: tema.primaryText,
                              fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: puntos,
                isCurved: true,
                curveSmoothness: 0.2,
                color: acento,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData:
                    BarAreaData(show: true, color: _tinte(acento, 0.12)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: acento, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(titulo,
                  style: tema.titleSmall.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
              if (puntos.isNotEmpty) ...[
                const Spacer(),
                Text('${_numeroCorto(puntos.last.y)} $sufijo',
                    style: tema.titleSmall
                        .copyWith(color: acento, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          cuerpo,
          if (puntos.length >= 2 &&
              primeraFecha != null &&
              ultimaFecha != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fecha(primeraFecha),
                    style: tema.bodySmall.copyWith(color: tema.secondaryText)),
                Text(_fecha(ultimaFecha),
                    style: tema.bodySmall.copyWith(color: tema.secondaryText)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _seccionPesoYGrasa(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final tema = FlutterFlowTheme.of(context);
    final puntosPeso = <FlSpot>[];
    final puntosGrasa = <FlSpot>[];
    DateTime? primeraPeso, ultimaPeso, primeraGrasa, ultimaGrasa;

    for (var i = 0; i < docs.length; i++) {
      final datos = docs[i].data();
      final fechaTs = datos['fecha'];
      if (fechaTs is! Timestamp) continue;
      final x = i.toDouble();

      final peso = (datos['pesoKg'] as num?)?.toDouble();
      if (peso != null && peso > 0) {
        puntosPeso.add(FlSpot(x, peso));
        primeraPeso ??= fechaTs.toDate();
        ultimaPeso = fechaTs.toDate();
      }

      final grasa = (datos['grasaCorporalPct'] as num?)?.toDouble();
      if (grasa != null && grasa > 0) {
        puntosGrasa.add(FlSpot(x, grasa));
        primeraGrasa ??= fechaTs.toDate();
        ultimaGrasa = fechaTs.toDate();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaGrafica(
          titulo: 'Peso corporal',
          acento: tema.primary,
          puntos: puntosPeso,
          sufijo: 'kg',
          etiquetaVacio:
              'Registra tu peso más de una vez en Perfil para ver aquí su evolución.',
          primeraFecha: primeraPeso,
          ultimaFecha: ultimaPeso,
        ),
        _tarjetaGrafica(
          titulo: '% de grasa estimado',
          acento: tema.tertiary,
          puntos: puntosGrasa,
          sufijo: '%',
          etiquetaVacio:
              'Rellena cuello y cintura (y cadera si aplica) en Perfil, más de una vez, '
              'para ver aquí la evolución. Es una estimación (método de la Marina de '
              'EE. UU.), no una medición real.',
          primeraFecha: primeraGrasa,
          ultimaFecha: ultimaGrasa,
        ),
      ],
    );
  }

  // ---------- Sección 4: resumen rápido ----------

  int _contarEntrenosEn(DateTime inicio, DateTime fin) {
    if (_entrenosRecientes == null) return 0;
    var total = 0;
    for (final entreno in _entrenosRecientes!) {
      final f = entreno['fecha'];
      if (f is! Timestamp) continue;
      final fecha = f.toDate();
      if (!fecha.isBefore(fin) || fecha.isBefore(inicio)) continue;
      total++;
    }
    return total;
  }

  /// Días desde la última vez que cada grupo muscular apareció como motor
  /// principal en un entreno, a partir de los mismos entrenos recientes.
  Map<String, int?> _diasDesdeGrupo() {
    final resultado = <String, int?>{for (final g in _ordenGrupos) g: null};
    if (_entrenosRecientes == null) return resultado;
    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);

    for (final entreno in _entrenosRecientes!) {
      final f = entreno['fecha'];
      if (f is! Timestamp) continue;
      final fecha = f.toDate();
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      final dias = hoyFecha.difference(dia).inDays;

      final ejercicios = entreno['ejercicios'];
      if (ejercicios is! List) continue;
      final gruposDeEsteEntreno = <String>{};
      for (final ej in ejercicios) {
        if (ej is! Map) continue;
        final musculos = ej['musculos'];
        if (musculos is! List) continue;
        for (final m in musculos) {
          if (m is! Map) continue;
          if ((m['rol'] ?? '').toString().toLowerCase() != 'principal')
            continue;
          final grupo =
              _grupoMuscular[(m['musculo'] ?? '').toString().toLowerCase()];
          if (grupo != null) gruposDeEsteEntreno.add(grupo);
        }
      }
      for (final grupo in gruposDeEsteEntreno) {
        final actual = resultado[grupo];
        if (actual == null || dias < actual) resultado[grupo] = dias;
      }
    }
    return resultado;
  }

  String _textoDias(int? dias) {
    if (dias == null) return 'sin datos';
    if (dias == 0) return 'hoy';
    if (dias == 1) return 'ayer';
    return 'hace $dias días';
  }

  Widget _tarjetaNutricion() {
    final tema = FlutterFlowTheme.of(context);

    if (_comidasRecientes == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Center(child: CircularProgressIndicator(color: tema.primary)),
      );
    }

    final periodos = [
      ('Esta semana', _mediaNutricion(7)),
      ('Este mes', _mediaNutricion(30)),
      ('Últimos 6 meses', _mediaNutricion(182)),
      ('Este año', _mediaNutricion(365)),
    ];

    if (periodos.every((p) => p.$2 == null)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.restaurant_rounded, size: 20, color: tema.secondary),
              const SizedBox(width: 8),
              Text('Nutrición',
                  style: tema.titleSmall.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            Text('Todavía no hay comidas guardadas.',
                style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant_rounded, size: 20, color: tema.secondary),
            const SizedBox(width: 8),
            Text('Nutrición — media diaria',
                style: tema.titleSmall.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          for (final periodo in periodos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(periodo.$1,
                      style: tema.bodyMedium.copyWith(
                          color: tema.primaryText,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  if (periodo.$2 == null)
                    Text('sin datos',
                        style:
                            tema.bodySmall.copyWith(color: tema.secondaryText))
                  else
                    Text(
                      '${_miles(periodo.$2!['kcal']!.round())} kcal   ·   '
                      'P ${periodo.$2!['proteinaG']!.round()} g   ·   '
                      'C ${periodo.$2!['carbosG']!.round()} g   ·   '
                      'G ${periodo.$2!['grasaG']!.round()} g',
                      style: tema.bodySmall.copyWith(
                          color: tema.secondary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaPasos() {
    final tema = FlutterFlowTheme.of(context);

    if (_pasosRecientes == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Center(child: CircularProgressIndicator(color: tema.primary)),
      );
    }

    final periodos = [
      ('Esta semana', _mediaPasos(7)),
      ('Este mes', _mediaPasos(30)),
      ('Últimos 6 meses', _mediaPasos(182)),
      ('Este año', _mediaPasos(365)),
    ];

    if (periodos.every((p) => p.$2 == null)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.directions_walk_rounded,
                  size: 20, color: tema.secondary),
              const SizedBox(width: 8),
              Text('Pasos',
                  style: tema.titleSmall.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            Text(
                'Todavía no hay pasos guardados. Se registran solos al abrir Home.',
                style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.directions_walk_rounded,
                size: 20, color: tema.secondary),
            const SizedBox(width: 8),
            Text('Pasos — media diaria',
                style: tema.titleSmall.copyWith(
                    color: tema.primaryText, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          for (final periodo in periodos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(periodo.$1,
                        style:
                            tema.bodyMedium.copyWith(color: tema.primaryText)),
                  ),
                  Text(
                    periodo.$2 == null
                        ? 'sin datos'
                        : '${_miles(periodo.$2!.round())} pasos',
                    style: tema.bodyMedium.copyWith(
                      color: periodo.$2 == null
                          ? tema.secondaryText
                          : tema.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resumenRapido() {
    final tema = FlutterFlowTheme.of(context);

    if (_entrenosRecientes == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tema.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.alternate),
        ),
        child: Center(child: CircularProgressIndicator(color: tema.primary)),
      );
    }

    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final inicioSemana =
        hoyFecha.subtract(Duration(days: hoyFecha.weekday - 1));
    final inicioSemanaAnterior = inicioSemana.subtract(const Duration(days: 7));
    final estaSemana =
        _contarEntrenosEn(inicioSemana, hoyFecha.add(const Duration(days: 1)));
    final semanaAnterior =
        _contarEntrenosEn(inicioSemanaAnterior, inicioSemana);
    final dias = _diasDesdeGrupo();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.secondaryBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen rápido',
              style: tema.titleSmall.copyWith(
                  color: tema.primaryText, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: tema.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Entrenos esta semana',
                    style: tema.bodyMedium.copyWith(color: tema.primaryText)),
              ),
              Text('$estaSemana',
                  style: tema.bodyLarge.copyWith(
                      color: tema.primaryText, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('(semana pasada: $semanaAnterior)',
                  style: tema.bodySmall.copyWith(color: tema.secondaryText)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: tema.alternate),
          const SizedBox(height: 8),
          Text('Última vez que trabajaste cada grupo',
              style: tema.bodySmall.copyWith(color: tema.secondaryText)),
          const SizedBox(height: 10),
          for (final grupo in _ordenGrupos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_nombreGrupo[grupo]!,
                        style:
                            tema.bodyMedium.copyWith(color: tema.primaryText)),
                  ),
                  Text(
                    _textoDias(dias[grupo]),
                    style: tema.bodyMedium.copyWith(
                      color: (dias[grupo] ?? 99) >= 8
                          ? tema.warning
                          : tema.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final tema = FlutterFlowTheme.of(context);
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: tema.primaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(
              child: _pesosStream == null
                  ? Center(
                      child: Text('Inicia sesión para ver tus estadísticas.',
                          style: tema.bodyMedium
                              .copyWith(color: tema.secondaryText)),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _pesosStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: tema.primary));
                        }
                        final docs = snap.data?.docs ?? [];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _seccionPesoYGrasa(docs),
                              _tarjetaCuerpoSemana(),
                              _tarjetaNutricion(),
                              _tarjetaPasos(),
                              _resumenRapido(),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
