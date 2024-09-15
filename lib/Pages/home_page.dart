import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_leitos/Pages/report_screen.dart';
import 'checklist.dart'; // Importando a tela de checklist
import 'register_room.dart'; // Importando a tela de cadastro de quartos

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _updateRoomStatus(String roomId, bool isOccupied) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'isOpen': !isOccupied, // Se estiver ocupado, isOpen será falso (vermelho)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Portas'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu de Navegação',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Checklist'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChecklistScreen(roomId: '1')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Registrar Quarto'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RoomRegistrationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: const Text('Relatórios'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum quarto cadastrado'));
          }

          var rooms = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index];
              String roomId = room.id;
              bool isOpen = room['isOpen'];

              return GestureDetector(
                onTap: () {
                  if (isOpen) {
                    // Exibe o AlertDialog apenas se o quarto estiver vago (verde)
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ocupar o Leito?'),
                        content: Text('Quarto $roomId'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Se clicar em Sim, define como ocupado (vermelho)
                              _updateRoomStatus(roomId, true);
                              Navigator.of(context).pop(); // Fecha o dialog
                            },
                            child: const Text('Sim'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Se clicar em Não, mantém como vago (verde)
                              _updateRoomStatus(roomId, false);
                              Navigator.of(context).pop(); // Fecha o dialog
                            },
                            child: const Text('Não'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Exibe uma mensagem informando que o quarto está ocupado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Quarto $roomId já está ocupado.')),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  color: isOpen ? Colors.green : Colors.red,
                  child: Center(child: Text('Quarto $roomId')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
