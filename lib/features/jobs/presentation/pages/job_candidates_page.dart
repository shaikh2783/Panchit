import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/ui_constants.dart';
import '../../domain/jobs_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JobCandidatesPage extends StatefulWidget {
  final int jobId;
  const JobCandidatesPage({super.key, required this.jobId});

  @override
  State<JobCandidatesPage> createState() => _JobCandidatesPageState();
}

class _JobCandidatesPageState extends State<JobCandidatesPage> {
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _candidates = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; _offset = 0; _hasMore = true; });
    try {
      final repo = context.read<JobsRepository>();
      final res = await repo.getCandidates(widget.jobId, offset: 0);
      final list = _extractList(res);
      setState(() {
        _candidates = list;
        _loading = false;
        _hasMore = list.length >= 20; // assume default page size
        _offset = list.length;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final repo = context.read<JobsRepository>();
      final res = await repo.getCandidates(widget.jobId, offset: _offset);
      final list = _extractList(res);
      setState(() {
        _candidates.addAll(list);
        _loadingMore = false;
        _hasMore = list.length >= 20;
        _offset += list.length;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> data) {
    final keys = ['candidates', 'applicants', 'applications'];
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v.map((e) => (e as Map).cast<String, dynamic>()).toList();
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('candidates'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('${'error'.tr}: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(UI.lg, UI.lg, UI.lg, UI.xl * 2),
                    itemCount: _candidates.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: UI.md),
                    itemBuilder: (context, index) {
                      if (index >= _candidates.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final c = _candidates[index];
                      return _candidateCard(c);
                    },
                  ),
                ),
    );
  }

  Widget _candidateCard(Map<String, dynamic> c) {
    final title = (c['user_name'] ?? c['name'] ?? '').toString();
    final appliedAt = (c['applied_at'] ?? c['created_time'] ?? c['time'] ?? '').toString();
    final avatar = (c['user_picture'] ?? c['avatar'] ?? '').toString();
    final phone = (c['phone'] ?? c['mobile'] ?? '').toString();
    final email = (c['email'] ?? '').toString();
    // Work details (best-effort keys)
    final whereWorked = (c['where_did_you_work'] ?? c['company'] ?? c['work_place'] ?? '').toString();
    final position = (c['position'] ?? c['job_title'] ?? '').toString();
    final from = (c['from'] ?? c['start'] ?? c['start_date'] ?? '').toString();
    final to = (c['to'] ?? c['end'] ?? c['end_date'] ?? '').toString();
    final description = _bestString([
      c['description'],
      c['message'],
      c['notes'],
      (c['application'] is Map ? (c['application']['description'] ?? c['application']['message']) : null),
      (c['details'] is Map ? (c['details']['description'] ?? c['details']['message']) : null),
      c['desc'],
      c['about_you'],
    ]);
    final experiences = _extractExperiences(c);

    return Container(
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(UI.rLg),
        boxShadow: UI.softShadow(context),
      ),
      padding: EdgeInsets.all(UI.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          avatar.isNotEmpty
              ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatar))
              : const CircleAvatar(child: Icon(Iconsax.user_copy)),
          SizedBox(width: UI.md),
          Expanded(child: Text(title.isEmpty ? '—' : title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          if (appliedAt.isNotEmpty)
            Text(appliedAt, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context))),
        ]),
        SizedBox(height: UI.md),
        if (phone.isNotEmpty || email.isNotEmpty)
          Row(children: [
            if (phone.isNotEmpty) ...[
              const Icon(Iconsax.call_copy, size: 16),
              SizedBox(width: 6),
              Text(phone),
            ],
            if (phone.isNotEmpty && email.isNotEmpty) SizedBox(width: UI.lg),
            if (email.isNotEmpty) ...[
              const Icon(Iconsax.sms_copy, size: 16),
              SizedBox(width: 6),
              Flexible(child: Text(email, overflow: TextOverflow.ellipsis)),
            ],
          ]),
        if (phone.isNotEmpty || email.isNotEmpty) SizedBox(height: 8),
        if (phone.isNotEmpty || email.isNotEmpty)
          Wrap(spacing: 8, children: [
            if (phone.isNotEmpty)
              OutlinedButton.icon(onPressed: () => _launchUri(Uri.parse('tel:$phone')), icon: const Icon(Iconsax.call_copy, size: 16), label: Text('call'.tr)),
            if (email.isNotEmpty)
              OutlinedButton.icon(onPressed: () => _launchUri(Uri.parse('mailto:$email')), icon: const Icon(Iconsax.sms_copy, size: 16), label: Text('email'.tr)),
          ]),
        if (phone.isNotEmpty || email.isNotEmpty) SizedBox(height: UI.md),
        if (experiences.isNotEmpty) ...[
          Text('work_experience'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: UI.sm),
          ...experiences.map((e) => _experienceBlock(e)).toList(),
          SizedBox(height: UI.md),
        ] else ...[
          _kv('where_did_you_work'.tr, whereWorked),
          _kv('position_job'.tr, position),
          Row(children: [
            Expanded(child: _kv('from'.tr, from, dense: true)),
            SizedBox(width: UI.md),
            Expanded(child: _kv('to'.tr, to, dense: true)),
          ]),
          SizedBox(height: UI.sm),
        ],
        if (description.isNotEmpty) _kv('description'.tr, description, multiline: true),
      ]),
    );
  }

  String _bestString(List<dynamic> candidates) {
    for (final v in candidates) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Map<String, dynamic>> _extractExperiences(Map<String, dynamic> c) {
    final keys = ['experiences', 'work_history', 'jobs'];
    for (final k in keys) {
      final v = c[k];
      if (v is List) {
        return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    }
    return const [];
  }

  Widget _experienceBlock(Map<String, dynamic> e) {
    final whereWorked = (e['where_did_you_work'] ?? e['company'] ?? e['work_place'] ?? '').toString();
    final position = (e['position'] ?? e['job_title'] ?? '').toString();
    final from = (e['from'] ?? e['start'] ?? e['start_date'] ?? '').toString();
    final to = (e['to'] ?? e['end'] ?? e['end_date'] ?? '').toString();
    final description = (e['description'] ?? e['notes'] ?? '').toString();
    return Container(
      margin: EdgeInsets.only(bottom: UI.sm),
      padding: EdgeInsets.all(UI.md),
      decoration: BoxDecoration(
        color: UI.surfacePage(context),
        borderRadius: BorderRadius.circular(UI.rMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (whereWorked.isNotEmpty || position.isNotEmpty)
          Text([whereWorked, position].where((s) => s.isNotEmpty).join(' • '), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Row(children: [
          Expanded(child: _kv('from'.tr, from, dense: true)),
          SizedBox(width: UI.md),
          Expanded(child: _kv('to'.tr, to, dense: true)),
        ]),
        if (description.isNotEmpty) _kv('description'.tr, description, multiline: true),
      ]),
    );
  }

  Widget _kv(String label, String value, {bool dense = false, bool multiline = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    final styleLabel = Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context));
    final styleValue = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 6 : UI.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: styleLabel),
        SizedBox(height: 4),
        multiline ? Text(value) : Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: styleValue),
      ]),
    );
  }
}
