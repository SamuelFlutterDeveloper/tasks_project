import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_project/pages/analytics_servies.dart';
import 'package:tasks_project/provider/property_provider.dart';

class PropertyFilterPage extends StatefulWidget {
  const PropertyFilterPage({super.key});

  @override
  State<PropertyFilterPage> createState() => _PropertyFilterPageState();
}

class _PropertyFilterPageState extends State<PropertyFilterPage> {
  RangeValues priceRange = const RangeValues(100000, 500000);
  String? selectedCity;
  String? selectedStatus;
  List<String> selectedTags = [];
  Timer? _filterChangeTimer;

  List<String> cityList = [];
  List<String> tagList = [];
  List<String> statusList = ["Available", "Sold", "Rented"];

  @override
  void initState() {
    super.initState();
    // Track page view
    AnalyticsService.instance.trackPageView('filter_page');

    final provider = Provider.of<PropertyProvider>(context, listen: false);

    cityList = provider.propertyList
        .map((e) => e.location.city)
        .toSet()
        .toList();

    tagList = provider.propertyList
        .expand((e) => e.tags)
        .toSet()
        .toList()
        .cast<String>();
  }

  @override
  void dispose() {
    _filterChangeTimer?.cancel();
    // Track page end
    AnalyticsService.instance.trackPageEnd('filter_page');
    super.dispose();
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return "₹${(value / 100000).toStringAsFixed(1)}L";
    } else if (value >= 1000) {
      return "₹${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return "₹${value.toStringAsFixed(0)}";
    }
  }

  void _trackFilterChange() {
    _filterChangeTimer?.cancel();
    _filterChangeTimer = Timer(const Duration(milliseconds: 300), () {
      final filters = _getCurrentFilters();
      AnalyticsService.instance.trackInteraction(
        interactionType: 'filter_change',
        element: 'filter_widget',
        extraData: {'current_filters': filters},
      );
    });
  }

  Map<String, dynamic> _getCurrentFilters() {
    return {
      "min_price": priceRange.start.toInt(),
      "max_price": priceRange.end.toInt(),
      "location": selectedCity,
      "status": selectedStatus,
      "tags": selectedTags,
    };
  }

  void _applyFilters() {
    final filters = _getCurrentFilters();

    // Track filter application
    AnalyticsService.instance.trackInteraction(
      interactionType: 'filter_apply',
      element: 'apply_button',
      extraData: filters,
    );

    // Track the complete filter action
    AnalyticsService.instance.trackFilter(filters);

    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.setFilters(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    // Track filter reset
    AnalyticsService.instance.trackInteraction(
      interactionType: 'filter_reset',
      element: 'reset_button',
      extraData: {'action': 'reset_all_filters'},
    );

    setState(() {
      priceRange = const RangeValues(100000, 500000);
      selectedCity = null;
      selectedStatus = null;
      selectedTags = [];
    });

    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.setFilters({});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Filter Properties"),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.blue),
            onPressed: () {
              AnalyticsService.instance.trackInteraction(
                interactionType: 'analytics_button_click',
                element: 'filter_page_analytics',
              );
              // You can show filter analytics here if needed
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Analytics'),
                  content: Text(
                    'Current Filters:\n'
                    'Price Range: ${_formatCurrency(priceRange.start)} - ${_formatCurrency(priceRange.end)}\n'
                    'City: ${selectedCity ?? "Not selected"}\n'
                    'Status: ${selectedStatus ?? "Not selected"}\n'
                    'Tags: ${selectedTags.isEmpty ? "None" : selectedTags.join(", ")}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 900;
          final isTablet =
              constraints.maxWidth > 600 && constraints.maxWidth <= 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWeb
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _priceRangeCard(),
                            const SizedBox(height: 20),
                            _cityDropdownCard(),
                            const SizedBox(height: 20),
                            _statusDropdownCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(flex: 1, child: _tagsCard()),
                    ],
                  )
                : Column(
                    children: [
                      _priceRangeCard(),
                      const SizedBox(height: 20),
                      _cityDropdownCard(),
                      const SizedBox(height: 20),
                      _statusDropdownCard(),
                      const SizedBox(height: 20),
                      _tagsCard(),
                    ],
                  ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _applyFilters,
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _resetFilters,
                child: const Text("Reset", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Widgets --------------------
  Widget _priceRangeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Price Range",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_formatCurrency(priceRange.start)} - ${_formatCurrency(priceRange.end)}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: priceRange,
              min: 0,
              max: 1000000,
              divisions: 20,
              onChanged: (values) {
                setState(() {
                  priceRange = values;
                });
                _trackFilterChange();
              },
              onChangeEnd: (values) {
                // Track final price range selection
                AnalyticsService.instance.trackInteraction(
                  interactionType: 'price_range_selected',
                  element: 'price_slider',
                  extraData: {
                    'min_price': values.start.toInt(),
                    'max_price': values.end.toInt(),
                    'min_formatted': _formatCurrency(values.start),
                    'max_formatted': _formatCurrency(values.end),
                  },
                );
              },
              labels: RangeLabels(
                _formatCurrency(priceRange.start),
                _formatCurrency(priceRange.end),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(0),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  _formatCurrency(1000000),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityDropdownCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "City",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              isExpanded: true,
              hint: const Text("Select City"),
              value: selectedCity,
              items: cityList
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
                _trackFilterChange();

                // Track city selection
                AnalyticsService.instance.trackInteraction(
                  interactionType: 'city_selected',
                  element: 'city_dropdown',
                  extraData: {'selected_city': value},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdownCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              isExpanded: true,
              hint: const Text("Select Status"),
              value: selectedStatus,
              items: statusList
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
                _trackFilterChange();

                // Track status selection
                AnalyticsService.instance.trackInteraction(
                  interactionType: 'status_selected',
                  element: 'status_dropdown',
                  extraData: {'selected_status': value},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tags",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select one or more tags",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tagList.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                    _trackFilterChange();

                    // Track tag selection
                    AnalyticsService.instance.trackInteraction(
                      interactionType: selected
                          ? 'tag_selected'
                          : 'tag_deselected',
                      element: 'tag_chip',
                      extraData: {
                        'tag': tag,
                        'is_selected': selected,
                        'total_selected_tags': selectedTags.length,
                      },
                    );
                  },
                  showCheckmark: true,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
