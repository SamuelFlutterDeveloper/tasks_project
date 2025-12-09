import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tasks_project/pages/analytics_servies.dart';
import 'package:tasks_project/pages/property/model/property_model.dart';
import 'package:tasks_project/util/image_file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Property property;

  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // Track page view with property ID
    AnalyticsService.instance.trackPageView(
      'property_details',
      propertyId: widget.property.id,
    );

    // Track property view start
    AnalyticsService.instance.trackPropertyView(
      widget.property.id,
      widget.property.title,
    );
  }

  @override
  void dispose() {
    
    AnalyticsService.instance.trackPageEnd('property_details');

   
    AnalyticsService.instance.trackPropertyViewEnd(widget.property.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
       
          SliverAppBar(
            expandedHeight: isWeb
                ? 450
                : isTablet
                ? 350
                : 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _PropertyImagesGallery(
                images: widget.property.images,
                isWeb: isWeb,
                isTablet: isTablet,
              ),
            ),
            leading: IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.favorite_border, color: Colors.black),
                ),
                onPressed: () {
                  AnalyticsService.instance.trackInteraction(
                    interactionType: 'favorite',
                    propertyId: widget.property.id,
                    element: 'favorite_button',
                    extraData: {'propertyTitle': widget.property.title},
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Property Details
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb
                    ? 40
                    : isTablet
                    ? 24
                    : 16,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.property.currency} ${widget.property.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isWeb
                                    ? 28
                                    : isTablet
                                    ? 24
                                    : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.property.title,
                              style: TextStyle(
                                fontSize: isWeb
                                    ? 20
                                    : isTablet
                                    ? 18
                                    : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWeb || isTablet)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.property.status == 'Available'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.property.status == 'Available'
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Text(
                            widget.property.status,
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                              fontWeight: FontWeight.w500,
                              color: widget.property.status == 'Available'
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isWeb ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.property.location.address}, ${widget.property.location.city}, ${widget.property.location.state} ${widget.property.location.zip}',
                          style: TextStyle(
                            fontSize: isWeb ? 15 : 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Property Features
                  _PropertyFeaturesRow(
                    bedrooms: widget.property.bedrooms,
                    bathrooms: widget.property.bathrooms,
                    area: widget.property.areaSqFt,
                    isWeb: isWeb,
                    isTablet: isTablet,
                  ),

                  const SizedBox(height: 32),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.property.description,
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tags
                  if (widget.property.tags.isNotEmpty) ...[
                    Text(
                      'Features',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.property.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Agent Information
                  _AgentCard(
                    agent: widget.property.agent,
                    isWeb: isWeb,
                    isTablet: isTablet,
                    propertyId: widget.property.id,
                  ),

                  const SizedBox(height: 20),

                  // File Upload Section
                  UniversalFilePicker(
                    title: "Upload Property Documents",
                    propertyId: widget.property.id,
                    enableUpload: true,
                    onFilesSelected: (files) {
                      AnalyticsService.instance.trackInteraction(
                        interactionType: 'file_selected',
                        propertyId: widget.property.id,
                        element: 'file_picker',
                        extraData: {
                          'fileCount': files.length,
                          'propertyTitle': widget.property.title,
                        },
                      );
                      setState(() {
                        _selectedImages = files;
                      });
                      print("Selected ${files.length} files");
                    },
                    // FIX: Added the 'fileNames' argument to the callback signature.
                    onFilesSelectedWeb: (filesBytes, fileNames) {
                      AnalyticsService.instance.trackInteraction(
                        interactionType: 'file_selected_web',
                        propertyId: widget.property.id,
                        element: 'file_picker_web',
                        extraData: {
                          'fileCount': filesBytes.length,
                          'propertyTitle': widget.property.title,
                          'fileNames': fileNames.join(
                            ', ',
                          ), // Optional: use file names in analytics
                        },
                      );
                      setState(() {
                        // You should handle the web selected files (Uint8List) here if needed
                        // e.g., _selectedWebFileBytes = filesBytes;
                      });
                      print("Selected ${filesBytes.length} files on web");
                    },
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons for Mobile
                  if (!isWeb) _MobileActionButtons(property: widget.property),

                  // Spacer for web/tablet layout
                  if (isWeb || isTablet) const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar for Web/Tablet
      bottomNavigationBar: (isWeb || isTablet)
          ? Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 40 : 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isWeb) const Spacer(),
                  Expanded(
                    flex: isWeb ? 2 : 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 40 : 24,
                      ),
                      child: _WebActionButtons(
                        isWeb: isWeb,
                        property: widget.property,
                      ),
                    ),
                  ),
                  if (!isWeb) const Spacer(),
                ],
              ),
            )
          : null,
    );
  }
}

