import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/rest_api.dart';

class BurgerMenuScreen extends StatefulWidget {
  const BurgerMenuScreen({super.key});

  @override
  State<BurgerMenuScreen> createState() => _BurgerMenuScreenState();
}

class _BurgerMenuScreenState extends State<BurgerMenuScreen> {
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = RestApi.fetchProducts();
    });
  }

  // Dialog to Add a Burger (CREATE)
  // Inside _BurgerMenuScreenState in burger_menu_screen.dart:
  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final caloriesController = TextEditingController(text: '750');
    final proteinController = TextEditingController(text: '35g');
    final ingredientsController =
        TextEditingController(text: 'Beef Patty, Cheddar, Lettuce');
    final largeExtraPriceController = TextEditingController(text: '3.00');

    XFile? pickedFile;
    dynamic webImageBytes; // For instant preview on web / mobile

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Burger',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. FILE PICKER BUTTON & PREVIEW
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          pickedFile = file;
                          webImageBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid),
                      ),
                      child: webImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(webImageBytes,
                                  fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 40, color: Colors.blueAccent),
                                SizedBox(height: 6),
                                Text('Tap to upload image from device',
                                    style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. NAME & PRICE
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Burger Name *',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Base Price (\$) *',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),

                  // 3. CALORIES & PROTEIN
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Calories (kcal)',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: const InputDecoration(
                              labelText: 'Protein',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. INGREDIENTS
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                        labelText: 'Ingredients', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),

                  // 5. LARGE SIZE UPCHARGE
                  TextField(
                    controller: largeExtraPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Large Size Extra (+ \$)',
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) return;

                final basePrice = double.tryParse(priceController.text) ?? 10.0;
                final largeAdded =
                    double.tryParse(largeExtraPriceController.text) ?? 3.0;
                final ingredients = ingredientsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList();

                final fields = {
                  'category_id': '1',
                  'name': nameController.text.trim(),
                  'base_price': basePrice.toString(),
                  'rating': '5.0',
                  'calories': caloriesController.text.trim(),
                  'protein': proteinController.text.trim(),
                  'ingredients': jsonEncode(ingredients),
                  'sizes': jsonEncode([
                    {'size_name': 'Regular', 'price': basePrice},
                    {'size_name': 'Large', 'price': basePrice + largeAdded},
                  ]),
                };

                final success = await RestApi.uploadProductWithImage(
                  fields: fields,
                  imageFile: pickedFile,
                );

                if (!mounted) return;
                Navigator.pop(ctx);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Burger & image uploaded successfully!')),
                  );
                  _loadProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload failed.')),
                  );
                }
              },
              child: const Text('Upload & Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Edit a Burger (UPDATE)
  // Dialog to Edit All Burger Details (UPDATE)
  void _showEditDialog(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());

    // Extract calories & protein from nutritionFacts
    String initialCal = '';
    String initialPro = '';
    if (product.nutritionFacts.contains('kcal')) {
      final parts = product.nutritionFacts.split('•');
      initialCal = parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim();
      if (parts.length > 1) {
        initialPro = parts[1].replaceAll('Protein', '').trim();
      }
    }

    final caloriesController = TextEditingController(text: initialCal);
    final proteinController = TextEditingController(text: initialPro);
    final ingredientsController =
        TextEditingController(text: product.ingredients.join(', '));

    // Large price upcharge calculation
    double largeAddedCost = 3.0;
    if (product.sizePrices.containsKey('Large')) {
      largeAddedCost = (product.sizePrices['Large']! - product.price);
      if (largeAddedCost < 0) largeAddedCost = 3.0;
    }
    final largeExtraPriceController =
        TextEditingController(text: largeAddedCost.toStringAsFixed(2));

    XFile? newPickedFile;
    dynamic newImageBytes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${product.name}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Current / Replacement Image Picker
                  const Text('Burger Image:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          newPickedFile = file;
                          newImageBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: newImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(newImageBytes,
                                  fit: BoxFit.cover),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: product.imagePath.startsWith('http')
                                  ? Image.network(
                                      product.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Text('Tap to change image',
                                            style: TextStyle(
                                                color: Colors.black54)),
                                      ),
                                    )
                                  : Image.asset(
                                      product.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Text('Tap to change image',
                                            style: TextStyle(
                                                color: Colors.black54)),
                                      ),
                                    ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Name & Base Price
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Burger Name *',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Base Price (\$) *',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),

                  // 3. Nutrition (Calories & Protein)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Calories (kcal)',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: const InputDecoration(
                              labelText: 'Protein',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Ingredients
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. Size Pricing Extra
                  TextField(
                    controller: largeExtraPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Large Size Extra (+ \$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) return;

                final basePrice =
                    double.tryParse(priceController.text) ?? product.price;
                final largeAdded =
                    double.tryParse(largeExtraPriceController.text) ?? 3.0;
                final ingredients = ingredientsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final fields = {
                  'name': nameController.text.trim(),
                  'base_price': basePrice.toString(),
                  'calories': caloriesController.text.trim(),
                  'protein': proteinController.text.trim(),
                  'ingredients': jsonEncode(ingredients),
                  'sizes': jsonEncode([
                    {'size_name': 'Regular', 'price': basePrice},
                    {'size_name': 'Large', 'price': basePrice + largeAdded},
                  ]),
                };

                final success = await RestApi.updateProductWithImage(
                  id: product.id,
                  fields: fields,
                  imageFile: newPickedFile,
                );

                if (!mounted) return;
                Navigator.pop(ctx);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Burger updated successfully!')),
                  );
                  _loadProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update burger.')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // Delete Action (DELETE)
  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Burger'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await RestApi.deleteProduct(product.id);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Burger deleted.')),
                );
                _loadProducts();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete failed.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Angkor Burger Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    'Connection Error: ${snapshot.error}\n\nMake sure your Laravel backend is running.'),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No burgers found. Tap + to add one!'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final burger = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: _buildBurgerImage(burger.imagePath),
                    ),
                  ),
                  title: Text(burger.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '\$${burger.price.toStringAsFixed(2)} • ${burger.nutritionFacts}\n'
                    '${burger.sizePrices.length} sizes • ${burger.addOns.length} add-ons',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(burger),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(burger),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBurgerImage(String path) {
    final clean = path.trim();

    // 1. Network Image (uploaded from Laravel server)
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final safeUrl = Uri.encodeFull(clean);

      return Image.network(
        safeUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const CircleAvatar(
          backgroundColor: Color(0xFFFFECB3),
          child: Icon(Icons.lunch_dining, color: Colors.brown),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // 2. Local Asset
    String assetPath = clean;
    if (assetPath.startsWith('assets/assets/')) {
      assetPath = assetPath.replaceFirst('assets/assets/', 'assets/');
    } else if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }

    if (assetPath.contains('burger.png') ||
        assetPath.contains('wings.png') ||
        assetPath.isEmpty) {
      assetPath = 'assets/images/imagelist1.jpg';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const CircleAvatar(
        backgroundColor: Color(0xFFFFECB3),
        child: Icon(Icons.lunch_dining, color: Colors.brown),
      ),
    );
  }
}
