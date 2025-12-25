import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/job.dart';
import '../models/job_currency.dart';

class JobsApiService {
  final ApiClient _client;
  JobsApiService(this._client);

  Future<List<JobCategory>> getCategories() async {
    final res = await _client.get(configCfgP('jobs_categories'));
    final list = (res['data']?['categories'] as List<dynamic>? ?? []);
    return list.map((e) => JobCategory.fromJson(e)).toList();
  }

  Future<List<JobCurrency>> getCurrencies() async {
    final res = await _client.get(configCfgP('system_currencies'));
    final list = (res['data']?['currencies'] as List<dynamic>? ?? []);
    return list.map((e) => JobCurrency.fromJson(e)).toList();
  }

  Future<List<Job>> getJobs({
    int offset = 0,
    int limit = 20,
    int? categoryId,
    String? type,
    String? payPer,
    String? location,
    int? salaryMin,
    int? salaryMax,
  }) async {
    final qp = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (payPer != null && payPer.isNotEmpty) 'pay_salary_per': payPer,
      if (location != null && location.isNotEmpty) 'location': location,
      if (salaryMin != null) 'salary_minimum': salaryMin.toString(),
      if (salaryMax != null) 'salary_maximum': salaryMax.toString(),
    };
    final res = await _client.get(configCfgP('jobs_base'), queryParameters: qp);
    final list = (res['data']?['jobs'] as List<dynamic>? ?? []);
    return list.map((e) => Job.fromJson(e)).toList();
  }

  Future<Job> getJob(int id) async {
    final res = await _client.get('${configCfgP('jobs_base')}/$id');
    return Job.fromJson(res['data']?['job'] as Map<String, dynamic>);
  }

  Future<Job> createJob(Map<String, dynamic> body) async {
    final res = await _client.post(configCfgP('jobs_base'), body: body);
    return Job.fromJson(res['data']?['job'] as Map<String, dynamic>);
  }

  Future<Job> updateJob(int id, Map<String, dynamic> body) async {
    // Prefer POST alias to avoid PUT redirects on some backends
    final res = await _client.post('${configCfgP('jobs_base')}/$id/update', body: body);
    final data = res['data'];
    if (data is Map<String, dynamic> && data['job'] is Map<String, dynamic>) {
      return Job.fromJson(data['job'] as Map<String, dynamic>);
    }
    // Some servers return only { job: { post_id } } or minimal body
    final current = await getJob(id);
    return current;
  }

  Future<bool> deleteJob(int id) async {
    final res = await _client.post('${configCfgP('jobs_base')}/$id/delete', body: {});
    // API may return 204 with empty body; ApiClient would throw, so we used POST alias.
    return res.isNotEmpty; // best effort
  }

  Future<bool> applyToJob(int id, Map<String, dynamic> body) async {
    final res = await _client.post('${configCfgP('jobs_base')}/$id/apply', body: body);
    final data = res['data'] as Map<String, dynamic>?;
    return data?['applied'] == true;
  }

  Future<Map<String, dynamic>> getCandidates(int id, {int offset = 0}) async {
    final res = await _client.get(
      '${configCfgP('jobs_base')}/$id/candidates',
      queryParameters: {'offset': offset.toString()},
    );
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }
}
