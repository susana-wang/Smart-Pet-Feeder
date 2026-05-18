import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MachineDetailsPage.dart';
import '../services/database_service.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<QuerySnapshot> _machinesStream;

  @override
  void initState() {
    super.initState();
    _machinesStream = _databaseService.getAvailableMachinesStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Top Bar (Coerente com MyAnimalsPage)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: Colors.blue[800],
            child: const Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'As Minhas Máquinas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dono: Utilizador Principal',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _machinesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar máquinas: ${snapshot.error}'),
                    );
                  }

                  final machines = snapshot.data?.docs ?? [];

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: machines.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildAddMachineCard();
                      }

                      final machineDoc = machines[index - 1];
                      final machineData = {
                        'docId': machineDoc.id,
                        ...machineDoc.data() as Map<String, dynamic>
                      };
                      return _buildMachineCard(machineData);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMachineCard() {
    return GestureDetector(
      onTap: () {
        // Lógica para adicionar nova máquina
        _addNewMachine();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[700]!, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 50, color: Colors.blue[700]),
            const SizedBox(height: 10),
            Text(
              'Adicionar\nMáquina',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewMachine() async {
    try {
      // Gera um novo documento no Firebase em 'machines'
      final docRef = FirebaseFirestore.instance.collection('machines').doc();
      await docRef.set({
        'userID': 'user_01',
        'status': 'Online',
        'createdAt': FieldValue.serverTimestamp(),
        'linkedAnimalID': null,
        'linkedAnimalData': null,
        'feedAmount': 0.0,
        'openTimes': 0,
        'feedingSchedule': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máquina adicionada com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar máquina: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildMachineCard(Map<String, dynamic> machine) {
    bool isOnline = machine['status'] == 'Online';
    final machineDocId = machine['docId'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetailsPage(
              machineData: machine,
              ownerName: "Utilizador Principal",
              machineDocId: machineDocId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            )
          ],
        ),
        child: Column(
          children: [
            // Header do Card com Status
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: isOnline ? Colors.green : Colors.red,
                ),
              ),
            ),
            // Ícone da Máquina
            Icon(Icons.settings_remote, size: 60, color: Colors.grey[700]),
            const SizedBox(height: 10),
            // Texto info
            Text(
              'Máquina #${machineDocId.substring(0, 6)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green[900] : Colors.red[900],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            // Rodapé do card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text(
                  'Ver Detalhes',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}