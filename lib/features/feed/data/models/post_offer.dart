class PostOffer {
  PostOffer({
    required this.offerId,
    required this.title,
    this.description,
    this.categoryId,
    required this.discountType,
    this.discountPercent,
    this.discountAmount,
    this.buyX,
    this.getY,
    this.spendX,
    this.amountY,
    this.endDate,
    this.price,
    this.thumbnail,
  });
  final String offerId;
  final String title;
  final String? description;
  final String? categoryId;
  final String discountType; // discount_percent, discount_amount, buy_get_discount, spend_get_off, free_shipping
  final int? discountPercent;
  final double? discountAmount;
  final int? buyX;
  final int? getY;
  final double? spendX;
  final double? amountY;
  final String? endDate;
  final double? price;
  final String? thumbnail;
  bool get hasDiscount => discountPercent != null || discountAmount != null;
  bool get isPercentDiscount => discountType == 'discount_percent';
  bool get isAmountDiscount => discountType == 'discount_amount';
  bool get isBuyGetDiscount => discountType == 'buy_get_discount';
  bool get isSpendGetOff => discountType == 'spend_get_off';
  bool get isFreeShipping => discountType == 'free_shipping';
  factory PostOffer.fromJson(Map<String, dynamic> json) {
    return PostOffer(
      offerId: json['post_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      categoryId: json['category_id']?.toString(),
      discountType: json['discount_type'] ?? 'discount_percent',
      discountPercent: json['discount_percent'] != null 
          ? int.tryParse(json['discount_percent'].toString())
          : null,
      discountAmount: json['discount_amount'] != null
          ? double.tryParse(json['discount_amount'].toString())
          : null,
      buyX: json['buy_x'] != null
          ? int.tryParse(json['buy_x'].toString())
          : null,
      getY: json['get_y'] != null
          ? int.tryParse(json['get_y'].toString())
          : null,
      spendX: json['spend_x'] != null
          ? double.tryParse(json['spend_x'].toString())
          : null,
      amountY: json['amount_y'] != null
          ? double.tryParse(json['amount_y'].toString())
          : null,
      endDate: json['end_date'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      thumbnail: json['thumbnail'],
    );
  }
  static PostOffer? maybeFromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map<String, dynamic>) return null;
    if (json.isEmpty) return null;
    try {
      return PostOffer.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  Map<String, dynamic> toJson() {
    return {
      'post_id': offerId,
      'title': title,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      'discount_type': discountType,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (buyX != null) 'buy_x': buyX,
      if (getY != null) 'get_y': getY,
      if (spendX != null) 'spend_x': spendX,
      if (amountY != null) 'amount_y': amountY,
      if (endDate != null) 'end_date': endDate,
      if (price != null) 'price': price,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }
}
