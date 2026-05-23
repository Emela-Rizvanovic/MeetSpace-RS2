import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/country.dart';
import '../providers/auth_provider.dart';
import '../models/city.dart';
import '../models/facility.dart';
import '../models/space_type.dart';
import '../utils/validators.dart';
import '../widgets/admin_styles.dart';
import '../widgets/countries_section.dart';
import '../widgets/cities_section.dart';
import '../widgets/facilities_section.dart';
import '../widgets/space_types_section.dart';
import '../widgets/confirm_delete_dialog.dart';

class ReferenceDataDialog extends StatefulWidget {
  const ReferenceDataDialog({super.key});

  @override
  State<ReferenceDataDialog> createState() =>
      _ReferenceDataDialogState();
}

class _ReferenceDataDialogState
    extends State<ReferenceDataDialog> {

List<Country> _countries = [];
bool _isLoadingCountries = false;
String _countrySearch = "";
int _countryPage = 0;
final int _countryPageSize = 4;
int _countryTotalPages = 1;

List<City> _cities = [];
bool _isLoadingCities = false;
String _citySearch = "";
int _cityPage = 0;
final int _cityPageSize = 4;
int _cityTotalPages = 1;

List<Facility> _facilities = [];
bool _isLoadingFacilities = false;
String _facilitySearch = "";
int _facilityPage = 0;
final int _facilityPageSize = 4;
int _facilityTotalPages = 1;

List<SpaceType> _spaceTypes = [];
bool _isLoadingSpaceTypes = false;
String _spaceTypeSearch = "";
int _spaceTypePage = 0;
final int _spaceTypePageSize = 4;
int _spaceTypeTotalPages = 1;

@override
void initState() {
  super.initState();

  _loadCountries();
  _loadCities();
  _loadFacilities();
  _loadSpaceTypes();
}

  String _selected = "Countries";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminStyles.bgColor,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        width: 1200,
        height: 700,
        child: Row(
          children: [

            /// SIDEBAR
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AdminStyles.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [

                  const SizedBox(height: 30),

                  const Text(
                    "REFERENCE DATA",
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildMenuItem("Countries"),
                  _buildMenuItem("Cities"),
                  _buildMenuItem("Facilities"),
                  _buildMenuItem("Space types"),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                       style: AdminStyles.primaryButton,
                        child: const Text("Close"),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    final selected = _selected == title;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selected = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color:
                selected ? AdminStyles.brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selected) {
 case "Countries":
  return CountriesSection(
    countries: _countries,

    isLoading:
        _isLoadingCountries,

    currentPage:
        _countryPage,

    totalPages:
        _countryTotalPages,

    onSearch: (value) {
      setState(() {
        _countrySearch = value;
        _countryPage = 0;
      });

      _loadCountries();
    },

    onAdd: () async {
      await _showCountryDialog();
    },

    onEdit: (country) async {
      await _showCountryDialog(
        country: country,
      );
    },

    onDelete: (country) async {
      await _deleteCountry(country);
    },

    onPrevious:
        _countryPage > 0
            ? () {
                setState(() {
                  _countryPage--;
                });

                _loadCountries();
              }
            : null,

    onNext:
        _countryPage <
                _countryTotalPages - 1
            ? () {
                setState(() {
                  _countryPage++;
                });

                _loadCountries();
              }
            : null,

    onPageSelected: (page) {
      setState(() {
        _countryPage = page;
      });

      _loadCountries();
    },
  );
case "Cities":
  return CitiesSection(
    cities: _cities,

    isLoading:
        _isLoadingCities,

    currentPage:
        _cityPage,

    totalPages:
        _cityTotalPages,

    onSearch: (value) {
      setState(() {
        _citySearch = value;
        _cityPage = 0;
      });

      _loadCities();
    },

    onAdd: () async {
      await _showCityDialog();
    },

    onEdit: (city) async {
      await _showCityDialog(
        city: city,
      );
    },

    onDelete: (city) async {
      await _deleteCity(city);
    },

    onPrevious:
        _cityPage > 0
            ? () {
                setState(() {
                  _cityPage--;
                });

                _loadCities();
              }
            : null,

    onNext:
        _cityPage <
                _cityTotalPages - 1
            ? () {
                setState(() {
                  _cityPage++;
                });

                _loadCities();
              }
            : null,

    onPageSelected: (page) {
      setState(() {
        _cityPage = page;
      });

      _loadCities();
    },
  );
     case "Facilities":
  return FacilitiesSection(
    facilities: _facilities,

    isLoading:
        _isLoadingFacilities,

    currentPage:
        _facilityPage,

    totalPages:
        _facilityTotalPages,

    onSearch: (value) {
      setState(() {
        _facilitySearch = value;
        _facilityPage = 0;
      });

      _loadFacilities();
    },

    onAdd: () async {
      await _showFacilityDialog();
    },

    onEdit: (facility) async {
      await _showFacilityDialog(
        facility: facility,
      );
    },

    onDelete: (facility) async {
      await _deleteFacility(
        facility,
      );
    },

    onPrevious:
        _facilityPage > 0
            ? () {
                setState(() {
                  _facilityPage--;
                });

                _loadFacilities();
              }
            : null,

    onNext:
        _facilityPage <
                _facilityTotalPages - 1
            ? () {
                setState(() {
                  _facilityPage++;
                });

                _loadFacilities();
              }
            : null,

    onPageSelected: (page) {
      setState(() {
        _facilityPage = page;
      });

      _loadFacilities();
    },
  );
     case "Space types":
  return SpaceTypesSection(
    spaceTypes: _spaceTypes,

    isLoading:
        _isLoadingSpaceTypes,

    currentPage:
        _spaceTypePage,

    totalPages:
        _spaceTypeTotalPages,

    onSearch: (value) {
      setState(() {
        _spaceTypeSearch =
            value;

        _spaceTypePage = 0;
      });

      _loadSpaceTypes();
    },

    onAdd: () async {
      await _showSpaceTypeDialog();
    },

    onEdit: (type) async {
      await _showSpaceTypeDialog(
        type: type,
      );
    },

    onDelete: (type) async {
      await _deleteSpaceType(
        type,
      );
    },

    onPrevious:
        _spaceTypePage > 0
            ? () {
                setState(() {
                  _spaceTypePage--;
                });

                _loadSpaceTypes();
              }
            : null,

    onNext:
        _spaceTypePage <
                _spaceTypeTotalPages - 1
            ? () {
                setState(() {
                  _spaceTypePage++;
                });

                _loadSpaceTypes();
              }
            : null,

    onPageSelected: (page) {
      setState(() {
        _spaceTypePage = page;
      });

      _loadSpaceTypes();
    },
  );

      default:
        return const SizedBox();
    }
  }

Future<void> _showCountryDialog({
  Country? country,
}) async {
  final formKey = GlobalKey<FormState>();
  
  final controller = TextEditingController(
    text: country?.name ?? "",
  );

  final result = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: AdminStyles.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          country == null
              ? "Add country"
              : "Edit country",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
       content: SizedBox(
  width: 400,
  child: Form(
    key: formKey,
    child: TextFormField(
      controller: controller,

      autovalidateMode:
          AutovalidateMode.onUserInteraction,

      validator: (value) =>
          Validators.required(
        value,
        "Country name",
      ),

      style: const TextStyle(
        color: Colors.white,
      ),

    decoration:
    AdminStyles.inputDecoration(
  "Country name",
),
    ),
  ),
),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: AdminStyles.cancelButton,
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {

  if (!formKey.currentState!
      .validate()) {
    return;
  }
              try {
                final auth =
                    context.read<AuthProvider>();

                if (country == null) {
                  await auth.countryService.insert({
                    "name": controller.text,
                  });
                } else {
                  await auth.countryService.update(
                    country.id,
                    {
                      "name": controller.text,
                    },
                  );
                }

                Navigator.pop(context, true);
             } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
            },
          style: AdminStyles.primaryButton,
            child: const Text("Save"),
          ),
        ],
      );
    },
  );

  if (result == true) {
    await _loadCountries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            country == null
                ? "Country added successfully"
                : "Country updated successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

Future<void> _deleteCountry(
  Country country,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) {
return ConfirmDeleteDialog(
  title: "Delete country",

  message:
      "Are you sure you want to delete ${country.name}?",
);
    },
  );

  if (confirmed == true) {
    try {
      final auth = context.read<AuthProvider>();

      await auth.countryService.delete(
        country.id,
      );

      await _loadCountries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Country deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot delete country because it is in use.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

Future<void> _showCityDialog({
  City? city,
}) async {
  final formKey = GlobalKey<FormState>();

  final controller = TextEditingController(
    text: city?.name ?? "",
  );

  int? selectedCountryId =
      city?.countryId ??
      (_countries.isNotEmpty
          ? _countries.first.id
          : null);

  final result = await showDialog<bool>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AdminStyles.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            title: Text(
              city == null
                  ? "Add city"
                  : "Edit city",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Form(
  key: formKey,
  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                 /// CITY NAME
TextFormField(
  controller: controller,

  autovalidateMode:
      AutovalidateMode.onUserInteraction,

  validator: (value) =>
      Validators.required(
    value,
    "City name",
  ),

  style: const TextStyle(
    color: Colors.white,
  ),

decoration:
    AdminStyles.inputDecoration(
  "City name",
),
),

                  const SizedBox(height: 20),

                  /// COUNTRY DROPDOWN
                  DropdownButtonFormField<int>(
                    value: selectedCountryId,
                    dropdownColor: AdminStyles.cardColor,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AdminStyles.bgColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                14),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                    items: _countries.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedCountryId =
                            value;
                      });
                    },
                  ),
               ],
),
),
),
            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
               style: AdminStyles.cancelButton,
                child: const Text(
                  "Cancel",
                ),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!
    .validate()) {
  return;
}
                  try {
                    final auth =
                        context.read<
                            AuthProvider>();

                    final body = {
                      "name":
                          controller.text,
                      "countryId":
                          selectedCountryId,
                    };

                    if (city == null) {
                      await auth.cityService
                          .insert(body);
                    } else {
                      await auth.cityService
                          .update(
                        city.id,
                        body,
                      );
                    }

                    Navigator.pop(
                      context,
                      true,
                    );
                } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
                },
               style: AdminStyles.primaryButton,
                child: const Text(
                  "Save",
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
    await _loadCities();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            city == null
                ? "City added successfully"
                : "City updated successfully",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    }
  }
}

