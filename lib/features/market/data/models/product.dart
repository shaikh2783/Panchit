import 'package:equatable/equatable.dart';

/// Product Model - نموذج المنتج
/// 
/// يمثل منتج في السوق مع جميع تفاصيله.
/// المنتجات هي منشورات من نوع 'product' في نظام Panchit.
/// 
/// الاستخدام:
/// ```dart
/// final product = Product.fromJson(json);
/// print('${product.name} - ${product.price} ${product.currency}');
/// print('الحالة: ${product.conditionDisplay}');
/// print('البائع: ${product.seller.userName}');
/// print('الكمية المتوفرة: ${product.quantity}');
/// print('نوع: ${product.isDigital ? "رقمي" : "فيزيائي"}');
/// ```
/// 
/// Properties:
/// - [productId]: معرف المنتج (post_id)
/// - [name]: اسم المنتج
/// - [price]: السعر
/// - [description]: وصف المنتج
/// - [condition]: حالة المنتج (new, like_new, excellent, good, fair, poor)
/// - [location]: موقع المنتج
/// - [categoryId]: معرف الفئة
/// - [categoryName]: اسم الفئة
/// - [photos]: صور المنتج
/// - [seller]: معلومات البائع
/// - [status]: حالة المنتج (available, sold, unavailable)
/// - [quantity]: الكمية المتوفرة في المخزون
/// - [isDigital]: هل المنتج رقمي أم فيزيائي
/// 
/// See also:
/// - [ProductSeller]: معلومات البائع
/// - [ProductCategory]: فئة المنتج
class Product extends Equatable {
  final String productId;
  final String name;
  final String price;
  final String currency;
  final String description;
  final String condition; // new, like_new, excellent, good, fair, poor
  final String location;
  final int categoryId;
  final String categoryName;
  final List<String> photos;
  final ProductSeller seller;
  final String status; // available, sold, unavailable
  final DateTime createdAt;
  final int views;
  final bool isFavorite;
  final int quantity; // الكمية المتوفرة
  final bool isDigital; // منتج رقمي أو فيزيائي

    const Product({
    required this.productId,
    required this.name,
    required this.price,
    this.currency = 'USD',
    required this.description,
    required this.condition,
    required this.location,
    required this.categoryId,
    required this.categoryName,
    required this.photos,
    required this.seller,
    required this.status,
    required this.createdAt,
    this.views = 0,
    this.isFavorite = false,
    this.quantity = 0,
    this.isDigital = false,
  });

  @override
  List<Object?> get props => [
    productId,
    name,
    price,
    currency,
    description,
    condition,
    location,
    categoryId,
    categoryName,
    photos,
    seller,
    status,
    createdAt,
    views,
    isFavorite,
    quantity,
    isDigital,
  ];

  /// Creates Product from JSON response
  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle photos array - check multiple possible field names
    List<String> photosList = [];
    
    // Try different possible field names for photos
    final photosData = json['images'] ??  // Main field from API
                      json['photos'] ?? 
                      json['album_pictures'] ?? 
                      json['product_pictures'] ?? 
                      json['pictures'];
    
