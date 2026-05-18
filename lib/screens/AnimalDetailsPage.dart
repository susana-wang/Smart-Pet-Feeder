import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/database_service.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Map<String, dynamic> animal;
  final String? petId;

  const AnimalDetailsPage({
    super.key,
    required this.animal,
    this.petId,
  });

  @override
  State<AnimalDetailsPage> createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  late bool isEditing;
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController breedController;
  late TextEditingController feedAmountController;
  File? selectedImage;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    isEditing = false;
    nameController = TextEditingController(text: widget.animal['name'] ?? '');
    ageController = TextEditingController(text: '${widget.animal['age'] ?? 0}');
    breedController = TextEditingController(text: widget.animal['breed'] ?? '');
    feedAmountController = TextEditingController(text: '${widget.animal['feedAmount'] ?? 0.0}');

    // Initialize selectedImage if it exists
    if (widget.animal['image'] != null) {
      final File imageFile = File(widget.animal['image']);
      if (imageFile.existsSync()) {
        selectedImage = imageFile;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    breedController.dispose();
    feedAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,

    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        widget.animal['image'] = selectedImage?.path;
      });
    }
  }

   void _toggleEditMode() async {
     if (isEditing) {
       // Save changes
       try {
         if (widget.petId != null) {
           // Save to Firestore
           await _databaseService.updatePet(
             petId: widget.petId!,
             name: nameController.text.trim(),
             age: int.tryParse(ageController.text) ?? widget.animal['age'],
             breed: breedController.text.trim(),
             feedAmount: double.tryParse(feedAmountController.text) ?? widget.animal['feedAmount'],
           );

           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Animal updated successfully!'),
                 backgroundColor: Colors.green,
                 duration: Duration(seconds: 2),
               ),
             );
           }
         }

         // Update local state
         widget.animal['name'] = nameController.text;
         widget.animal['age'] = int.tryParse(ageController.text) ?? widget.animal['age'];
         widget.animal['breed'] = breedController.text;
         widget.animal['feedAmount'] = double.tryParse(feedAmountController.text) ?? widget.animal['feedAmount'];

         setState(() {
           isEditing = !isEditing;
         });
       } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Error: $e'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 2),
             ),
           );
         }
       }
     } else {
       setState(() {
         isEditing = !isEditing;
       });
      }
    }

    void _showAddMachineDialog() {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select a Machine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _databaseService.getAvailableMachinesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final machines = snapshot.data?.docs ?? [];

                        if (machines.isEmpty) {
                          return const Center(
                            child: Text('No machines yet'),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: machines.length,
                          itemBuilder: (context, index) {
                            final machineData = machines[index].data() as Map<String, dynamic>;
                            final machineName = machineData['name'] ?? 'Unknown';
                            final machineType = machineData['type'] ?? 'No type';

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    if (widget.petId != null) {
                                      await _databaseService.addMachine(
                                        petId: widget.petId!,
                                        machineName: machineName,
                                        machineType: machineType,
                                      );

                                      if (mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Machine added successfully!'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.devices,
                                          size: 32,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          machineName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          machineType,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue[700]!),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           // Custom Top Bar
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 16),
             color: Colors.blue[700],
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.animal['name'] ?? 'Animal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      // Show delete confirmation dialog
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete Animal'),
                          content: Text('Are you sure you want to delete ${widget.animal['name']}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  if (widget.petId != null) {
                                    await _databaseService.deletePet(widget.petId!);
                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Animal deleted successfully!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _selectImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                ),
                                child: selectedImage != null && selectedImage!.existsSync()
                                    ? ClipOval(
                                        child: Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.pets,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.animal['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.animal['breed'] ?? 'No breed'} • ${widget.animal['age'] ?? 0} years',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Details:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _toggleEditMode,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      isEditing ? 'Save' : 'Edit',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!isEditing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Age', '${widget.animal['age'] ?? 0} years'),
                                const SizedBox(height: 12),
                                _buildDetailRow('Breed', widget.animal['breed'] ?? 'Not specified'),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Feed Amount',
                                  '${widget.animal['feedAmount'] ?? 0.0} kg/day',
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEditableField('Age', ageController),
                                const SizedBox(height: 12),
                                _buildEditableField('Breed', breedController),
                                const SizedBox(height: 12),
                                _buildEditableField('Feed Amount (kg/day)', feedAmountController),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                     // Machines Section
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade50,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.shade200),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text(
                                 'Machines:',
                                 style: TextStyle(
                                   fontSize: 18,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               MouseRegion(
                                 cursor: SystemMouseCursors.click,
                                 child: GestureDetector(
                                   onTap: () => _showAddMachineDialog(),
                                   child: Container(
                                     decoration: BoxDecoration(
                                       color: Colors.blue[700],
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 12,
                                       vertical: 6,
                                     ),
                                     child: const Text(
                                       'Add',
                                       style: TextStyle(
                                         color: Colors.white,
                                         fontSize: 12,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 12),
                           if (widget.petId != null)
                             StreamBuilder<QuerySnapshot>(
                               stream: _databaseService.getMachinesStream(widget.petId!),
                               builder: (context, snapshot) {
                                 if (snapshot.connectionState == ConnectionState.waiting) {
                                   return const Center(
                                     child: Padding(
                                       padding: EdgeInsets.all(16.0),
                                       child: CircularProgressIndicator(),
                                     ),
                                   );
                                 }

                                 if (snapshot.hasError) {
                                   return Center(
                                     child: Padding(
                                       padding: const EdgeInsets.all(16.0),
                                       child: Text('Error: ${snapshot.error}'),
                                     ),
                                   );
                                 }

                                 final machines = snapshot.data?.docs ?? [];

                                 if (machines.isEmpty) {
                                   return Center(
                                     child: Padding(
                                       padding: const EdgeInsets.all(16.0),
                                       child: Text(
                                         'No machines yet',
                                         style: TextStyle(
                                           color: Colors.grey.shade600,
                                           fontSize: 14,
                                         ),
                                       ),
                                     ),
                                   );
                                 }

                                 return Column(
                                   children: machines.map((machineDoc) {
                                     final machineData = machineDoc.data() as Map<String, dynamic>;
                                     final machineId = machineDoc.id;

                                     return Container(
                                       margin: const EdgeInsets.only(bottom: 8),
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(
                                         color: Colors.white,
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.grey.shade200),
                                       ),
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Expanded(
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   machineData['name'] ?? 'Unknown',
                                                   style: const TextStyle(
                                                     fontWeight: FontWeight.bold,
                                                     fontSize: 14,
                                                   ),
                                                 ),
                                                 const SizedBox(height: 4),
                                                 Text(
                                                   machineData['type'] ?? 'No type',
                                                   style: TextStyle(
                                                     color: Colors.grey.shade600,
                                                     fontSize: 12,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                           MouseRegion(
                                             cursor: SystemMouseCursors.click,
                                             child: GestureDetector(
                                               onTap: () {
                                                 // Delete machine
                                                 showDialog(
                                                   context: context,
                                                   builder: (dialogContext) => AlertDialog(
                                                     title: const Text('Delete Machine'),
                                                     content: Text('Are you sure you want to delete ${machineData['name']}?'),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(dialogContext),
                                                         child: const Text('Cancel'),
                                                       ),
                                                       TextButton(
                                                         onPressed: () async {
                                                           try {
                                                             await _databaseService.deleteMachine(widget.petId!, machineId);
                                                             if (mounted) {
                                                               Navigator.pop(dialogContext);
                                                               ScaffoldMessenger.of(context).showSnackBar(
                                                                 const SnackBar(
                                                                   content: Text('Machine deleted successfully!'),
                                                                   backgroundColor: Colors.green,
                                                                   duration: Duration(seconds: 2),
                                                                 ),
                                                               );
                                                             }
                                                           } catch (e) {
                                                             if (mounted) {
                                                               Navigator.pop(dialogContext);
                                                               ScaffoldMessenger.of(context).showSnackBar(
                                                                 SnackBar(
                                                                   content: Text('Error: $e'),
                                                                   backgroundColor: Colors.red,
                                                                   duration: const Duration(seconds: 2),
                                                                 ),
                                                               );
                                                             }
                                                           }
                                                         },
                                                         child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                               },
                                               child: Container(
                                                 padding: const EdgeInsets.all(6),
                                                 decoration: BoxDecoration(
                                                   color: Colors.red.withOpacity(0.1),
                                                   borderRadius: BorderRadius.circular(6),
                                                 ),
                                                 child: const Icon(
                                                   Icons.delete,
                                                   color: Colors.red,
                                                   size: 18,
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ],
                                       ),
                                     );
                                   }).toList(),
                                 );
                               },
                             )
                           else
                             Center(
                               child: Text(
                                 'No machines yet',
                                 style: TextStyle(
                                   color: Colors.grey.shade600,
                                   fontSize: 14,
                                 ),
                               ),
                             ),
                         ],
                       ),
                     ),
                    const SizedBox(height: 24),

                    // Meals Report Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meals Report:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMealsReportContent(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: label.contains('Age') || label.contains('Feed') ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsReportContent() {
    List<Map<String, dynamic>> meals = [];

    if (meals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Empty',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: meals.map((meal) {
        final date = meal['date'] ?? 'N/A';
        final amount = meal['amount'] ?? 0.0;
        final difference = meal['difference'] ?? 0.0;
        final isDifferencePositive = difference >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '$amount kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${isDifferencePositive ? '+' : ''}$difference kg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDifferencePositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealsReportSection() {
    List<Map<String, dynamic>> meals = [];

    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Empty',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: meals.map((meal) {
        final date = meal['date'] ?? 'N/A';
        final amount = meal['amount'] ?? 0.0;
        final difference = meal['difference'] ?? 0.0;
        final isDifferencePositive = difference >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '$amount kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${isDifferencePositive ? '+' : ''}$difference kg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDifferencePositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

