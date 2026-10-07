import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refuel_record.dart';
import '../services/csv_service.dart';

class AddRefuelScreen extends StatefulWidget {
  const AddRefuelScreen({Key? key}) : super(key: key);

  @override
  State<AddRefuelScreen> createState() => _AddRefuelScreenState();
}

class _AddRefuelScreenState extends State<AddRefuelScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _fuelType = 'Benzina';
  String? _lastFuelType;

  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastFuelType();
  }

  Future<void> _loadLastFuelType() async {
    final lastType = await CSVService.getLastFuelType();
    setState(() {
      _lastFuelType = lastType;
      if (_lastFuelType != null && _lastFuelType != 'SERVICE') {
        _fuelType = _lastFuelType!;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final km = int.parse(_kmController.text);
    final liters = double.parse(_litersController.text);
    final price = double.parse(_priceController.text);
    final amount = double.parse(_amountController.text);
    final notes = _notesController.text;

    // Calcola metriche
    final metrics = await CSVService.calculateMetrics(km, liters, amount);

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final record = RefuelRecord(
      dateTime: dateTime,
      km: km,
      fuelType: _fuelType,
      price: price,
      amount: amount,
      notes: notes,
      kmPerLiter: metrics['kmPerLiter'] ?? 0,
      kmPerEuro: metrics['kmPerEuro'] ?? 0,
    );

    try {
      await CSVService.addRecord(record);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rifornimento salvato con successo! ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Rifornimento'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Ora
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Ora'),
                    subtitle: Text(_selectedTime.format(context)),
                    onTap: () => _selectTime(context),
                  ),
                ),
                const SizedBox(height: 12),

                // KM
                TextFormField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'KM Odometro',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obbligatorio';
                    if (int.tryParse(value!) == null)
                      return 'Inserire un numero';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Tipo Carburante
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<String>(
                      value: _fuelType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Metano', 'Benzina', 'Diesel', 'SERVICE']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _fuelType = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Litri
                TextFormField(
                  controller: _litersController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Litri',
                    prefixIcon: const Icon(Icons.local_gas_station),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obbligatorio';
                    if (double.tryParse(value!) == null)
                      return 'Inserire un numero';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Prezzo al litro
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prezzo al litro (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obbligatorio';
                    if (double.tryParse(value!) == null)
                      return 'Inserire un numero';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Importo pagato
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo pagato (€)',
                    prefixIcon: const Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo obbligatorio';
                    if (double.tryParse(value!) == null)
                      return 'Inserire un numero';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Note
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pulsante Salva
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.save),
                    label: const Text('SALVA RIFORNIMENTO'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _litersController.dispose();
    super.dispose();
  }
}
