class PropertyResponseModel {
  final dynamic error;
  final FiltersApplied? filtersApplied;
  final bool loading;
  final int page;
  final int pageSize;
  final List<Property> properties;

  PropertyResponseModel({
    required this.error,
    this.filtersApplied,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.properties,
  });

  factory PropertyResponseModel.fromJson(Map<String, dynamic> json) {
    return PropertyResponseModel(
      error: json['error'],
      filtersApplied: json['filtersApplied'] != null
          ? FiltersApplied.fromJson(json['filtersApplied'])
          : null,
      loading: json['loading'] ?? false,
      page: json['page'] ?? 1, // ✅ default 1
      pageSize: json['page_size'] ?? 20, // ✅ default 20
      properties: (json['properties'] as List? ?? [])
          .map((e) => Property.fromJson(e))
          .toList(),
    );
  }
}

class FiltersApplied {
  final String? location;
  final int? maxPrice;
  final int? minPrice;
  final String? status;
  final List<String> tags;

  FiltersApplied({
    this.location,
    this.maxPrice,
    this.minPrice,
    this.status,
    required this.tags,
  });

  factory FiltersApplied.fromJson(Map<String, dynamic> json) {
    return FiltersApplied(
      location: json['location'],
      maxPrice: json['max_price'] ?? 0, // ✅ default 0
      minPrice: json['min_price'] ?? 0, // ✅ default 0
      status: json['status'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class Property {
  final String id;
  final String title;
  final String description;
  final int price;
  final String currency;
  final int bedrooms;
  final int bathrooms;
  final int areaSqFt;
  final String status;
  final List<String> images;
  final List<String> tags;
  final Agent agent;
  final LocationModel location;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqFt,
    required this.status,
    required this.images,
    required this.tags,
    required this.agent,
    required this.location,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0, // ✅ default 0 if null
      currency: json['currency'] ?? 'USD',
      bedrooms: json['bedrooms'] ?? 0, // ✅ default 0
      bathrooms: json['bathrooms'] ?? 0, // ✅ default 0
      areaSqFt: json['areaSqFt'] ?? 0, // ✅ default 0
      status: json['status'] ?? 'Unknown',
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      agent: Agent.fromJson(json['agent'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
    );
  }
}

class Agent {
  final String name;
  final String email;
  final String contact;

  Agent({required this.name, required this.email, required this.contact});

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      name: json['name'],
      email: json['email'],
      contact: json['contact'],
    );
  }
}

class LocationModel {
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String state;
  final String zip;

  LocationModel({
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.zip,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'],
      city: json['city'],
      country: json['country'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      state: json['state'],
      zip: json['zip'],
    );
  }
}