Future<void> _deleteCity(
  City city,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (_) {
  return ConfirmDeleteDialog(
  title: "Delete city",

  message:
      "Are you sure you want to delete ${city.name}?",
);
    },
  );

  if (confirmed == true) {
    try {
      final auth =
          context.read<AuthProvider>();

      await auth.cityService.delete(
        city.id,
      );

      await _loadCities();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "City deleted successfully",
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot delete city because it is in use.",
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
    }
  }
}

Future<void> _showFacilityDialog({
  Facility? facility,
}) async {
  final formKey = GlobalKey<FormState>();

  final nameController =
      TextEditingController(
    text: facility?.name ?? "",
  );

  final addressController =
      TextEditingController(
    text: facility?.address ?? "",
  );

  final emailController =
      TextEditingController(
    text:
        facility?.contactEmail ?? "",
  );

  final phoneController =
      TextEditingController(
    text:
        facility?.contactPhone ?? "",
  );

  final descriptionController =
      TextEditingController(
    text:
        facility?.description ?? "",
  );

  int? selectedCityId =
      facility?.cityId ??
      (_cities.isNotEmpty
          ? _cities.first.id
          : null);

  final result =
      await showDialog<bool>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder:
            (context, setModalState) {
          return AlertDialog(
            backgroundColor:
                AdminStyles.cardColor,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                      20),
            ),
            title: Text(
              facility == null
                  ? "Add facility"
                  : "Edit facility",
              style:
                  const TextStyle(
                color: Colors.white,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
  child: Form(
    key: formKey,
    child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [

                    /// NAME
TextFormField(
  controller: nameController,

  autovalidateMode:
      AutovalidateMode.onUserInteraction,

  validator: (value) =>
      Validators.required(
    value,
    "Facility name",
  ),

  style: const TextStyle(
    color: Colors.white,
  ),

decoration:
    AdminStyles.inputDecoration(
  "Facility name",
),
),

                    const SizedBox(
                        height: 16),

                    /// ADDRESS
TextFormField(
  controller: addressController,

  autovalidateMode:
      AutovalidateMode.onUserInteraction,

  validator: (value) =>
      Validators.required(
    value,
    "Address",
  ),

  style: const TextStyle(
    color: Colors.white,
  ),

decoration:
    AdminStyles.inputDecoration(
  "Address",
),
),

                    const SizedBox(
                        height: 16),

                    /// CITY
                    DropdownButtonFormField<
                        int>(
                      value:
                          selectedCityId,
                      dropdownColor:
                          AdminStyles.cardColor,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                      decoration:
                          InputDecoration(
                        filled: true,
                        fillColor:
                            AdminStyles.bgColor,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  14),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                      ),
                      items:
                          _cities.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child:
                              Text(c.name),
                        );
                      }).toList(),
                      onChanged:
                          (value) {
                        setModalState(() {
                          selectedCityId =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                        height: 16),

                    /// EMAIL
TextFormField(
  controller: emailController,

  autovalidateMode:
      AutovalidateMode.onUserInteraction,

  validator: Validators.email,

  style: const TextStyle(
    color: Colors.white,
  ),

decoration:
    AdminStyles.inputDecoration(
  "Contact email",
),
),

                    const SizedBox(
                        height: 16),

                    /// PHONE
TextFormField(
  controller: phoneController,

  autovalidateMode:
      AutovalidateMode.onUserInteraction,

  validator: Validators.phone,

  style: const TextStyle(
    color: Colors.white,
  ),

decoration:
    AdminStyles.inputDecoration(
  "Contact phone",
),
),

                    const SizedBox(
                        height: 16),

                    /// DESCRIPTION
                    TextField(
                      controller:
                          descriptionController,
                      maxLines: 4,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                   decoration:
    AdminStyles.inputDecoration(
  "Description",
),
                    ),
                  ],
                ),
              ),
            ),
            ),
            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(
                      context);
                },
                style: AdminStyles.cancelButton,
                child:
                    const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!
    .validate()) {
  return;
}
                  try {
                    final auth =
                        context.read<
                            AuthProvider>();

                    final body = {
                      "name":
                          nameController
                              .text,
                      "address":
                          addressController
                              .text,
                      "cityId":
                          selectedCityId,
                      "contactEmail":
                          emailController
                              .text,
                      "contactPhone":
                          phoneController
                              .text,
                      "description":
                          descriptionController
                              .text,
                    };

                    if (facility ==
                        null) {
                      await auth
                          .facilityService
                          .insert(body);
                    } else {
                      await auth
                          .facilityService
                          .update(
                        facility.id,
                        body,
                      );
                    }

                    Navigator.pop(
                      context,
                      true,
                    );
                 } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
                },
                style: AdminStyles.primaryButton,
                child:
                    const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
    await _loadFacilities();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            facility == null
                ? "Facility added successfully"
                : "Facility updated successfully",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    }
  }
}

