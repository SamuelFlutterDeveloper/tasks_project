import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_project/pages/analytics_servies.dart';
import 'package:tasks_project/pages/property/model/property_model.dart';
import 'package:tasks_project/pages/property/screen/property_details_page.dart';
import 'package:tasks_project/pages/property/screen/property_filter_page.dart';
import 'package:tasks_project/provider/property_provider.dart';

class PropertiyListPage extends StatefulWidget {
  const PropertiyListPage({super.key});

  @override
  State<PropertiyListPage> createState() => _PropertiyListPageState();
}

class _PropertiyListPageState extends State<PropertiyListPage> {
  TextEditingController searchController = TextEditingController();
  Timer? _searchTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
      AnalyticsService.instance.trackPageView('property_list');
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchTimer?.cancel();
    AnalyticsService.instance.trackPageEnd('property_list');
    super.dispose();
  }

  Future<void> _loadProperties({bool loadMore = false}) async {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    await provider.fetchProperties(loadMore: loadMore);

    if (_isInitialLoad) {
      _isInitialLoad = false;
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange) {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      if (provider.hasMore && !provider.isMoreLoading) {
        AnalyticsService.instance.trackInteraction(
          interactionType: 'scroll_near_end',
          element: 'scroll_listener',
        );
        _loadProperties(loadMore: true);
      }
    }
  }

  void _onSearchChanged(String value) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        provider.setSearchQuery(value.trim());
        AnalyticsService.instance.trackSearch(
          value.trim(),
          provider.propertyList.length,
        );
      } else {
        provider.setSearchQuery(null);
      }
      _loadProperties();
    });
  }

  void _clearSearch() {
    searchController.clear();
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.setSearchQuery(null);
    _loadProperties();
  }

  void _clearFilters() {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.clearFilters();
    _loadProperties();
  }

  Widget _buildPropertyCard(Property item, bool isWeb, bool isTablet) {
    return InkWell(
      onTap: () {
        AnalyticsService.instance.trackInteraction(
          interactionType: 'property_card_tap',
          propertyId: item.id,
          element: 'property_card',
          extraData: {
            'propertyTitle': item.title,
            'price': item.price,
            'city': item.location.city,
          },
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsPage(property: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                item.images.isNotEmpty
                    ? item.images.first
                    : "https://via.placeholder.com/150",
                height: isWeb
                    ? 150
                    : isTablet
                    ? 180
                    : 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: isWeb
                        ? 150
                        : isTablet
                        ? 180
                        : 200,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isWeb
                        ? 150
                        : isTablet
                        ? 180
                        : 200,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.home_work,
                      size: 60,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWeb
                            ? 14
                            : isTablet
                            ? 15
                            : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: isWeb ? 14 : 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: isWeb
                                  ? 12
                                  : isTablet
                                  ? 13
                                  : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.currency} ${item.price}",
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.bed,
                              size: isWeb ? 14 : 16,
                              color: Colors.grey,
                            ),
                            Text(
                              ' ${item.bedrooms}',
                              style: TextStyle(
                                fontSize: isWeb ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bathtub,
                              size: isWeb ? 14 : 16,
                              color: Colors.grey,
                            ),
                            Text(
                              ' ${item.bathrooms}',
                              style: TextStyle(
                                fontSize: isWeb ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadMoreTrigger() {
    return GestureDetector(
      onTap: () => _loadProperties(loadMore: true),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue[700], size: 32),
            const SizedBox(height: 8),
            Text(
              'Load More Properties',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfList() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'All properties loaded',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPropertiesFound() {
    final provider = Provider.of<PropertyProvider>(context);
    final hasFilters =
        provider.currentFilters.isNotEmpty ||
        provider.currentSearchQuery != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            hasFilters
                ? "No Properties Match Your Filters"
                : "No Properties Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? "Try adjusting your filters or search criteria"
                : "Try searching for something else",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final provider = Provider.of<PropertyProvider>(context);
    if (provider.currentFilters.isEmpty) return const SizedBox();

    final chips = <Widget>[];

    if (provider.currentFilters.containsKey('min_price') &&
        provider.currentFilters.containsKey('max_price')) {
      chips.add(
        Chip(
          label: Text(
            'Price: ${provider.currentFilters['min_price']} - ${provider.currentFilters['max_price']}',
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            final newFilters = Map<String, dynamic>.from(
              provider.currentFilters,
            );
            newFilters.remove('min_price');
            newFilters.remove('max_price');
            provider.setFilters(newFilters);
            _loadProperties();
          },
        ),
      );
    }

    if (provider.currentFilters.containsKey('location')) {
      chips.add(
        Chip(
          label: Text('City: ${provider.currentFilters['location']}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            final newFilters = Map<String, dynamic>.from(
              provider.currentFilters,
            );
            newFilters.remove('location');
            provider.setFilters(newFilters);
            _loadProperties();
          },
        ),
      );
    }

    if (provider.currentFilters.containsKey('status')) {
      chips.add(
        Chip(
          label: Text('Status: ${provider.currentFilters['status']}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            final newFilters = Map<String, dynamic>.from(
              provider.currentFilters,
            );
            newFilters.remove('status');
            provider.setFilters(newFilters);
            _loadProperties();
          },
        ),
      );
    }

    if (provider.currentFilters.containsKey('tags')) {
      final tags = provider.currentFilters['tags'] as List;
      chips.add(
        Chip(
          label: Text('Tags: ${tags.join(', ')}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            final newFilters = Map<String, dynamic>.from(
              provider.currentFilters,
            );
            newFilters.remove('tags');
            provider.setFilters(newFilters);
            _loadProperties();
          },
        ),
      );
    }

    if (provider.currentSearchQuery != null) {
      chips.add(
        Chip(
          label: Text('Search: ${provider.currentSearchQuery}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            _clearSearch();
          },
        ),
      );
    }

    if (chips.isNotEmpty) {
      chips.add(
        Chip(
          label: const Text('Clear All'),
          avatar: const Icon(Icons.clear_all, size: 16),
          onDeleted: _clearFilters,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PropertyProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final isWeb = screenWidth > 900;

    int gridCount = 1;
    if (isTablet) gridCount = 2;
    if (isWeb) gridCount = 4;

    double cardWidth = (screenWidth / gridCount) - 40;
    double cardHeight = screenHeight * 0.40;
    double dynamicAspectRatio = cardWidth / cardHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Properties"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              AnalyticsService.instance.trackInteraction(
                interactionType: 'filter_button_click',
                element: 'app_bar_filter',
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PropertyFilterPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalyticsReport,
            tooltip: 'View Analytics',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search properties...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProperties(),
        child: Column(
          children: [
            // Active filters chips
            _buildFilterChips(),

            // Properties Grid
            Expanded(
              child: provider.isLoading && provider.propertyList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.propertyList.isEmpty
                  ? _buildNoPropertiesFound()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          if (!provider.isMoreLoading && provider.hasMore) {
                            _loadProperties(loadMore: true);
                          }
                        }
                        return false;
                      },
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: dynamicAspectRatio,
                        ),
                        itemCount:
                            provider.propertyList.length +
                            (provider.isMoreLoading ? 1 : 0) +
                            (provider.hasMore && !provider.isMoreLoading
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          // Loading indicator at the end
                          if (index >= provider.propertyList.length) {
                            if (index == provider.propertyList.length &&
                                provider.isMoreLoading) {
                              return _buildLoadingIndicator();
                            }

                            if (!provider.hasMore &&
                                provider.propertyList.isNotEmpty) {
                              return _buildEndOfList();
                            }

                            if (provider.hasMore && !provider.isMoreLoading) {
                              return _buildLoadMoreTrigger();
                            }

                            return const SizedBox.shrink();
                          }

                          final item = provider.propertyList[index];
                          return _buildPropertyCard(item, isWeb, isTablet);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalyticsReport() async {
    final report = await AnalyticsService.instance.getMostViewedProperties();
    final pageReport = await AnalyticsService.instance.getPageAnalytics();
    final interactionReport = await AnalyticsService.instance
        .getInteractionAnalytics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Analytics Report'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportSection('📊 Most Viewed Properties', report),
              const Divider(),
              _buildReportSection('📈 Page Analytics', pageReport),
              const Divider(),
              _buildReportSection('🖱️ User Interactions', interactionReport),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              AnalyticsService.instance.exportAnalytics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics exported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export Data'),
          ),
          TextButton(
            onPressed: () async {
              await AnalyticsService.instance.clearAnalytics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics data cleared!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Clear Data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(String title, Map<String, dynamic> data) {
    Widget content = const SizedBox();

    if (title.contains('Most Viewed')) {
      final topProperties = data['topProperties'] as List;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Properties Viewed: ${data['totalProperties']}'),
          Text('Total Views: ${data['totalViews']}'),
          const SizedBox(height: 12),
          if (topProperties.isNotEmpty)
            ...topProperties.map((property) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${property['viewCount']}'),
                ),
                title: Text(
                  property['propertyTitle'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Views: ${property['viewCount']} • '
                  'Avg: ${property['avgDurationFormatted']}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  'ID: ${property['propertyId']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            }).toList()
          else
            const Text('No property views yet'),
        ],
      );
    } else if (title.contains('Page Analytics')) {
      final pageStats = data['pageStats'] as List;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Pages: ${data['totalPages']}'),
          Text('Total Page Views: ${data['totalPageViews']}'),
          const SizedBox(height: 12),
          if (pageStats.isNotEmpty)
            ...pageStats.map((page) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pageview, size: 24),
                title: Text(
                  page['pageName'],
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Views: ${page['count']} • '
                  'Avg: ${page['avgDurationFormatted']}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  'Last: ${_formatDate(page['lastVisit'])}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            }).toList()
          else
            const Text('No page views yet'),
        ],
      );
    } else if (title.contains('User Interactions')) {
      final interactions = data['interactions'] as List;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Interactions: ${data['totalInteractions']}'),
          const SizedBox(height: 12),
          if (interactions.isNotEmpty)
            ...interactions.map((interaction) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text('${interaction['count']}'),
                  radius: 16,
                ),
                title: Text(
                  interaction['type'],
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Element: ${interaction['element'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  'Count: ${interaction['count']}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList()
          else
            const Text('No interactions yet'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Never';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid';
    }
  }
}
