import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class MachineDetailsPage extends StatefulWidget {
  final Map<String, dynamic> machineData;
  final String ownerName;
  final String machineDocId;

  const MachineDetailsPage({
    super.key,
    required this.machineData,
    required this.ownerName,
    required this.machineDocId,
  });

  @override
  State<MachineDetailsPage> createState() => _MachineDetailsPageState();
}

class _MachineDetailsPageState extends State<MachineDetailsPage> {
  late bool isEditing;

  // Controladores para o que é editável (Animal e Configurações)
  late TextEditingController animalNameController;
  late TextEditingController breedController;
  late TextEditingController feedAmountController;
  late TextEditingController openTimesController;

  File? selectedImage;
  // Simulated list of animals (read-only here to avoid changing animal pages)
  final List<Map<String, dynamic>> availableAnimals = [
    {
      'name': 'Max',
      'age': 3,
      'breed': 'Golden Retriever',
      'feedAmount': 2.5,
      'image': null,
    },
    {
      'name': 'Luna',
      'age': 2,
      'breed': 'Siamese Cat',
      'feedAmount': 1.0,
      'image': null,
    },
    {
      'name': 'Bella',
      'age': 4,
      'breed': 'Beagle',
      'feedAmount': 1.8,
      'image': null,
    },
  ];

  Map<String, dynamic>? linkedAnimal;
  List<TimeOfDay> feedingTimes = [];
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    isEditing = false;

    // O ID da máquina e o Utilizador são apenas leitura, por isso não precisam de controllers
    animalNameController = TextEditingController(text: widget.machineData['animalName'] ?? '');
    breedController = TextEditingController(text: widget.machineData['breed'] ?? '');
    feedAmountController = TextEditingController(text: widget.machineData['feedAmount']?.toString() ?? '0.0');

    // Se não houver vezes definidas, o padrão é 3 (Manhã, Almoço, Jantar)
    openTimesController = TextEditingController(
        text: (widget.machineData['openTimes'] ?? 3).toString()
    );

    if (widget.machineData['image'] != null) {
      selectedImage = File(widget.machineData['image']);
    }

    // load linked animal if exists
    if (widget.machineData['linkedAnimal'] != null) {
      linkedAnimal = Map<String, dynamic>.from(widget.machineData['linkedAnimal']);
    }
    // If there's a linked animal, populate the controllers with its data
    if (linkedAnimal != null) {
      animalNameController.text = linkedAnimal!['name'] ?? animalNameController.text;
      breedController.text = linkedAnimal!['breed'] ?? breedController.text;
      feedAmountController.text = (linkedAnimal!['feedAmount'] != null) ? linkedAnimal!['feedAmount'].toString() : feedAmountController.text;
    }

    // Initialize feedingTimes from machineData if present, otherwise use defaults based on openTimes
    if (widget.machineData['feedingSchedule'] != null) {
      try {
        final List<dynamic> list = widget.machineData['feedingSchedule'];
        feedingTimes = list.map((e) {
          if (e is String && e.contains(':')) {
            final parts = e.split(':');
            return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          return TimeOfDay(hour: 8, minute: 0);
        }).toList();
      } catch (_) {
        feedingTimes = [];
      }
    }
    if (feedingTimes.isEmpty) {
      final int defaultTimes = widget.machineData['openTimes'] ?? 3;
      // simple defaults
      final now = DateTime.now();
      feedingTimes = List.generate(defaultTimes, (i) {
        final hour = [8, 13, 19][i % 3];
        return TimeOfDay(hour: hour, minute: 0);
      });
    }
  }

  @override
  void dispose() {
    animalNameController.dispose();
    breedController.dispose();
    feedAmountController.dispose();
    openTimesController.dispose();
    super.dispose();
  }

