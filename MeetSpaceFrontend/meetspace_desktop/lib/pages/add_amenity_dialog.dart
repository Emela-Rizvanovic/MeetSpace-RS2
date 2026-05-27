import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/amenity.dart';

class AddAmenityDialog extends StatefulWidget {
  final AmenityResponse? amenity;

  const AddAmenityDialog({super.key, this.amenity});

  @override
  State<AddAmenityDialog> createState() => _AddAmenityDialogState();
}

class _AddAmenityDialogState extends State<AddAmenityDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  List<dynamic> _categories = [];
  int? _categoryId;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.amenity != null) {
      _nameController.text = widget.amenity!.name;
      _descController.text = widget.amenity!.description ?? "";
      _priceController.text = widget.amenity!.price.toString();
      _categoryId = widget.amenity!.amenityCategoryId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final auth = context.read<AuthProvider>();
      final res = await auth.api.get(
  "AmenityCategory",
  queryParameters: {
    "Page": "0",
    "PageSize": "1000",
    "SortBy": "Id",
    "Desc": "true",
  },
);
      final decoded = jsonDecode(res.body);

      setState(() {
        _categories = decoded['items'] ?? [];
      });
   } catch (_) {
  if (!mounted) return;
  setState(() {
    _categories = [];
  });
}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();

      if (widget.amenity == null) {
        /// CREATE
        await auth.amenityService.api.post("Amenity", {
          "name": _nameController.text,
          "description": _descController.text,
          "price": double.parse(_priceController.text),
          "amenityCategoryId": _categoryId,
        });
      } else {
        /// UPDATE
        await auth.amenityService.api.put(
          "Amenity/${widget.amenity!.id}",
          {
            "name": _nameController.text,
            "description": _descController.text,
            "price": double.parse(_priceController.text),
            "amenityCategoryId": _categoryId,
          },
        );
      }

      Navigator.pop(context, widget.amenity == null ? "created" : "updated");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving amenity")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
  Row(
    children: [
      Expanded(
        child: Text(
          widget.amenity == null
              ? "Add new amenity"
              : "Edit amenity",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
        tooltip: "Close",
      ),
    ],
  ),

  const SizedBox(height: 20),

              _input(_nameController, "Name"),
              const SizedBox(height: 12),

              _input(_descController, "Description"),
              const SizedBox(height: 12),

              _input(_priceController, "Price", isNumber: true),
              const SizedBox(height: 12),

              /// 🔥 CATEGORY DROPDOWN
              DropdownButtonFormField<int>(
                value: _categoryId,
                items: _categories
                    .map<DropdownMenuItem<int>>(
                      (c) => DropdownMenuItem(
                        value: c['id'],
                        child: Text(c['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? "Category is required. Select one category from the list." : null,
                decoration: InputDecoration(
                  hintText: "Category",
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
   validator: (v) {
  if (v == null || v.trim().isEmpty) {
    return "$hint is required.";
  }

  final value = v.trim();

  if (isNumber) {
    final number = double.tryParse(value);

    if (number == null) {
      return "$hint must be a valid number, e.g. 10.50.";
    }

    if (number < 0) {
      return "$hint must be greater than or equal to 0.";
    }
  } else {
    if (hint.toLowerCase().contains("name") && value.length < 2) {
      return "Name must contain at least 2 characters.";
    }

    if (hint.toLowerCase().contains("description") && value.length > 500) {
      return "Description can contain up to 500 characters.";
    }
  }

  return null;
},
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}