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
  String? _startTime;
  String? _endTime;
  final Map<String, String> _inspectionResults = {};

  List<ItemChecklist> items = [
    ItemChecklist('Inspeção 1', 'Descrição da Inspeção 1'),
    ItemChecklist('Inspeção 2', 'Descrição da Inspeção 2'),
    ItemChecklist('Inspeção 3', 'Descrição da Inspeção 3'),
  ];

  void _startChecklist() {
    setState(() {
      _startTime = DateTime.now().toString();
    });
  }

  void _finishChecklist() async {
    setState(() {
      _endTime = DateTime.now().toString();
    });

    String roomId = widget.roomId;

    await FirebaseFirestore.instance.collection('checklists').add({
      'roomNumber': roomId,
      'employeeName': _employeeNameController.text,
      'startTime': _startTime,
      'endTime': _endTime,
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

  Widget _buildInspectionItem(ItemChecklist item) {
    return Row(
      children: [
        Text(item.title),
        const Spacer(),
        _buildInspectionButton(item, 'Conforme'),
        _buildInspectionButton(item, 'Não Conforme'),
        _buildInspectionButton(item, 'Inexistente'),
      ],
    );
  }

  Widget _buildInspectionButton(ItemChecklist item, String answer) {
    return IconButton(
      onPressed: () {
        setState(() {
          _inspectionResults[item.title] = answer;
        });
      },
      icon: Icon(
        Icons.circle,
        color: _inspectionResults[item.title] == answer ? Colors.blue : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            ...items.map((item) => _buildInspectionItem(item)).toList(),
            const Spacer(),
            ElevatedButton(
              onPressed: _startChecklist,
              child: const Text('Iniciar Checklist'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _finishChecklist,
              child: const Text('Finalizar Checklist'),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemChecklist {
  String title;
  String description;

  ItemChecklist(this.title, this.description);
}
