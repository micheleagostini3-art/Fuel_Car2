import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refuel_record.dart';
import '../services/csv_service.dart';
import 'add_refuel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<RefuelRecord>> _records;
  late Future<Map<String, dynamic>> _monthlyStats;
  late Future<Map<String, dynamic>> _yearlyStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _records = CSVService.readRecords();
      final now = DateTime.now();
      _monthlyStats = CSVService.getMonthlyStats(now);
      _yearlyStats = CSVService.getYearlyStats(now.year);
    });
  }

  Future<void> _refreshData() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚗 Fuel Car Tracker'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Statistiche
              _buildStatsSection(),

              // Lista rifornimenti
              _buildRecordsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRefuelScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Rifornimento'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTICHE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 12),

          // Stats Mese
          FutureBuilder<Map<String, dynamic>>(
            future: _monthlyStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData) {
                return const Text('Errore caricamento statistiche');
              }

              final stats = snapshot.data!;
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Color(0xFF1E88E5)),
                          const SizedBox(width: 8),
                          Text(
                            'QUESTO MESE',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Rifornimenti',
                            stats['count'].toString(),
                            Icons.local_gas_station,
                          ),
                          _buildStatCard(
                            'KM/L',
                            stats['avgKmPerLiter'].toString(),
                            Icons.speed,
                          ),
                          _buildStatCard(
                            'KM/€',
                            stats['avgKmPerEuro'].toString(),
                            Icons.euro,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Speso',
                            '${stats['totalSpent']}€',
                            Icons.payment,
                          ),
                          _buildStatCard(
                            'KM Fatti',
                            stats['totalKm'].toString(),
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Stats Anno
          FutureBuilder<Map<String, dynamic>>(
            future: _yearlyStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData) {
                return const Text('Errore caricamento statistiche annuali');
              }

              final stats = snapshot.data!;
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF1E88E5)),
                          const SizedBox(width: 8),
                          Text(
                            'QUESTO ANNO',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Rifornimenti',
                            stats['count'].toString(),
                            Icons.local_gas_station,
                          ),
                          _buildStatCard(
                            'KM/L',
                            stats['avgKmPerLiter'].toString(),
                            Icons.speed,
                          ),
                          _buildStatCard(
                            'KM/€',
                            stats['avgKmPerEuro'].toString(),
                            Icons.euro,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Speso',
                            '${stats['totalSpent']}€',
                            Icons.payment,
                          ),
                          _buildStatCard(
                            'KM Fatti',
                            stats['totalKm'].toString(),
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STORICO RIFORNIMENTI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<RefuelRecord>>(
            future: _records,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.local_gas_station,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Nessun rifornimento registrato',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Premi il pulsante + per aggiungere il primo rifornimento',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final records = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _buildRecordCard(record);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(RefuelRecord record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color fuelColor = Colors.grey;
    IconData fuelIcon = Icons.local_gas_station;

    switch (record.fuelType) {
      case 'Metano':
        fuelColor = Colors.purple;
        fuelIcon = Icons.cloud;
        break;
      case 'Benzina':
        fuelColor = Colors.orange;
        fuelIcon = Icons.fire_truck;
        break;
      case 'Diesel':
        fuelColor = Colors.blue;
        fuelIcon = Icons.local_gas_station;
        break;
      case 'SERVICE':
        fuelColor = Colors.red;
        fuelIcon = Icons.build;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Intestazione con data e tipo carburante
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(record.dateTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(fuelIcon, size: 16, color: fuelColor),
                        const SizedBox(width: 4),
                        Text(
                          record.fuelType,
                          style: TextStyle(
                            color: fuelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${record.km} KM',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.amount.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Metriche
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      'KM/L',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      record.kmPerLiter.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'KM/€',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      record.kmPerEuro.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Prezzo/L',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${record.price.toStringAsFixed(3)}€',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Note se presenti
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Note: ${record.notes}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
