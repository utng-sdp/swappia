import 'package:flutter/material.dart';
import '../../core/services/postal_code_service.dart';

/// Selector en cascada de ubicación mexicana impulsado por API de Códigos Postales:
/// 1. Lista desplegable de Código Postal (C.P.)
/// 2. Lista desplegable de Municipio (autollenado desde la API del C.P.)
/// 3. Lista desplegable de Colonia / Comunidad (autollenado desde la API del C.P.)
class PostalCodeLocationSelector extends StatefulWidget {
  final PostalCodeService? postalCodeService;
  final String? initialCodigoPostal;
  final String? initialMunicipio;
  final String? initialColonia;
  final void Function({
    String? codigoPostal,
    String? municipio,
    String? colonia,
  }) onLocationChanged;
  final bool isRequired;
  final bool compact;
  final Key? cpDropdownKey;
  final Key? municipioDropdownKey;
  final Key? coloniaDropdownKey;
  final String? cpLabel;
  final String? municipioLabel;
  final String? coloniaLabel;

  const PostalCodeLocationSelector({
    super.key,
    this.postalCodeService,
    this.initialCodigoPostal,
    this.initialMunicipio,
    this.initialColonia,
    required this.onLocationChanged,
    this.isRequired = true,
    this.compact = false,
    this.cpDropdownKey,
    this.municipioDropdownKey,
    this.coloniaDropdownKey,
    this.cpLabel,
    this.municipioLabel,
    this.coloniaLabel,
  });

  @override
  State<PostalCodeLocationSelector> createState() =>
      _PostalCodeLocationSelectorState();
}

