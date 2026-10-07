class RefuelRecord {
  final DateTime dateTime;
  final int km;
  final String fuelType; // Metano, Benzina, Diesel, SERVICE
  final double price;
  final double amount; // importo pagato
  final String notes;
  final double kmPerLiter;
  final double kmPerEuro;

  RefuelRecord({
    required this.dateTime,
    required this.km,
    required this.fuelType,
    required this.price,
    required this.amount,
    required this.notes,
    required this.kmPerLiter,
    required this.kmPerEuro,
  });

  // Converti in CSV row
  String toCSVRow() {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')},'
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')},'
        '$km,$fuelType,$price,$amount,$notes,${kmPerLiter.toStringAsFixed(2)},${kmPerEuro.toStringAsFixed(2)}';
  }

  // Parsing da CSV
  factory RefuelRecord.fromCSVRow(List<dynamic> row) {
    try {
      final dateParts = row[0].toString().split('-');
      final timeParts = row[1].toString().split(':');
      final dateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      return RefuelRecord(
        dateTime: dateTime,
        km: int.parse(row[2].toString()),
        fuelType: row[3].toString(),
        price: double.parse(row[4].toString()),
        amount: double.parse(row[5].toString()),
        notes: row[6].toString(),
        kmPerLiter: double.tryParse(row[7].toString()) ?? 0,
        kmPerEuro: double.tryParse(row[8].toString()) ?? 0,
      );
    } catch (e) {
      rethrow;
    }
  }
}