Future<void> _deleteFacility(
  Facility facility,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (_) {
    return ConfirmDeleteDialog(
  title: "Delete facility",

  message:
      "Are you sure you want to delete ${facility.name}?",
);
    },
  );

  if (confirmed == true) {
    try {
      final auth =
          context.read<AuthProvider>();

      await auth.facilityService
          .delete(facility.id);

      await _loadFacilities();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Facility deleted successfully",
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot delete facility because it is in use.",
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
    }
  }
}

Future<void> _showSpaceTypeDialog({
  SpaceType? type,
}) async {

  final formKey = GlobalKey<FormState>();

  final controller =
      TextEditingController(
    text: type?.name ?? "",
  );

  final result =
      await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor:
            AdminStyles.cardColor,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
                  20),
        ),
        title: Text(
          type == null
              ? "Add space type"
              : "Edit space type",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
content: SizedBox(
  width: 400,
  child: Form(
    key: formKey,
    child: TextFormField(
      controller: controller,

      autovalidateMode:
          AutovalidateMode.onUserInteraction,

      validator: (value) =>
          Validators.required(
        value,
        "Space type name",
      ),

      style: const TextStyle(
        color: Colors.white,
      ),

     decoration:
    AdminStyles.inputDecoration(
  "Space type name",
),
    ),
  ),
),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(
                  context);
            },
           style: AdminStyles.cancelButton,
            child:
                const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!
    .validate()) {
  return;
}
              try {
                final auth =
                    context.read<
                        AuthProvider>();

                final body = {
                  "name":
                      controller.text,
                };

                if (type == null) {
                  await auth
                      .spaceTypeService
                      .insert(body);
                } else {
                  await auth
                      .spaceTypeService
                      .update(
                    type.id,
                    body,
                  );
                }

                Navigator.pop(
                  context,
                  true,
                );
            } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
            },
           style: AdminStyles.primaryButton,
            child:
                const Text("Save"),
          ),
        ],
      );
    },
  );

  if (result == true) {
    await _loadSpaceTypes();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            type == null
                ? "Space type added successfully"
                : "Space type updated successfully",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    }
  }
}

