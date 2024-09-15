import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistScreen extends StatefulWidget {
  final String roomId;
  const ChecklistScreen({super.key, required this.roomId});

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final Map<String, String> _inspectionResults = {};
  bool _showInspectionItems = false;
  bool _showFinishButton = false;

  final List<String> items = [
    'Inspeção 1',
    'Inspeção 2',
    'Inspeção 3',
  ];

  void _startChecklist() {
    if (_roomNumberController.text.isNotEmpty && _employeeNameController.text.isNotEmpty) {
      setState(() {
        _showInspectionItems = true;
        _updateFinishButtonVisibility();
      });
    } else {
      // Mostra mensagem de erro se campos obrigatórios não forem preenchidos
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('Por favor, preencha todos os campos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _finishChecklist() async {
    String roomId = _roomNumberController.text;

    await FirebaseFirestore.instance.collection('checklists').add({
      'roomNumber': roomId,
      'employeeName': _employeeNameController.text,
      'startTime': DateTime.now().toString(),
      'endTime': DateTime.now().toString(),
      'inspectionResults': _inspectionResults,
    });

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'isOpen': true,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('Quarto $roomId está vago.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(String item) {
    return Row(
      children: [
        Expanded(child: Text(item)),
        _buildInspectionButton(item, 'Sim'),
        _buildInspectionButton(item, 'Não'),
        _buildInspectionButton(item, 'Inexistente'),
      ],
    );
  }

  Widget _buildInspectionButton(String item, String answer) {
    return IconButton(
      onPressed: () {
        setState(() {
          _inspectionResults[item] = answer;
          _updateFinishButtonVisibility();
        });
      },
      icon: Icon(
        Icons.circle,
        color: _inspectionResults[item] == answer ? Colors.blue : Colors.grey,
      ),
    );
  }

  void _updateFinishButtonVisibility() {
    bool allItemsChecked = items.every((item) => _inspectionResults.containsKey(item));
    setState(() {
      _showFinishButton = allItemsChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_showInspectionItems) ...[
              Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(labelText: 'Número do Quarto'),
                      ),
                      TextField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(labelText: 'Nome do Funcionário'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startChecklist,
                        child: const Text('Iniciar Checklist'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView(
                  children: items.map((item) => Card(
                    color: const Color.fromARGB(255, 206, 205, 205),
                    margin: const EdgeInsets.all(10.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildInspectionItem(item),
                    ),
                  )).toList(),
                ),
              ),
              if (_showFinishButton)
                ElevatedButton(
                  onPressed: _finishChecklist,
                  child: const Text('Finalizar Checklist'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
