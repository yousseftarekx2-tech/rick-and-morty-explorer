import 'package:flutter/material.dart';
import 'package:learn_bloc/business_logic/cubit/charcters_cubit.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.availableLocations,
    required this.onApply,
  });

  final CharacterFilter initialFilter;
  final List<String> availableLocations;
  final ValueChanged<CharacterFilter> onApply;

  static Future<void> show({
    required BuildContext context,
    required CharacterFilter currentFilter,
    required List<String> availableLocations,
    required ValueChanged<CharacterFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterBottomSheet(
        initialFilter: currentFilter,
        availableLocations: availableLocations,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedStatus;
  late String? _selectedSpecies;
  late String? _selectedLocation;
  final TextEditingController _locationSearchController = TextEditingController();
  String _locationFilterText = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialFilter.status ?? 'All';
    _selectedSpecies = widget.initialFilter.species ?? 'All';
    _selectedLocation = widget.initialFilter.location ?? 'All';
    _locationSearchController.addListener(() {
      setState(() {
        _locationFilterText = _locationSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedStatus = 'All';
      _selectedSpecies = 'All';
      _selectedLocation = 'All';
      _locationSearchController.clear();
    });
  }

  void _apply() {
    final newFilter = CharacterFilter(
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      species: _selectedSpecies == 'All' ? null : _selectedSpecies,
      location: _selectedLocation == 'All' ? null : _selectedLocation,
    );
    widget.onApply(newFilter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredLocations = widget.availableLocations.where((loc) {
      if (_locationFilterText.isEmpty) return true;
      return loc.toLowerCase().contains(_locationFilterText);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Text(
                        'Filter Characters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      _buildSectionTitle('Status'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Alive', 'Dead', 'Unknown'].map((status) {
                          final isSelected = _selectedStatus == status;
                          return ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedStatus = status),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Species'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Human', 'Alien', 'Other'].map((species) {
                          final isSelected = _selectedSpecies == species;
                          return ChoiceChip(
                            label: Text(species),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedSpecies = species),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search locations...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _locationSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _locationSearchController.clear(),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Locations'),
                            selected: _selectedLocation == 'All',
                            onSelected: (_) => setState(() => _selectedLocation = 'All'),
                          ),
                          ...filteredLocations.map((loc) {
                            final isSelected = _selectedLocation == loc;
                            return ChoiceChip(
                              label: Text(loc),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedLocation = loc),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