class _PropertyImagesGallery extends StatelessWidget {
  final List<String> images;
  final bool isWeb;
  final bool isTablet;

  const _PropertyImagesGallery({
    required this.images,
    required this.isWeb,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.home_work, size: 100, color: Colors.grey),
        ),
      );
    }

    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
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
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}

class _PropertyFeaturesRow extends StatelessWidget {
  final int bedrooms;
  final int bathrooms;
  final int area;
  final bool isWeb;
  final bool isTablet;

  const _PropertyFeaturesRow({
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.isWeb,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final featureItems = [
      _FeatureItem(
        icon: Icons.bed,
        value: '$bedrooms',
        label: 'Bedrooms',
        isWeb: isWeb,
        isTablet: isTablet,
      ),
      _FeatureItem(
        icon: Icons.bathtub,
        value: '$bathrooms',
        label: 'Bathrooms',
        isWeb: isWeb,
        isTablet: isTablet,
      ),
      _FeatureItem(
        icon: Icons.square_foot,
        value: '$area',
        label: 'Sq Ft',
        isWeb: isWeb,
        isTablet: isTablet,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: featureItems,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isWeb;
  final bool isTablet;

  const _FeatureItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isWeb,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: isWeb ? 28 : 24, color: Colors.blue[700]),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: isWeb ? 14 : 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  final bool isWeb;
  final bool isTablet;
  final String propertyId;

  const _AgentCard({
    required this.agent,
    required this.isWeb,
    required this.isTablet,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Agent',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: isWeb ? 70 : 60,
                height: isWeb ? 70 : 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: isWeb ? 32 : 28,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.email,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.contact,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isWeb || isTablet) ...[
            const SizedBox(height: 20),
            _WebActionButtons(
              isWeb: isWeb,
              property: Property(
                id: propertyId,
                title: '',
                description: '',
                price: 0,
                currency: '',
                bedrooms: 0,
                bathrooms: 0,
                areaSqFt: 0,
                status: '',
                images: [],
                tags: [],
                agent: agent,
                location: LocationModel(
                  address: '',
                  city: '',
                  country: '',
                  latitude: 0,
                  longitude: 0,
                  state: '',
                  zip: '',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WebActionButtons extends StatelessWidget {
  final bool isWeb;
  final Property property;

  const _WebActionButtons({required this.isWeb, required this.property});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              AnalyticsService.instance.trackInteraction(
                interactionType: 'call_agent',
                propertyId: property.id,
                element: 'call_button_web',
                extraData: {
                  'agentName': property.agent.name,
                  'phone': property.agent.contact,
                },
              );
              launchUrl(Uri.parse('tel:${property.agent.contact}'));
            },
            icon: const Icon(Icons.call, size: 20),
            label: Text(
              'Call',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              AnalyticsService.instance.trackInteraction(
                interactionType: 'message_agent',
                propertyId: property.id,
                element: 'message_button_web',
                extraData: {'agentEmail': property.agent.email},
              );
              launchUrl(Uri.parse('mailto:${property.agent.email}'));
            },
            icon: const Icon(Icons.message, size: 20),
            label: Text(
              'Message Agent',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileActionButtons extends StatelessWidget {
  final Property property;

  const _MobileActionButtons({required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            AnalyticsService.instance.trackInteraction(
              interactionType: 'call_agent',
              propertyId: property.id,
              element: 'call_button_mobile',
              extraData: {
                'agentName': property.agent.name,
                'phone': property.agent.contact,
              },
            );
            launchUrl(Uri.parse('tel:${property.agent.contact}'));
          },
          icon: const Icon(Icons.call, size: 20),
          label: const Text(
            'Call Agent',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[700],
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.shade300),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            AnalyticsService.instance.trackInteraction(
              interactionType: 'message_agent',
              propertyId: property.id,
              element: 'message_button_mobile',
              extraData: {'agentEmail': property.agent.email},
            );
            launchUrl(Uri.parse('mailto:${property.agent.email}'));
          },
          icon: const Icon(Icons.message, size: 20),
          label: const Text(
            'Message Agent',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
