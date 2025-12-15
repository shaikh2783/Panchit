import '../data/models/offer.dart';
import '../data/models/offer_category.dart';
import '../data/services/offers_api_service.dart';
class OffersRepository {
  final OffersApiService _api;
  OffersRepository(this._api);
  Future<List<OfferCategory>> getCategories() => _api.getCategories();
  Future<Map<String, dynamic>> getOffers({int offset = 0, int limit = 20, String search = '', int? categoryId}) =>
      _api.getOffers(offset: offset, limit: limit, search: search, categoryId: categoryId);
  Future<Offer> getOfferById(int id) => _api.getOfferById(id);
  Future<Offer> createOffer(Map<String, dynamic> body) => _api.createOffer(body);
  Future<Offer> updateOffer(int id, Map<String, dynamic> body) => _api.updateOffer(id, body);
  Future<void> deleteOffer(int id) => _api.deleteOffer(id);
}
