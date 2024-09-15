import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomRegistrationScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNumberController = TextEditingController();

  RoomRegistrationScreen({super.key});

  void _registerRoom() async {
    String roomNumber = _roomNumberController.text;
    if (roomNumber.isNotEmpty) {
      await FirebaseFirestore.instance.collection('rooms').doc(roomNumber).set({
        'isOpen': false,
      });
      _roomNumberController.clear();
      ScaffoldMessenger.of(_formKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Quarto $roomNumber cadastrado com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Quartos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _roomNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número do Quarto'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerRoom,
                child: const Text('Cadastrar Quarto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
