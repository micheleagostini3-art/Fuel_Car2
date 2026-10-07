import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/refuel_record.dart';
import 'package:csv/csv.dart';

class CSVService {
  static const String fileName = 'fuel_car_data.csv';
  static const String csvHeader =
      'data,ora,km,tipologia,prezzo,importo_pagato,note,km_litro,km_euro\n';

  // Ottieni il percorso del file CSV
  static Future<File> get csvFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  // Verifica se il file esiste
  static Future<bool> csvExists() async {
    final file = await csvFile;
    return file.exists();
  }

  // Crea il file se non esiste
  static Future<void> initializeCSV() async {
    final file = await csvFile;
    if (!file.existsSync()) {
      await file.create(recursive: true);
      await file.writeAsString(csvHeader);
    }
  }

  // Leggi tutti i record
  static Future<List<RefuelRecord>> readRecords() async {
    try {
      await initializeCSV();
      final file = await csvFile;
      final contents = await file.readAsString();
      final lines = contents.split('\n');

      List<RefuelRecord> records = [];

      // Salta l'header
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        try {
          final row = CsvToListConverter().convert(lines[i]);
          if (row.isNotEmpty && row[0].toString().isNotEmpty) {
            records.add(RefuelRecord.fromCSVRow(row[0]));
          }
        } catch (e) {
          continue;
        }
      }

      // Ordina per data decrescente (più recenti in alto)
      records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return records;
    } catch (e) {
      return [];
    }
  }

  // Aggiungi un nuovo record
  static Future<void> addRecord(RefuelRecord record) async {
    try {
      await initializeCSV();
      final file = await csvFile;
      final csvRow = record.toCSVRow() + '\n';
      await file.writeAsString(csvRow, mode: FileMode.append);
    } catch (e) {
      rethrow;
    }
  }

  // Cancella il file (reset completo)
  static Future<void> deleteCSV() async {
    try {
      final file = await csvFile;
      if (file.existsSync()) {
        await file.delete();
      }
      await initializeCSV();
    } catch (e) {
      rethrow;
    }
  }

  // Ottieni l'ultimo tipo di carburante selezionato
  static Future<String?> getLastFuelType() async {
    try {
      final records = await readRecords();
      if (records.isNotEmpty) {
        final lastRecord = records.first;
        if (lastRecord.fuelType != 'SERVICE') {
          return lastRecord.fuelType;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calcola KM/Litro e KM/Euro
  static Future<Map<String, double>> calculateMetrics(
      int currentKm, double liters, double euroSpent) async {
    try {
      final records = await readRecords();

      double kmPerLiter = 0;
      double kmPerEuro = 0;

      if (records.isNotEmpty) {
        final lastRecord = records.first;
        final kmDifference = currentKm - lastRecord.km;

        if (kmDifference > 0) {
          if (liters > 0) {
            kmPerLiter = kmDifference / liters;
          }
          if (euroSpent > 0) {
            kmPerEuro = kmDifference / euroSpent;
          }
        }
      }

      return {'kmPerLiter': kmPerLiter, 'kmPerEuro': kmPerEuro};
    } catch (e) {
      return {'kmPerLiter': 0, 'kmPerEuro': 0};
    }
  }

  // Statistiche: consumo medio nel mese
  static Future<Map<String, dynamic>> getMonthlyStats(
      DateTime month) async {
    try {
      final records = await readRecords();

      final monthRecords = records
          .where((r) =>
              r.dateTime.year == month.year &&
              r.dateTime.month == month.month)
          .toList();

      if (monthRecords.isEmpty) {
        return {
          'count': 0,
          'avgKmPerLiter': 0,
          'avgKmPerEuro': 0,
          'totalSpent': 0,
          'totalKm': 0,
        };
      }

      double totalKmPerLiter = 0;
      double totalKmPerEuro = 0;
      double totalSpent = 0;
      int totalKm = 0;

      for (var record in monthRecords) {
        totalKmPerLiter += record.kmPerLiter;
        totalKmPerEuro += record.kmPerEuro;
        totalSpent += record.amount;
        totalKm += record.km;
      }

      return {
        'count': monthRecords.length,
        'avgKmPerLiter':
            (totalKmPerLiter / monthRecords.length).toStringAsFixed(2),
        'avgKmPerEuro':
            (totalKmPerEuro / monthRecords.length).toStringAsFixed(2),
        'totalSpent': totalSpent.toStringAsFixed(2),
        'totalKm': totalKm,
      };
    } catch (e) {
      return {
        'count': 0,
        'avgKmPerLiter': 0,
        'avgKmPerEuro': 0,
        'totalSpent': 0,
        'totalKm': 0,
      };
    }
  }

  // Statistiche: consumo medio nell'anno
  static Future<Map<String, dynamic>> getYearlyStats(int year) async {
    try {
      final records = await readRecords();

      final yearRecords =
          records.where((r) => r.dateTime.year == year).toList();

      if (yearRecords.isEmpty) {
        return {
          'count': 0,
          'avgKmPerLiter': 0,
          'avgKmPerEuro': 0,
          'totalSpent': 0,
          'totalKm': 0,
        };
      }

      double totalKmPerLiter = 0;
      double totalKmPerEuro = 0;
      double totalSpent = 0;
      int totalKm = 0;

      for (var record in yearRecords) {
        totalKmPerLiter += record.kmPerLiter;
        totalKmPerEuro += record.kmPerEuro;
        totalSpent += record.amount;
        totalKm += record.km;
      }

      return {
        'count': yearRecords.length,
        'avgKmPerLiter': (totalKmPerLiter / yearRecords.length).toString(),
        'avgKmPerEuro': (totalKmPerEuro / yearRecords.length).toString(),
        'totalSpent': totalSpent.toStringAsFixed(2),
        'totalKm': totalKm,
      };
    } catch (e) {
      return {
        'count': 0,
        'avgKmPerLiter': 0,
        'avgKmPerEuro': 0,
        'totalSpent': 0,
        'totalKm': 0,
      };
    }
  }
}
