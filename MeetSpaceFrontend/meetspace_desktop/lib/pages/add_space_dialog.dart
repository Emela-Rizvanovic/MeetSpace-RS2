import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/space.dart';

class AddSpaceDialog extends StatefulWidget {
  final SpaceResponse? space;

  const AddSpaceDialog({super.key, this.space});

  @override
  State<AddSpaceDialog> createState() => _AddSpaceDialogState();
}

class _AddSpaceDialogState extends State<AddSpaceDialog> {
  final _formKey = GlobalKey<FormState>();
    List<int> _imagesToDelete = [];

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  int? _facilityId;
  int? _spaceTypeId;
  List<int> _selectedAmenities = [];

  List<File> _images = [];

  List<dynamic> _facilities = [];
  List<dynamic> _spaceTypes = [];
  List<dynamic> _amenities = [];

  bool _loading = false;

  @override
void initState() {
  super.initState();
  _loadDropdowns();

  final s = widget.space;

  if (s != null) {
    _nameController.text = s.name;
    _descController.text = s.description;
    _priceController.text = s.pricePerHour.toString();
    _capacityController.text = s.capacity.toString();

    _facilityId = s.facilityId;
    _spaceTypeId = s.spaceTypeId;

    _selectedAmenities = s.amenities.map((a) => a.id).toList();
  }
}

Future<void> _loadDropdowns() async {
  final auth = context.read<AuthProvider>();
final api = auth.api;

 final fRes = await api.get(
  "Facility",
  queryParameters: {
    "Page": "0",
    "PageSize": "1000",
    "SortBy": "Id",
    "Desc": "true",
  },
);

final tRes = await api.get(
  "SpaceType",
  queryParameters: {
    "Page": "0",
    "PageSize": "1000",
    "SortBy": "Id",
    "Desc": "true",
  },
);

final aRes = await api.get(
  "Amenity",
  queryParameters: {
    "Page": "0",
    "PageSize": "1000",
    "SortBy": "Id",
    "Desc": "true",
  },
);

  final fDecoded = jsonDecode(fRes.body);
  final tDecoded = jsonDecode(tRes.body);
  final aDecoded = jsonDecode(aRes.body);

  setState(() {
    _facilities = fDecoded['items'] ?? [];
    _spaceTypes = tDecoded['items'] ?? [];
    _amenities = aDecoded['items'] ?? [];
  });
}

 Future<void> _pickImages() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.image,
  );

  if (result != null) {
    setState(() {
      _images.addAll(
        result.paths.map((p) => File(p!)),
      );
    });
  }
}

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
final spaceService = auth.spaceService;

      if (widget.space == null) {
  await spaceService.createSpace(
    name: _nameController.text,
    description: _descController.text,
    price: double.parse(_priceController.text),
    capacity: int.parse(_capacityController.text),
    facilityId: _facilityId!,
    spaceTypeId: _spaceTypeId!,
    images: _images,
    amenityIds: _selectedAmenities,
  );
} else {
 await spaceService.updateSpace(
  id: widget.space!.id,
  name: _nameController.text,
  description: _descController.text,
  price: double.parse(_priceController.text),
  capacity: int.parse(_capacityController.text),
  facilityId: _facilityId!,
  spaceTypeId: _spaceTypeId!,
  amenityIds: _selectedAmenities,
  newImages: _images,
  deleteImageIds: _imagesToDelete, 
);
}

      Navigator.pop(context, widget.space == null ? "created" : "updated");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
  content: Text(widget.space == null
      ? "Error creating space"
      : "Error updating space"),
),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 750,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
       child: Form(
  key: _formKey,
  child: SingleChildScrollView(
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.space == null ? "Add new space" : "Edit space",
                style: const TextStyle(
                  fontSize: 32,
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
                Row(
  children: [
    Expanded(
      child: _input(
        _nameController,
        "Name",
        minLength: 3,
        maxLength: 50,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _dropdown(
                        hint: "Facility",
                        value: _facilityId,
                        items: _facilities,
                        onChanged: (v) => setState(() => _facilityId = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

               Row(
  children: [
    Expanded(
      child: _input(_capacityController, "Capacity", isNumber: true),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _input(_priceController, "Price per hour", isNumber: true),
    ),
  ],
),

                const SizedBox(height: 12),

                _dropdown(
                  hint: "Space type",
                  value: _spaceTypeId,
                  items: _spaceTypes,
                  onChanged: (v) => setState(() => _spaceTypeId = v),
                ),

                const SizedBox(height: 12),

                _input(_descController, "Description", minLength: 10, maxLength: 500),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: _amenities.map((a) {
                      final id = a['id'];
                      return FilterChip(
                        label: Text(a['name']),
                        selected: _selectedAmenities.contains(id),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedAmenities.add(id);
                            } else {
                              _selectedAmenities.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

if (widget.space != null && widget.space!.images.isNotEmpty) ...[
  const SizedBox(height: 10),
  Align(
    alignment: Alignment.centerLeft,
    child: const Text("Existing images"),
  ),
  const SizedBox(height: 10),

  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: widget.space!.images.map((img) {
      final isDeleted = _imagesToDelete.contains(img.id);

      return Stack(
        children: [
          Opacity(
            opacity: isDeleted ? 0.3 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                img.imageUrl,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isDeleted) {
                    _imagesToDelete.remove(img.id);
                  } else {
                    _imagesToDelete.add(img.id);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDeleted ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeleted ? Icons.undo : Icons.delete,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList(),
  ),
],
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                   child: _images.isEmpty
    ? const Center(child: Text("Import photos"))
    : Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _images.map((img) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  img,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _images.remove(img);
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
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
      ),
    );
  }

Widget _input(
  TextEditingController controller,
  String hint, {
  bool isNumber = false,
  int? minLength,
  int? maxLength,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
  validator: (v) {
  if (v == null || v.trim().isEmpty) {
    return "$hint is required.";
  }

  final value = v.trim();

  if (!isNumber) {
    if (minLength != null && value.length < minLength) {
      return "$hint must contain at least $minLength characters.";
    }

    if (maxLength != null && value.length > maxLength) {
      return "$hint can contain up to $maxLength characters.";
    }
  } else {
    final number = double.tryParse(value);

    if (number == null) {
      return "$hint must be a valid number, e.g. 25.50.";
    }

    if (number <= 0) {
      return "$hint must be greater than 0.";
    }

    if (hint.toLowerCase().contains("capacity") && number % 1 != 0) {
      return "Capacity must be a whole number greater than 0, e.g. 10.";
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

  Widget _dropdown({
    required String hint,
    required int? value,
    required List items,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items
          .map<DropdownMenuItem<int>>(
            (e) => DropdownMenuItem(
              value: e['id'],
              child: Text(e['name'] ?? e['title'] ?? 'Unknown'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "$hint is required. Select a value from the list." : null,
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