  Future<void> _toggleEditMode() async {
    // Toggle edit/save. If saving and an animal is linked, warn the user that
    // this will affect the animal page (which is not currently synchronized).
    if (isEditing) {
      // We're about to save
      final newFeed = double.tryParse(feedAmountController.text) ?? 0.0;
      final newOpenTimes = int.tryParse(openTimesController.text) ?? 3;

      if (linkedAnimal != null) {
        // Show a confirmation warning explaining that animal pages aren't linked
        final apply = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirmar alteração'),
              content: const Text(
                  'Esta alteração alterará também os dados do animal vinculado noutra página. \n\nNo entanto, as páginas de animais não estão sincronizadas automaticamente.\nDeseja aplicar as alterações apenas à máquina (recomendado) e não alterar o ficheiro de animais)?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Aplicar à máquina'),
                ),
              ],
            );
          },
        );

        if (apply != true) {
          // User cancelled saving
          return;
        }
      }

      // Save into machineData (and into linkedAnimal object inside machineData)
      setState(() {
        widget.machineData['animalName'] = animalNameController.text;
        widget.machineData['breed'] = breedController.text;
        widget.machineData['feedAmount'] = newFeed;
        widget.machineData['openTimes'] = newOpenTimes;

        if (linkedAnimal != null) {
          // Update the linkedAnimal object stored in machineData (local only)
          linkedAnimal!['name'] = animalNameController.text;
          linkedAnimal!['breed'] = breedController.text;
          linkedAnimal!['feedAmount'] = newFeed;
          widget.machineData['linkedAnimal'] = linkedAnimal;
        }
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alterações guardadas na máquina')));
    } else {
      // Enter edit mode
      setState(() {
        isEditing = true;
      });
    }
  }

  void _showLinkDialog() async {
    // Show dialog with list of available animals to link
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 360,
            height: 420,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Select an animal to link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: availableAnimals.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = availableAnimals[index];
                      return ListTile(
                        leading: a['image'] != null && File(a['image']).existsSync()
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(a['image']), width: 48, height: 48, fit: BoxFit.cover))
                            : Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey), child: Icon(Icons.pets, color: Colors.white)),
                        title: Text(a['name']),
                        subtitle: Text('${a['breed']} • ${a['age']}y'),
                        onTap: () {
                          Navigator.of(context).pop(a);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        linkedAnimal = Map<String, dynamic>.from(selected);
        widget.machineData['linkedAnimal'] = linkedAnimal;
        // Update controllers to reflect the linked animal data
        animalNameController.text = linkedAnimal!['name'] ?? animalNameController.text;
        breedController.text = linkedAnimal!['breed'] ?? breedController.text;
        feedAmountController.text = (linkedAnimal!['feedAmount'] != null) ? linkedAnimal!['feedAmount'].toString() : feedAmountController.text;
      });

      _saveToFirebase();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Máquina vinculada a ${selected['name']}')));
    }
  }

  void _unlinkAnimal() {
    setState(() {
      linkedAnimal = null;
      widget.machineData.remove('linkedAnimal');
      // Restore controllers to machine-stored values (or empty)
      animalNameController.text = widget.machineData['animalName'] ?? '';
      breedController.text = widget.machineData['breed'] ?? '';
      feedAmountController.text = widget.machineData['feedAmount']?.toString() ?? '0.0';
    });
    _saveToFirebase();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máquina desvinculada')));
  }

  Future<void> _saveToFirebase() async {
    try {
      await _firestore.collection('machines').doc(widget.machineDocId).update({
        'linkedAnimalID': linkedAnimal?['id'],
        'linkedAnimalData': linkedAnimal,
        'feedAmount': double.tryParse(feedAmountController.text) ?? 0.0,
        'openTimes': feedingTimes.length,
        'feedingSchedule': feedingTimes.map((t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}').toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar: $e')),
        );
      }
    }
  }

  Future<void> _showEditFeedingDialog() async {
    final feedController = TextEditingController(text: feedAmountController.text);
    List<TimeOfDay> tempTimes = List.from(feedingTimes);

    Future<void> pickTime(int? index) async {
      final initial = index != null ? tempTimes[index] : TimeOfDay.now();
      final t = await showTimePicker(context: context, initialTime: initial);
      if (t != null) {
        if (index != null) tempTimes[index] = t; else tempTimes.add(t);
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: 360,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Editar Alimentação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: feedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantidade de Ração (kg/dia)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Horários'),
                        TextButton(
                          onPressed: () async {
                            await pickTime(null);
                            setDialogState(() {});
                          },
                          child: const Text('+ Adicionar horário'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: tempTimes.isEmpty
                          ? const Center(child: Text('Nenhum horário definido'))
                          : ListView.builder(
                              itemCount: tempTimes.length,
                              itemBuilder: (context, i) {
                                final t = tempTimes[i];
                                return ListTile(
                                  title: Text(t.format(context)),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await pickTime(i);
                                        setDialogState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        tempTimes.removeAt(i);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ]),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // validation
                            final f = double.tryParse(feedController.text) ?? -1;
                            if (f <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantidade inválida')));
                              return;
                            }
                            // commit tempTimes and feed
                            setState(() {
                              feedAmountController.text = feedController.text;
                              feedingTimes = List.from(tempTimes);
                            });
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (saved == true) {
      // If linkedAnimal exists, confirm that user understands it affects animal page
      if (linkedAnimal != null) {
        final apply = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirmar alteração'),
              content: const Text('Alterar a quantidade ou horários irá também alterar os dados do animal vinculado n\'outro lado. Deseja aplicar apenas à máquina?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Aplicar à máquina')),
              ],
            );
          },
        );

        if (apply != true) {
          // user cancelled final confirmation -> do not persist to machineData
          return;
        }
      }

      // persist to machineData
      widget.machineData['feedAmount'] = double.tryParse(feedAmountController.text) ?? 0.0;
      widget.machineData['openTimes'] = feedingTimes.length;
      widget.machineData['feedingSchedule'] = feedingTimes.map((t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}').toList();

      // also update linkedAnimal stored locally
      if (linkedAnimal != null) {
        linkedAnimal!['feedAmount'] = widget.machineData['feedAmount'];
        widget.machineData['linkedAnimal'] = linkedAnimal;
      }

      _saveToFirebase();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuração de alimentação atualizada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Máquina #${widget.machineData['machineID']}"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),
            _buildSectionTitle("Informação do Animal"),
            _buildAnimalCard(),
            const SizedBox(height: 20),
            _buildSectionTitle("Configuração de Alimentação"),
            _buildFeedingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_remote, color: Colors.blue, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID da Máquina: ${widget.machineData['machineID']}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Dono: ${widget.ownerName}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Nome do Animal", animalNameController, !isEditing),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            // Linked animal status and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: linkedAnimal != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vinculado a: ${linkedAnimal!['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${linkedAnimal!['breed']} • ${linkedAnimal!['age']} anos', style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      : const Text('Nenhum animal vinculado', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                linkedAnimal != null
                    ? TextButton(
                        onPressed: _unlinkAnimal,
                        child: const Text('Desvincular'),
                      )
                    : ElevatedButton(
                        onPressed: _showLinkDialog,
                        child: const Text('Vincular'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row with edit button for feeding settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alimentação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showEditFeedingDialog,
                      tooltip: 'Editar alimentação',
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildField("Quantidade de Ração (kg/dia)", feedAmountController, !isEditing, isNumeric: true),
            const SizedBox(height: 10),
            // show feeding times as chips
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: feedingTimes.map((t) => Chip(label: Text(t.format(context)))).toList(),
              ),
            ),
            const SizedBox(height: 10),
            _buildField("Vezes por dia (Default: 3)", openTimesController, !isEditing, isNumeric: true),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool readOnly, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      enabled: !readOnly,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: readOnly ? InputBorder.none : const OutlineInputBorder(),
        filled: !readOnly,
        fillColor: Colors.grey[100],
      ),
      style: TextStyle(
        fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
        color: readOnly ? Colors.black87 : Colors.blue[900],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }
}