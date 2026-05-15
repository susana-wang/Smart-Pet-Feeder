import 'package:flutter/material.dart';
import 'dart:io';
import 'MachineDetailsPage.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  // Simulação de dados vindos da sua classe Machine
  // Na vida real, isto viria de uma base de dados ou Provider
  List<Map<String, dynamic>> machines = [
    {
      'machineID': 101,
      'userID': 'user_01',
      'status': 'Online',
    },
    {
      'machineID': 102,
      'userID': 'user_01',
      'status': 'Offline',
    },
  ];

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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: machines.length + 1,
                itemBuilder: (context, index) {
                  // Card para Adicionar/Vincular nova Máquina
                  if (index == 0) {
                    return _buildAddMachineCard();
                  }

                  final machine = machines[index - 1];
                  return _buildMachineCard(machine);
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

  void _addNewMachine() {
    // Gera um novo ID de máquina
    int newMachineID = (machines.map((m) => m['machineID'] as int).fold<int>(0, (a, b) => a > b ? a : b)) + 1;

    setState(() {
      machines.add({
        'machineID': newMachineID,
        'userID': 'user_01',
        'status': 'Online',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Máquina #$newMachineID adicionada com sucesso!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> machine) {
    bool isOnline = machine['status'] == 'Online';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetailsPage(machineData: machine, ownerName: "Utilizador Principal"),
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
              'Máquina #${machine['machineID']}',
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