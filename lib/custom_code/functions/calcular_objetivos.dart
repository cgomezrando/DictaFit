import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/flutter_flow/custom_functions.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/auth_util.dart';

ObjetivosStruct calcularObjetivos(
  String sexo,
  double pesoKg,
  int alturaCm,
  DateTime fechaNacimiento,
  String actividad,
  String objetivo,
) {
// Edad exacta a partir de la fecha de nacimiento
  final ahora = DateTime.now();
  int edad = ahora.year - fechaNacimiento.year;
  if (ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month &&
          ahora.day < fechaNacimiento.day)) {
    edad--;
  }

  // Tasa metabólica basal (Mifflin-St Jeor)
  final double ajusteSexo = sexo == 'mujer' ? -161.0 : 5.0;
  final double tmb = 10.0 * pesoKg + 6.25 * alturaCm - 5.0 * edad + ajusteSexo;

  // Factor de actividad
  const Map<String, double> factoresActividad = {
    'sedentario': 1.2,
    'ligero': 1.375,
    'moderado': 1.55,
    'alto': 1.725,
    'muy_alto': 1.9,
  };
  final double factorActividad = factoresActividad[actividad] ?? 1.55;

  // Ajuste por objetivo
  const Map<String, double> factoresObjetivo = {
    'perder': 0.8,
    'mantener': 1.0,
    'ganar': 1.1,
  };
  final double factorObjetivo = factoresObjetivo[objetivo] ?? 1.0;

  final double kcal = tmb * factorActividad * factorObjetivo;

  // Proteína: 2,0 g/kg en déficit, 1,8 g/kg en el resto
  final double proteinaG = pesoKg * (objetivo == 'perder' ? 2.0 : 1.8);

  // Grasa: 25 % de las kcal, con un mínimo de 0,8 g/kg
  final double grasaPorPorcentaje = kcal * 0.25 / 9.0;
  final double grasaMinima = pesoKg * 0.8;
  final double grasaG =
      grasaPorPorcentaje > grasaMinima ? grasaPorPorcentaje : grasaMinima;

  // Carbohidratos: el resto de kcal
  final double kcalRestantes = kcal - proteinaG * 4.0 - grasaG * 9.0;
  final double carbosG = kcalRestantes > 0 ? kcalRestantes / 4.0 : 0.0;

  return ObjetivosStruct(
    kcal: kcal.round(),
    proteinaG: proteinaG.round(),
    carbosG: carbosG.round(),
    grasaG: grasaG.round(),
  );
}
