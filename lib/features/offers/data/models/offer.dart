import 'offer_author.dart';
class Offer {
  final String postId;
  final String title;
  final String description;
  final int? categoryId;
  final String? discountType;
  final double? discountPercent;
  final double? discountAmount;
  final int? buyX;
  final int? getY;
  final double? spendX;
  final double? amountY;
  final String? endDate;
  final double? price;
  final String? metaTitle;
  final String? thumbnail;
  final String createdTime;
  final OfferAuthor author;
  Offer({
    required this.postId,
    required this.title,
    required this.description,
    this.categoryId,
    this.discountType,
    this.discountPercent,
    this.discountAmount,
    this.buyX,
    this.getY,
    this.spendX,
    this.amountY,
    this.endDate,
    this.price,
    this.metaTitle,
    this.thumbnail,
    required this.createdTime,
    required this.author,
  });
  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        postId: json['post_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
        discountType: json['discount_type']?.toString(),
        discountPercent: double.tryParse(json['discount_percent']?.toString() ?? ''),
        discountAmount: double.tryParse(json['discount_amount']?.toString() ?? ''),
        buyX: int.tryParse(json['buy_x']?.toString() ?? ''),
        getY: int.tryParse(json['get_y']?.toString() ?? ''),
        spendX: double.tryParse(json['spend_x']?.toString() ?? ''),
        amountY: double.tryParse(json['amount_y']?.toString() ?? ''),
        endDate: json['end_date']?.toString(),
        price: double.tryParse(json['price']?.toString() ?? ''),
        metaTitle: json['meta_title']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
        createdTime: json['created_time']?.toString() ?? json['time']?.toString() ?? '',
        author: OfferAuthor.fromJson(json['author'] ?? {}),
      );
}