class _PostalCodeLocationSelectorState
    extends State<PostalCodeLocationSelector> {
  late final PostalCodeService _service;

  List<PostalCodeOption> _postalCodes =
      List<PostalCodeOption>.from(PostalCodeService.fallbackPostalCodes);
  List<String> _municipios = [];
  List<String> _colonias = [];

  String? _selectedCp;
  String? _selectedMunicipio;
  String? _selectedColonia;
  bool _isLoadingCpData = false;

  @override
  void initState() {
    super.initState();
    _service = widget.postalCodeService ?? PostalCodeService();
    _selectedCp = _cleanOrNull(widget.initialCodigoPostal);
    _selectedMunicipio = _cleanOrNull(widget.initialMunicipio);
    _selectedColonia = _cleanOrNull(widget.initialColonia);

    if (_selectedMunicipio != null) {
      _municipios = [_selectedMunicipio!];
    }
    if (_selectedColonia != null) {
      _colonias = [_selectedColonia!];
    }

    _loadInitialPostalCodes();
    if (_selectedCp != null) {
      _onPostalCodeSelected(_selectedCp, notifyParent: false);
    }
  }

  @override
  void didUpdateWidget(covariant PostalCodeLocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingColonia = _cleanOrNull(widget.initialColonia);
    final incomingCp = _cleanOrNull(widget.initialCodigoPostal);
    final incomingMunicipio = _cleanOrNull(widget.initialMunicipio);

    if (incomingCp != oldWidget.initialCodigoPostal &&
        incomingCp != _selectedCp) {
      _selectedCp = incomingCp;
      if (incomingCp != null) {
        _onPostalCodeSelected(incomingCp, notifyParent: false);
      } else {
        setState(() {
          _municipios = [];
          _colonias = [];
          _selectedMunicipio = null;
          _selectedColonia = null;
        });
      }
    }

    if (incomingMunicipio != oldWidget.initialMunicipio &&
        incomingMunicipio != _selectedMunicipio) {
      setState(() {
        _selectedMunicipio = incomingMunicipio;
        if (incomingMunicipio != null &&
            !_municipios.contains(incomingMunicipio)) {
          _municipios = [incomingMunicipio, ..._municipios];
        }
      });
    }

    if (incomingColonia != oldWidget.initialColonia &&
        incomingColonia != _selectedColonia) {
      setState(() {
        _selectedColonia = incomingColonia;
        if (incomingColonia != null && !_colonias.contains(incomingColonia)) {
          _colonias = [incomingColonia, ..._colonias];
        }
      });
    }
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _loadInitialPostalCodes() async {
    final codes = await _service.fetchPostalCodes();
    if (!mounted) return;
    setState(() {
      _postalCodes = codes;
    });
  }

  Future<void> _onPostalCodeSelected(
    String? cp, {
    bool notifyParent = true,
  }) async {
    if (cp == null || cp.trim().isEmpty) {
      setState(() {
        _selectedCp = null;
        _selectedMunicipio = null;
        _selectedColonia = null;
        _municipios = [];
        _colonias = [];
      });
      if (notifyParent) {
        widget.onLocationChanged(
          codigoPostal: null,
          municipio: null,
          colonia: null,
        );
      }
      return;
    }

    setState(() {
      _selectedCp = cp;
      _isLoadingCpData = true;
    });

    final info = await _service.fetchByPostalCode(cp);
    if (!mounted) return;

    final newMunicipios = List<String>.from(info.municipios);
    final newColonias = List<String>.from(info.colonias);

    final String? nextMunicipio =
        (_selectedMunicipio != null && newMunicipios.contains(_selectedMunicipio))
            ? _selectedMunicipio
            : (newMunicipios.isNotEmpty ? newMunicipios.first : null);

    final String? nextColonia =
        (_selectedColonia != null && newColonias.contains(_selectedColonia))
            ? _selectedColonia
            : (newColonias.isNotEmpty ? newColonias.first : null);

    setState(() {
      _municipios = newMunicipios;
      _colonias = newColonias;
      _selectedMunicipio = nextMunicipio;
      _selectedColonia = nextColonia;
      _isLoadingCpData = false;
    });

    if (notifyParent) {
      widget.onLocationChanged(
        codigoPostal: _selectedCp,
        municipio: _selectedMunicipio,
        colonia: _selectedColonia,
      );
    }
  }

  List<String> _safeUniqueList(List<String> source, String? currentValue) {
    final set = <String>{...source};
    if (currentValue != null && currentValue.isNotEmpty) {
      set.add(currentValue);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = widget.compact ? 8.0 : 10.0;
    final contentPadding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);

    final cpOptions = List<PostalCodeOption>.from(_postalCodes);
    if (_selectedCp != null &&
        !cpOptions.any((o) => o.codigoPostal == _selectedCp)) {
      cpOptions.insert(
        0,
        PostalCodeOption(
          codigoPostal: _selectedCp!,
          municipio: _selectedMunicipio ?? 'Dolores Hidalgo',
          estado: 'Guanajuato',
        ),
      );
    }

    final municipioItems = _safeUniqueList(_municipios, _selectedMunicipio);
    final coloniaItems = _safeUniqueList(_colonias, _selectedColonia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Dropdown de Código Postal
        FormField<String>(
          validator: widget.isRequired
              ? (_) {
                  if ((_selectedCp == null || _selectedCp!.trim().isEmpty) &&
                      (_selectedColonia == null || _selectedColonia!.isEmpty)) {
                    return 'Selecciona un código postal';
                  }
                  return null;
                }
              : null,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: widget.cpLabel ??
                    (widget.isRequired ? 'Código Postal *' : 'Código Postal'),
                prefixIcon:
                    const Icon(Icons.markunread_mailbox_outlined, size: 18),
                suffixIcon: _isLoadingCpData
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                errorText: field.errorText,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: contentPadding,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: widget.cpDropdownKey,
                  value: _selectedCp,
                  hint: const Text(
                    'Selecciona tu Código Postal',
                    overflow: TextOverflow.ellipsis,
                  ),
                  isExpanded: true,
                  items: [
                    if (!widget.isRequired)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Todos los códigos postales',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ...cpOptions.map(
                      (option) => DropdownMenuItem<String>(
                        value: option.codigoPostal,
                        child: Text(
                          option.displayLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    field.didChange(value);
                    _onPostalCodeSelected(value);
                  },
                ),
              ),
            );
          },
        ),
        SizedBox(height: gap),

        // 2. Dropdown de Municipio (autollenado desde API de C.P.)
        FormField<String>(
          validator: widget.isRequired
              ? (_) {
                  if ((_selectedMunicipio == null ||
                          _selectedMunicipio!.trim().isEmpty) &&
                      (_selectedColonia == null || _selectedColonia!.isEmpty)) {
                    return 'Selecciona un municipio';
                  }
                  return null;
                }
              : null,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: widget.municipioLabel ??
                    (widget.isRequired ? 'Municipio *' : 'Municipio'),
                prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
                errorText: field.errorText,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: contentPadding,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: widget.municipioDropdownKey,
                  value: municipioItems.contains(_selectedMunicipio)
                      ? _selectedMunicipio
                      : null,
                  hint: Text(
                    _selectedCp == null
                        ? 'Se llena al elegir Código Postal'
                        : 'Selecciona un municipio',
                    overflow: TextOverflow.ellipsis,
                  ),
                  isExpanded: true,
                  items: municipioItems
                      .map(
                        (mun) => DropdownMenuItem<String>(
                          value: mun,
                          child: Text(mun, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: municipioItems.isEmpty
                      ? null
                      : (value) {
                          setState(() => _selectedMunicipio = value);
                          field.didChange(value);
                          widget.onLocationChanged(
                            codigoPostal: _selectedCp,
                            municipio: _selectedMunicipio,
                            colonia: _selectedColonia,
                          );
                        },
                ),
              ),
            );
          },
        ),
        SizedBox(height: gap),

        // 3. Dropdown de Colonia / Comunidad (autollenado desde API de C.P.)
        FormField<String>(
          validator: widget.isRequired
              ? (_) {
                  if (_selectedColonia == null ||
                      _selectedColonia!.trim().isEmpty) {
                    return 'Indique su colonia o comunidad';
                  }
                  return null;
                }
              : null,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: widget.coloniaLabel ??
                    (widget.isRequired
                        ? 'Colonia o comunidad *'
                        : 'Colonia o comunidad'),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                errorText: field.errorText,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: contentPadding,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: widget.coloniaDropdownKey,
                  value: coloniaItems.contains(_selectedColonia)
                      ? _selectedColonia
                      : null,
                  hint: Text(
                    _selectedCp == null
                        ? 'Se llena al elegir Código Postal'
                        : 'Selecciona tu colonia',
                    overflow: TextOverflow.ellipsis,
                  ),
                  isExpanded: true,
                  items: [
                    if (!widget.isRequired && coloniaItems.isNotEmpty)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Todas las colonias',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ...coloniaItems.map(
                      (col) => DropdownMenuItem<String>(
                        value: col,
                        child: Text(col, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: coloniaItems.isEmpty
                      ? null
                      : (value) {
                          setState(() => _selectedColonia = value);
                          field.didChange(value);
                          widget.onLocationChanged(
                            codigoPostal: _selectedCp,
                            municipio: _selectedMunicipio,
                            colonia: _selectedColonia,
                          );
                        },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
