import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../home/home_style.dart';

class MenuDish {
  MenuDish(
    this.name,
    this.description,
    this.price,
    this.category,
    this.image, {
    this.available = true,
    this.photo,
  });
  String name, description, category;
  int price;
  String? image;
  Uint8List? photo;
  bool available;
}

class FoodEditorScreen extends StatefulWidget {
  const FoodEditorScreen({
    super.key,
    this.dish,
    this.onNavigate,
    this.pickImage,
  });
  final MenuDish? dish;
  final ValueChanged<int>? onNavigate;
  final Future<XFile?> Function()? pickImage;
  @override
  State<FoodEditorScreen> createState() => _FoodEditorScreenState();
}

class _FoodEditorScreenState extends State<FoodEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _description, _price;
  late String _category;
  late bool _available;
  Uint8List? _photo;
  String? _imageError;
  bool _picking = false;
  @override
  void initState() {
    super.initState();
    final dish = widget.dish;
    _name = TextEditingController(text: dish?.name);
    _description = TextEditingController(text: dish?.description);
    _price = TextEditingController(text: dish?.price.toString() ?? '0');
    _category = dish?.category ?? 'Rice & Curry';
    _available = dish?.available ?? true;
    _photo = dish?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final file =
          await (widget.pickImage?.call() ??
              ImagePicker().pickImage(source: ImageSource.gallery));
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 5 MB.');
      }
      final bytes = await file.readAsBytes();
      final jpg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      if (!jpg && !png) {
        throw const FormatException('Choose a JPG or PNG image.');
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) {
        setState(
          () => _imageError = e is FormatException
              ? e.message
              : 'Could not open this image. Please choose another.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    if (!_form.currentState!.validate() || _picking) return;
    Navigator.pop(
      context,
      MenuDish(
        _name.text.trim(),
        _description.text.trim(),
        int.parse(_price.text.trim()),
        _category,
        widget.dish?.image,
        available: _available,
        photo: _photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HomeStyle.border),
        ),
        labelStyle: const TextStyle(color: HomeStyle.muted, fontSize: 12),
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'MealMate',
              style: TextStyle(color: HomeStyle.orange, fontSize: 10),
            ),
            Text(
              widget.dish == null ? 'Add Food Item' : 'Edit Food Item',
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
        actions: const [
          Center(
            child: Text(
              'OWNER',
              style: TextStyle(color: HomeStyle.orange, fontSize: 10),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Shan Food Cabin',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            widget.dish == null
                ? 'Add a dish to your menu · Required fields *'
                : 'Update your menu item · Required fields *',
            style: const TextStyle(color: HomeStyle.muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HomeStyle.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Food image',
                    style: TextStyle(fontSize: 11, color: HomeStyle.muted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _photo != null
                        ? Image.memory(_photo!, height: 150, fit: BoxFit.cover)
                        : widget.dish?.image != null
                        ? Image.asset(
                            widget.dish!.image!,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            height: 150,
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: HomeStyle.muted,
                              size: 48,
                            ),
                          ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _picking ? null : _pick,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(
                      _picking
                          ? 'Opening photo...'
                          : _photo != null || widget.dish?.image != null
                          ? 'Change image'
                          : 'Upload image',
                    ),
                  ),
                  const Text(
                    'JPG or PNG, up to 5 MB. Use a clear food photo.',
                    style: TextStyle(color: HomeStyle.muted, fontSize: 10),
                  ),
                  if (_imageError != null)
                    Text(
                      _imageError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Item name *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a name.' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      helperText: 'Describe ingredients and portion size.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Food category *',
                    ),
                    items: [
                      for (final c in [
                        'Rice & Curry',
                        'Short Eats',
                        'Beverages',
                      ])
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      prefixText: 'LKR  ',
                      helperText: 'Price per portion in Sri Lankan rupees.',
                    ),
                    validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) <= 0
                        ? 'Enter a price greater than LKR 0.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Available',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Turn off to mark as unavailable.',
                        style: TextStyle(fontSize: 10),
                      ),
                      value: _available,
                      activeTrackColor: HomeStyle.green,
                      onChanged: (v) => setState(() => _available = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Preview · Changes are not published',
            style: TextStyle(color: HomeStyle.muted, fontSize: 10),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _picking ? null : _save,
            child: const Text('Save item'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: HomeStyle.orange,
        unselectedItemColor: HomeStyle.muted,
        onTap: (i) {
          Navigator.pop(context);
          widget.onNavigate?.call(i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}
