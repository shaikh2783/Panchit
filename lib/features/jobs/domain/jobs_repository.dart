import '../data/models/job.dart';
import '../data/services/jobs_api_service.dart';
import '../data/models/job_currency.dart';

class JobsRepository {
  final JobsApiService _api;
  JobsRepository(this._api);

  Future<List<JobCategory>> getCategories() => _api.getCategories();
  Future<List<JobCurrency>> getCurrencies() => _api.getCurrencies();
  Future<List<Job>> getJobs({
    int offset = 0,
    int limit = 20,
    int? categoryId,
    String? type,
    String? payPer,
    String? location,
    int? salaryMin,
    int? salaryMax,
  }) {
    return _api.getJobs(
      offset: offset,
      limit: limit,
      categoryId: categoryId,
      type: type,
      payPer: payPer,
      location: location,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );
  }
  Future<Job> getJob(int id) => _api.getJob(id);
  Future<Job> createJob(Map<String, dynamic> body) => _api.createJob(body);
  Future<Job> updateJob(int id, Map<String, dynamic> body) => _api.updateJob(id, body);
  Future<bool> deleteJob(int id) => _api.deleteJob(id);
  Future<bool> applyToJob(int id, Map<String, dynamic> body) => _api.applyToJob(id, body);
  Future<Map<String, dynamic>> getCandidates(int id, {int offset = 0}) => _api.getCandidates(id, offset: offset);
}