    if (photosData != null) {
      if (photosData is List) {
        photosList = photosData
            .map((photo) {
              // Handle if photo is an object with 'source' or 'image' field
              if (photo is Map) {
                return photo['source']?.toString() ?? 
                       photo['image']?.toString() ?? 
                       photo['url']?.toString() ?? 
                       photo.toString();
              }
              return photo.toString();
            })
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (photosData is String && photosData.isNotEmpty) {
        photosList = [photosData.toString()];
      }
    }
    
    // Also check for single photo field
    if (photosList.isEmpty && json['photo'] != null) {
      photosList = [json['photo'].toString()];
    }
    
    // Also check product_picture field
    if (photosList.isEmpty && json['product_picture'] != null) {
      photosList = [json['product_picture'].toString()];
    }

    // Parse created_at
    DateTime createdTime;
    try {
      createdTime = DateTime.parse(json['time'] ?? json['created_at']);
    } catch (e) {
      createdTime = DateTime.now();
    }

    return Product(
      productId: json['post_id']?.toString() ?? json['product_id']?.toString() ?? '',
      name: json['product_name']?.toString() ?? json['name']?.toString() ?? '',
      price: json['product_price']?.toString() ?? json['price']?.toString() ?? '0',
      currency: json['product_currency']?.toString() ?? json['currency']?.toString() ?? 'USD',
      description: json['text']?.toString() ?? json['description']?.toString() ?? '',
      condition: json['product_condition']?.toString() ?? json['condition']?.toString() ?? json['status']?.toString() ?? 'good',
      location: json['product_location']?.toString() ?? json['location']?.toString() ?? '',
      categoryId: int.parse(json['product_category']?.toString() ?? json['category_id']?.toString() ?? '0'),
      categoryName: json['category_name']?.toString() ?? '',
      photos: photosList,
      seller: ProductSeller.fromJson(json['author'] ?? json['seller'] ?? {}),
      status: json['available'] == '1' || json['available'] == 1 ? 'available' : 'unavailable',
      createdAt: createdTime,
      views: int.parse(json['views']?.toString() ?? '0'),
      isFavorite: json['i_save'] == true || json['i_save'] == '1',
      quantity: int.parse(json['quantity']?.toString() ?? '0'),
      isDigital: json['is_digital'] == true || json['is_digital'] == '1' || json['is_digital'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': name,
      'product_price': price,
      'product_currency': currency,
      'description': description,
      'product_condition': condition,
      'product_location': location,
      'product_category': categoryId,
      'category_name': categoryName,
      'photos': photos,
      'seller': seller.toJson(),
      'product_status': status,
      'created_at': createdAt.toIso8601String(),
      'views': views,
      'is_favorite': isFavorite,
      'quantity': quantity,
      'is_digital': isDigital,
    };
  }

  /// Product condition display in Arabic
  String get conditionDisplay {
    switch (condition) {
      case 'new':
        return 'جديد';
      case 'like_new':
        return 'كالجديد';
      case 'excellent':
        return 'ممتاز';
      case 'good':
        return 'جيد';
      case 'fair':
        return 'مقبول';
      case 'poor':
        return 'سيء';
      default:
        return condition;
    }
  }

  /// Product status display in Arabic
  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'متاح';
      case 'sold':
        return 'تم البيع';
      case 'unavailable':
        return 'غير متاح';
      default:
        return status;
    }
  }

  /// Check if product is available for purchase
  bool get isAvailable => status == 'available' && quantity > 0;

  /// Check if product is sold
  bool get isSold => status == 'sold';

  /// Check if product is out of stock
  bool get isOutOfStock => quantity == 0;

  /// Check if product is in stock
  bool get isInStock => quantity > 0;

  /// Product type display (digital/physical)
  String get productTypeDisplay => isDigital ? 'منتج رقمي' : 'منتج فيزيائي';

  /// Get primary photo
  String get primaryPhoto => photos.isNotEmpty ? photos.first : '';

  /// Format price with currency
  String get formattedPrice => '$price $currency';

  Product copyWith({
    String? productId,
    String? name,
    String? price,
    String? currency,
    String? description,
    String? condition,
    String? location,
    int? categoryId,
    String? categoryName,
    List<String>? photos,
    ProductSeller? seller,
    String? status,
    DateTime? createdAt,
    int? views,
    bool? isFavorite,
    int? quantity,
    bool? isDigital,
  }) {
    return Product(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      photos: photos ?? this.photos,
      seller: seller ?? this.seller,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      isFavorite: isFavorite ?? this.isFavorite,
      quantity: quantity ?? this.quantity,
      isDigital: isDigital ?? this.isDigital,
    );
  }
}

/// Product Seller Model - معلومات البائع
/// 
/// معلومات البائع المرتبط بالمنتج
class ProductSeller extends Equatable {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userPicture;
  final bool verified;

  const ProductSeller({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userPicture,
    this.verified = false,
  });

  factory ProductSeller.fromJson(Map<String, dynamic> json) {
    return ProductSeller(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userFirstname: json['user_firstname']?.toString() ?? '',
      userLastname: json['user_lastname']?.toString() ?? '',
      userPicture: json['user_picture']?.toString() ?? '',
      verified: json['user_verified'] == true || json['user_verified'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_firstname': userFirstname,
      'user_lastname': userLastname,
      'user_picture': userPicture,
      'user_verified': verified,
    };
  }

  String get fullName => '$userFirstname $userLastname'.trim();

  @override
  List<Object?> get props => [
        userId,
        userName,
        userFirstname,
        userLastname,
        userPicture,
        verified,
      ];
}