Future<void> _deleteSpaceType(
  SpaceType type,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (_) {
     return ConfirmDeleteDialog(
  title: "Delete space type",

  message:
      "Are you sure you want to delete ${type.name}?",
);
    },
  );

  if (confirmed == true) {
    try {
      final auth =
          context.read<AuthProvider>();

      await auth.spaceTypeService
          .delete(type.id);

      await _loadSpaceTypes();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Space type deleted successfully",
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot delete space type because it is in use.",
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
    }
  }
}

  Future<void> _loadCountries() async {
  try {
    setState(() {
      _isLoadingCountries = true;
    });

    final auth =
        context.read<AuthProvider>();

    final result =
        await auth.countryService.getPaged(
      page: _countryPage,
      pageSize: _countryPageSize,
      name: _countrySearch,
    );

    final items = result["items"] as List;

    setState(() {
      _countries = items
          .map((e) => Country.fromJson(e))
          .toList();

      _countryTotalPages =
          result["totalPages"] ?? 1;

      _isLoadingCountries = false;
    });
  } catch (e) {

    setState(() {
      _isLoadingCountries = false;
    });
  }
}

Future<void> _loadCities() async {
  try {
    setState(() {
      _isLoadingCities = true;
    });

    final auth =
        context.read<AuthProvider>();

    final result =
        await auth.cityService.getPaged(
      page: _cityPage,
      pageSize: _cityPageSize,
      name: _citySearch,
    );

    final items = result["items"] as List;

    setState(() {
      _cities = items
          .map((e) => City.fromJson(e))
          .toList();

      _cityTotalPages =
          result["totalPages"] ?? 1;

      _isLoadingCities = false;
    });
  } catch (e) {

    setState(() {
      _isLoadingCities = false;
    });
  }
}

