import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChecklistScreen extends StatefulWidget {
  final String roomId;
  const ChecklistScreen({super.key, required this.roomId});

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final Map<String, Map<String, dynamic>> _inspectionResults = {};
  bool _showFinishButton = false;
  bool _checklistStarted = false;
  bool _checklistFinished =
      false; // Flag to indicate if the checklist is finished
  int _currentInspectionIndex = 0; // Começa no primeiro item
  File? _image;
  DateTime? _startTime; // Variable to store start time
  DateTime? _endTime; // Variable to store end time

  final List<Map<String, String>> items = [
    {
      'title': 'Tetos e luminárias',
      'description': 'Estão todos limpos, higienizados e sem avarias?'
    },
    {
      'title': 'Janelas',
      'description': 'Estão todas limpas, higienizadas e sem avarias?'
    },
    {
      'title': 'Armários',
      'description': 'Estão limpos, higienizados e sem avarias?'
    },
    {'title': 'Piso', 'description': 'Está limpo, higienizado e sem avarias?'},
  ];

  // Função para iniciar o checklist
  void _startChecklist() {
    if (_roomNumberController.text.isNotEmpty &&
        _employeeNameController.text.isNotEmpty) {
      setState(() {
        _checklistStarted = true; // Define que o checklist foi iniciado
        _currentInspectionIndex = 0; // Começa no primeiro item
        _showFinishButton =
            false; // Garante que o botão de finalizar só será exibido no fim
        _startTime = DateTime.now(); // Marca o horário de início
      });
    } else {
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

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);

      // Aguarde a conclusão do upload
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Erro ao fazer upload da imagem: $e");
      return null;
    }
  }

  Future<void> _submitComment(String item) async {
    Navigator.pop(context);
    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImage(_image!);
    }
    setState(() {
      _inspectionResults[item] = {
        'status': 'Não',
        'comment': _commentController.text,
        'imageUrl': imageUrl ?? ''
      };
      _commentController.clear();
      _image = null;
      _nextInspection();
    });
  }

  void _nextInspection() {
    setState(() {
      if (_currentInspectionIndex < items.length - 1) {
        _currentInspectionIndex++; // Avança para o próximo item
      } else {
        _showFinishButton =
            true; // Se for o último item, exibe o botão de finalizar
      }
    });
  }

  void _showCommentDialog(String item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comentário e Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Comentário'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getImage,
              child: const Text('Tirar Foto'),
            ),
            if (_image != null) Image.file(_image!, height: 100),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _commentController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _submitComment(item),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(Map<String, String> item) {
    return Card(
      color: const Color.fromARGB(255, 245, 245, 245),
      margin: const EdgeInsets.all(10.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title']!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(item['description']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _inspectionResults[item['title']!] = {'status': 'Sim'};
                      _nextInspection();
                    });
                  },
                  child: const Text('Sim'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _showCommentDialog(item['title']!),
                  child: const Text('Não'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishChecklist() async {
    String roomId = _roomNumberController.text;
    setState(() {
      _endTime = DateTime.now(); // Marca o horário de fim
      _checklistFinished = true; // Define que o checklist foi finalizado
    });

    await FirebaseFirestore.instance.collection('checklists').add({
      'roomNumber': roomId,
      'employeeName': _employeeNameController.text,
      'startTime': _startTime?.toString(), // Usa a data e hora de início
      'endTime': _endTime?.toString(), // Usa a data e hora de fim
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_checklistStarted) ...[
              // Exibe a tela inicial de preenchimento
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
                        decoration: const InputDecoration(
                            labelText: 'Número do Quarto'),
                      ),
                      TextField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(
                            labelText: 'Nome do Funcionário'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            _startChecklist, // Chama a função para iniciar o checklist
                        child: const Text('Iniciar Checklist'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!_checklistFinished) ...[
              // Exibe o checklist após o início
              Expanded(
                child: _buildInspectionItem(items[_currentInspectionIndex]),
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
