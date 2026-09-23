import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/rest_api.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? existingProduct; // Pass null for Add, or pass product to Edit

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // --- Controllers ---
  final _nameController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _ratingController = TextEditingController(text: '4.8');
  final _caloriesController = TextEditingController(text: '840');
  final _proteinController = TextEditingController(text: '42');
  final _fatController = TextEditingController(text: '58');
  final _carbsController = TextEditingController(text: '32');
  final _ingredientInputController = TextEditingController();
  final _newCategoryController = TextEditingController();

  // --- States ---
  String _selectedCategory = "Burgers (Gourmet Series)";
  bool _showCreateCategory = false;
  bool _isPopular = true;
  bool _isSaving = false;

  // Image Upload State
  XFile? _pickedImage;
  dynamic _imagePreviewBytes;
  String _existingImagePath = 'assets/images/imagelist1.jpg';

  // Ingredients tag list
  List<String> _ingredients = ['A5 Wagyu Beef', 'Truffle Aioli', 'Wild Arugula'];

  // Sizes dynamic list
  List<Map<String, dynamic>> _sizes = [
    {'size': 'S', 'price': 14.00, 'controller': TextEditingController(text: '14.00')},
    {'size': 'M', 'price': 18.50, 'controller': TextEditingController(text: '18.50')},
    {'size': 'L', 'price': 22.00, 'controller': TextEditingController(text: '22.00')},
  ];

  // Addons dynamic list
  List<Map<String, dynamic>> _addons = [
    {
      'name': 'Extra Crispy Chicken Strip',
      'price': 4.00,
      'nameController': TextEditingController(text: 'Extra Crispy Chicken Strip'),
      'priceController': TextEditingController(text: '4.00'),
    },
    {
      'name': 'Extra Truffle Aioli',
      'price': 1.50,
      'nameController': TextEditingController(text: 'Extra Truffle Aioli'),
      'priceController': TextEditingController(text: '1.50'),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      _basePriceController.text = p.price.toStringAsFixed(2);
      _ratingController.text = p.rating.toString();
      _existingImagePath = p.imagePath;

      // Extract Nutrition
      if (p.nutritionFacts.contains('kcal')) {
        final parts = p.nutritionFacts.split('•');
        _caloriesController.text = parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim();
        if (parts.length > 1) {
          _proteinController.text = parts[1].replaceAll(RegExp(r'[^0-9]'), '').trim();
        }
      }

      if (p.ingredients.isNotEmpty) {
        _ingredients = List.from(p.ingredients);
      }

      if (p.sizePrices.isNotEmpty) {
        _sizes = p.sizePrices.entries.map((e) {
          return {
            'size': e.key,
            'price': e.value,
            'controller': TextEditingController(text: e.value.toStringAsFixed(2)),
          };
        }).toList();
      }

      if (p.addOns.isNotEmpty) {
        _addons = p.addOns.entries.map((e) {
          return {
            'name': e.key,
            'price': e.value,
            'nameController': TextEditingController(text: e.key),
            'priceController': TextEditingController(text: e.value.toStringAsFixed(2)),
          };
        }).toList();
      }
    }
  }

  // --- Add Ingredient Chip ---
  void _addIngredient() {
    final text = _ingredientInputController.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
        _ingredientInputController.clear();
      });
    }
  }

  // --- Image Picker ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _imagePreviewBytes = bytes;
      });
    }
  }

  // --- Save / Publish to Laravel API ---
  Future<void> _saveAndPublish() async {
    if (_nameController.text.trim().isEmpty || _basePriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in product name and base price.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final basePrice = double.tryParse(_basePriceController.text) ?? 10.0;
    final rating = double.tryParse(_ratingController.text) ?? 5.0;

    final sizesPayload = _sizes.map((s) {
      final p = double.tryParse((s['controller'] as TextEditingController).text) ?? basePrice;
      return {'size_name': s['size'], 'price': p};
    }).toList();

    final addonsPayload = _addons.map((a) {
      final name = (a['nameController'] as TextEditingController).text.trim();
      final p = double.tryParse((a['priceController'] as TextEditingController).text) ?? 1.0;
      return {'name': name, 'price': p};
    }).where((a) => (a['name'] as String).isNotEmpty).toList();

    final fields = {
      'category_id': '1',
      'name': _nameController.text.trim(),
      'base_price': basePrice.toString(),
      'rating': rating.toString(),
      'is_popular': _isPopular ? '1' : '0',
      'calories': _caloriesController.text.trim(),
      'protein': '${_proteinController.text.trim()}g',
      'ingredients': jsonEncode(_ingredients),
      'sizes': jsonEncode(sizesPayload),
      'addons': jsonEncode(addonsPayload),
    };

    bool success = false;
    if (widget.existingProduct != null) {
      success = await RestApi.updateProductWithImage(
        id: widget.existingProduct!.id,
        fields: fields,
        imageFile: _pickedImage,
      );
    } else {
      success = await RestApi.uploadProductWithImage(
        fields: fields,
        imageFile: _pickedImage,
      );
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product published successfully!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish product.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF7A1C1C);
    const cardBgColor = Colors.white;
    final scaffoldBg = Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: maroonColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lunch_dining, color: maroonColor, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              widget.existingProduct != null ? 'Edit Menu Item' : 'Add Menu Item',
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: maroonColor,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products > Add New Item',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('POS & Mobile Sync Ready', style: TextStyle(fontSize: 10, color: Colors.black54)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Add New Menu Product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Text(
              'Configure food item menu portions and add-ons for POS and Mobile App Sync.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // ================= 1. CATEGORY ALLOCATION =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Category Allocation', badge: 'ID: SEC-CAT-01'),
                  const SizedBox(height: 12),
                  const Text('Assigned Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: ['Burgers (Gourmet Series)', 'Chicken & Wings', 'Drinks & Fries']
                                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showCreateCategory = !_showCreateCategory),
                        icon: const Icon(Icons.add, size: 16, color: maroonColor),
                        label: const Text('New', style: TextStyle(color: maroonColor, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: maroonColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  if (_showCreateCategory) ...[
                    const SizedBox(height: 14),
                    _buildSubBox(
                      title: 'Create Category',
                      subtitle: 'Add a new catalog category for POS & mobile menu sync.',
                      onClose: () => setState(() => _showCreateCategory = false),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _newCategoryController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Gourmet Sides',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('SVG/PNG icon Drop or Browse', style: TextStyle(fontSize: 11, color: Colors.black87)),
                                Text('Max 1 File (up to 2MB)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => setState(() => _showCreateCategory = false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_newCategoryController.text.isNotEmpty) {
                                    setState(() {
                                      _selectedCategory = _newCategoryController.text.trim();
                                      _showCreateCategory = false;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                label: const Text('Save Category', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: maroonColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 2. CORE ITEM DETAILS =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Core Item Details', badge: 'Standard Info'),
                  const SizedBox(height: 12),
                  const Text('Product Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. Angkor Royal Truffle Burger',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Base Price (\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _basePriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.attach_money, size: 16),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Initial Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _ratingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.star, size: 16, color: Colors.amber),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Popular Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Show in home feed and recommendations.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPopular,
                          activeColor: maroonColor,
                          onChanged: (val) => setState(() => _isPopular = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 3. NUTRITION FACTS =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Nutrition Facts', badge: 'Per Standard Serving'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildNutritionTile('Calories', _caloriesController, 'kcal', Icons.local_fire_department, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildNutritionTile('Protein', _proteinController, 'g', Icons.fitness_center, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildNutritionTile('Fat', _fatController, 'g', Icons.opacity, Colors.deepOrange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildNutritionTile('Carbs', _carbsController, 'g', Icons.grain, Colors.teal)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 4. INGREDIENTS & RECIPE =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Ingredients & Recipe', badge: '${_ingredients.length} Active Components'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _ingredients.map((ing) {
                      return Chip(
                        label: Text(ing, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _ingredients.remove(ing)),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientInputController,
                          decoration: InputDecoration(
                            hintText: 'Type ingredient...',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addIngredient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 5. PORTIONS & SIZES =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Portions & Sizes'),
                  const SizedBox(height: 10),
                  ..._sizes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final size = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(size['size'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: size['controller'] as TextEditingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.attach_money, size: 16),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () {
                              if (_sizes.length > 1) {
                                setState(() => _sizes.removeAt(index));
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _sizes.add({
                            'size': 'XL',
                            'price': 25.0,
                            'controller': TextEditingController(text: '25.00'),
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 16, color: maroonColor),
                      label: const Text('+ Add Size Option', style: TextStyle(color: maroonColor, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 6. CUSTOM ADD-ONS =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Custom Add-ons', badge: '${_addons.length} Configured'),
                  const SizedBox(height: 10),
                  ..._addons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final addon = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: addon['nameController'] as TextEditingController,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Addon Name'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TextField(
                              controller: addon['priceController'] as TextEditingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '+\$',
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: maroonColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => setState(() => _addons.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _addons.add({
                            'name': 'New Addon',
                            'price': 1.00,
                            'nameController': TextEditingController(text: 'New Addon'),
                            'priceController': TextEditingController(text: '1.00'),
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 16, color: maroonColor),
                      label: const Text('+ Add Option', style: TextStyle(color: maroonColor, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ================= 7. MENU DISPLAY PREVIEW =================
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Menu Display Preview'),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera, size: 16, color: maroonColor),
                        label: const Text('Upload Image', style: TextStyle(color: maroonColor, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black87,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imagePreviewBytes != null)
                          Image.memory(_imagePreviewBytes, fit: BoxFit.cover)
                        else if (_pickedImage != null)
                          const Center(child: CircularProgressIndicator())
                        else if (_existingImagePath.startsWith('http'))
                          Image.network(_existingImagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.lunch_dining, color: Colors.white, size: 40))
                        else
                          Image.asset(_existingImagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.lunch_dining, color: Colors.white, size: 40)),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty ? 'Angkor Royal Truffle Burger' : _nameController.text,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '\$${_basePriceController.text.isEmpty ? '18.50' : _basePriceController.text} • $_selectedCategory',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ================= 8. BOTTOM ACTIONS =================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAndPublish,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save & Publish',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, {String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF7A1C1C), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        if (badge != null)
          Text(badge, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubBox({required String title, required String subtitle, required VoidCallback onClose, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              InkWell(onTap: onClose, child: const Icon(Icons.close, size: 16, color: Colors.grey)),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildNutritionTile(String label, TextEditingController controller, String unit, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Row(
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      ),
                    ),
                    Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Icon(icon, color: iconColor, size: 18),
        ],
      ),
    );
  }
}