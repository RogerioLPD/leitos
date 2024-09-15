import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _roomNumberController = TextEditingController();
  List<Map<String, dynamic>> _reportDataList = [];

  Future<void> _fetchReport() async {
    String roomId = _roomNumberController.text;
    var querySnapshot = await FirebaseFirestore.instance
        .collection('checklists')
        .where('roomNumber', isEqualTo: roomId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var dataList = querySnapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        _reportDataList = dataList;
      });
    } else {
      setState(() {
        _reportDataList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum relatório encontrado para o quarto $roomId.')),
      );
    }
  }

  String _calculateDuration(String startTime, String endTime) {
    DateTime start = DateTime.parse(startTime);
    DateTime end = DateTime.parse(endTime);
    Duration duration = end.difference(start);

    return '${duration.inHours} horas, ${duration.inMinutes.remainder(60)} minutos';
  }

  String _formatDateTime(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Checklist'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              shadowColor: Colors.deepPurple.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Buscar Relatório de Quarto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomNumberController,
                      decoration: InputDecoration(
                        labelText: 'Número do Quarto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.room, color: Colors.deepPurple),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchReport,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text('Buscar Relatório'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Exibição dos relatórios
            _reportDataList.isNotEmpty
                ? Column(
                    children: _reportDataList.map((reportData) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.deepPurple.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalhes do Relatório',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                leading: Icon(Icons.person, color: Colors.deepPurple),
                                title: Text(
                                  'Funcionário',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(reportData['employeeName']),
                              ),
                              ListTile(
                                leading: Icon(Icons.timer, color: Colors.green),
                                title: Text(
                                  'Início do Checklist',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(_formatDateTime(reportData['startTime'])),
                              ),
                              ListTile(
                                leading: Icon(Icons.timer_off, color: Colors.red),
                                title: Text(
                                  'Término do Checklist',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(_formatDateTime(reportData['endTime'])),
                              ),
                              ListTile(
                                leading: Icon(Icons.access_time_filled, color: Colors.orange),
                                title: Text(
                                  'Tempo Gasto',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  _calculateDuration(
                                      reportData['startTime'], reportData['endTime']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: const Text(
                      'Nenhum relatório disponível.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