Future<void> _loadFacilities() async {
  try {
    setState(() {
      _isLoadingFacilities = true;
    });

    final auth =
        context.read<AuthProvider>();

    final result =
        await auth.facilityService.getPaged(
      page: _facilityPage,
      pageSize: _facilityPageSize,
      name: _facilitySearch,
    );

    final items = result["items"] as List;

    setState(() {
      _facilities = items
          .map((e) =>
              Facility.fromJson(e))
          .toList();

      _facilityTotalPages =
          result["totalPages"] ?? 1;

      _isLoadingFacilities = false;
    });
  } catch (e) {

    setState(() {
      _isLoadingFacilities = false;
    });
  }
}

Future<void> _loadSpaceTypes() async {
  try {
    setState(() {
      _isLoadingSpaceTypes = true;
    });

    final auth =
        context.read<AuthProvider>();

    final result = await auth
        .spaceTypeService
        .getPaged(
      page: _spaceTypePage,
      pageSize:
          _spaceTypePageSize,
      name: _spaceTypeSearch,
    );

    final items =
        result["items"] as List;

    setState(() {
      _spaceTypes = items
          .map((e) =>
              SpaceType.fromJson(e))
          .toList();

      _spaceTypeTotalPages =
          result["totalPages"] ?? 1;

      _isLoadingSpaceTypes =
          false;
    });
  } catch (e) {

    setState(() {
      _isLoadingSpaceTypes =
          false;
    });
  }
}
}