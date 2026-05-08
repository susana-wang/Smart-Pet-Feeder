import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'AnimalDetailsPage.dart' show AnimalDetailsPage;

class MyAnimalsPage extends StatefulWidget {
  const MyAnimalsPage({super.key});

  @override
  State<MyAnimalsPage> createState() => _MyAnimalsPageState();
}

class _MyAnimalsPageState extends State<MyAnimalsPage> {
  List<Map<String, dynamic>> animals = [
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
  ];

  void _showAddEditModal({Map<String, dynamic>? animal, int? index}) {
    final nameController = TextEditingController(text: animal?['name'] ?? '');
    final ageController = TextEditingController(text: animal?['age'].toString() ?? '');
    final breedController = TextEditingController(text: animal?['breed'] ?? '');
    final feedAmountController = TextEditingController(text: animal?['feedAmount'].toString() ?? '');

    File? selectedImage = animal?['image'] != null ? File(animal!['image']) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        animal == null ? 'Add Animal' : 'Edit Animal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );

                            if (image != null) {
                              setDialogState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.deepPurple, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.deepPurple.withOpacity(0.05),
                            ),
                            child: selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple),
                                        SizedBox(height: 8),
                                        Text(
                                          'Select Photo',
                                          style: TextStyle(color: Colors.deepPurple, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.pets),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: breedController,
                        decoration: InputDecoration(
                          labelText: 'Breed',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.info),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: feedAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Feed Amount per Day (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.deepPurple),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (animal == null) {
                                    animals.add({
                                      'name': nameController.text,
                                      'age': int.tryParse(ageController.text) ?? 0,
                                      'breed': breedController.text,
                                      'feedAmount': double.tryParse(feedAmountController.text) ?? 0.0,
                                      'image': selectedImage?.path,
                                    });
                                  } else {
                                    animals[index!] = {
                                      'name': nameController.text,
                                      'age': int.tryParse(ageController.text) ?? 0,
                                      'breed': breedController.text,
                                      'feedAmount': double.tryParse(feedAmountController.text) ?? 0.0,
                                      'image': selectedImage?.path,
                                    };
                                  }
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Save', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            color: Colors.deepPurple,
            child: const Center(
              child: Text(
                'My Animals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                ),
                itemCount: animals.length + 1,
                itemBuilder: (context, index) {
                  // Add Animal Card
                  if (index == 0) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showAddEditModal(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.deepPurple, width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.deepPurple,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Animal Cards
                  final animal = animals[index - 1];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnimalDetailsPage(animal: animal),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: animal['image'] != null && File(animal['image']).existsSync()
                                  ? Image.file(
                                      File(animal['image']),
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey,
                                        ),
                                        child: const Icon(
                                          Icons.pets,
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            animal['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


