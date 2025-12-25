import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../data/models/job.dart';
import '../../domain/jobs_repository.dart';
import 'job_detail_page.dart';
import 'job_create_page.dart';
import '../../../auth/application/auth_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JobsListPage extends StatefulWidget {
  final bool mineOnly;
  const JobsListPage({super.key, this.mineOnly = false});

  @override
  State<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  final _scroll = ScrollController();
  List<Job> _jobs = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String _error = '';

  // Filters
  List<JobCategory> _categories = [];
  int? _categoryId;
  String? _type; // e.g., full_time, part_time, contract
  String? _payPer; // e.g., hour, day, week, month, year
  final _locationCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prime();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _locationCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _prime() async {
    // Load categories in parallel with first page
    try {
      final repo = context.read<JobsRepository>();
      final cats = await repo.getCategories();
      setState(() => _categories = cats);
    } catch (_) {}
    await _load();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _offset = 0;
      _hasMore = true;
    });
    try {
      final repo = context.read<JobsRepository>();
      final items = await repo.getJobs(
        offset: 0,
        limit: _limit,
        categoryId: _categoryId,
        type: _type,
        payPer: _payPer,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        salaryMin: int.tryParse(_salaryMinCtrl.text.trim()),
        salaryMax: int.tryParse(_salaryMaxCtrl.text.trim()),
      );
      final filtered = widget.mineOnly
          ? _filterMine(items)
          : items;
      setState(() {
        _jobs = filtered;
        _loading = false;
        _hasMore = filtered.length >= _limit;
        _offset = filtered.length;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final repo = context.read<JobsRepository>();
      final items = await repo.getJobs(
        offset: _offset,
        limit: _limit,
        categoryId: _categoryId,
        type: _type,
        payPer: _payPer,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        salaryMin: int.tryParse(_salaryMinCtrl.text.trim()),
        salaryMax: int.tryParse(_salaryMaxCtrl.text.trim()),
      );
      final filtered = widget.mineOnly
          ? _filterMine(items)
          : items;
      setState(() {
        _jobs.addAll(filtered);
        _loadingMore = false;
        _hasMore = filtered.length >= _limit;
        _offset += filtered.length;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<Job> _filterMine(List<Job> items) {
    final auth = context.read<AuthNotifier>();
    final id = int.tryParse(auth.currentUser?['user_id']?.toString() ?? '');
    if (id == null) return const [];
    return items.where((j) => (j.iOwner == true) || j.author.userId == id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mineOnly ? 'my_jobs'.tr : 'jobs'.tr),
        actions: [
          IconButton(
            tooltip: 'filters'.tr,
            onPressed: _openFilters,
            icon: const Icon(Iconsax.filter_tick_copy),
          )
        ],
      ),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Get.to(() => const JobCreatePage())?.then((_) => _load()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.add_copy,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'create_job'.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? _buildSkeleton()
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.danger_copy, size: 48, color: UI.subtleText(context)),
                      SizedBox(height: UI.md),
                      Text('${'error'.tr}: $_error'),
                      SizedBox(height: UI.lg),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Iconsax.refresh_copy, size: 18),
                        label: Text('try_again'.tr),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(UI.lg, UI.lg, UI.lg, UI.xl * 3),
                    itemCount: _jobs.length + 1 + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: UI.lg),
                    itemBuilder: (context, index) {
                      // First item is filters summary row
                      if (index == 0) {
                        return _buildFilterChips();
                      }
                      final dataIndex = index - 1;
                      if (dataIndex >= _jobs.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final j = _jobs[dataIndex];
                      return InkWell(
                        onTap: () => Get.to(() => JobDetailPage(jobId: j.postId))?.then((_) => _load()),
                        child: Container(
                          decoration: BoxDecoration(
                            color: UI.surfaceCard(context),
                            borderRadius: BorderRadius.circular(UI.rLg),
                            boxShadow: UI.softShadow(context),
                          ),
                          child: Stack(
                            children: [
                              Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (j.cover.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(UI.rLg)),
                                  child: Stack(children: [
                                    Image.network(
                                      j.cover,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 160,
                                        color: Colors.grey[300],
                                        child: Icon(Iconsax.image_copy, color: Colors.grey[400]),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black26],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              Padding(
                                padding: EdgeInsets.all(UI.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(j.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    SizedBox(height: UI.sm),
                                    Wrap(spacing: 6, runSpacing: 6, children: [
                                      _chipSmall(context, j.typeMeta, scheme.primary.withOpacity(0.12), scheme.primary),
                                      if (j.paySalaryPerMeta.isNotEmpty) _chipSmall(context, j.paySalaryPerMeta, UI.surfacePage(context), UI.subtleText(context)),
                                    ]),
                                    SizedBox(height: UI.sm),
                                    Row(children: [
                                      Icon(Iconsax.location_copy, size: 16, color: UI.subtleText(context)),
                                      SizedBox(width: UI.sm),
                                      Expanded(child: Text(j.location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context)), maxLines: 1, overflow: TextOverflow.ellipsis))
                                    ]),
                                    SizedBox(height: UI.md),
                                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                      if (j.author.userPicture.isNotEmpty)
                                        CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider(j.author.userPicture))
                                      else
                                        CircleAvatar(radius: 14, backgroundColor: scheme.primary.withOpacity(0.2), child: Icon(Iconsax.user_copy, size: 14, color: scheme.primary)),
                                      SizedBox(width: UI.sm),
                                      Expanded(child: Text(j.author.userName, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      if (j.salaryMin != null && j.salaryMax != null && j.salaryMinCurrency != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: scheme.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${j.salaryMinCurrency!.format(j.salaryMin!)} - ${j.salaryMaxCurrency!.format(j.salaryMax!)}',
                                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 11),
                                          ),
                                        ),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: _ownerMenu(j),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _ownerMenu(Job j) {
    final auth = context.read<AuthNotifier>();
    final id = int.tryParse(auth.currentUser?['user_id']?.toString() ?? '');
    final isOwner = (id != null) && (j.iOwner == true || j.author.userId == id);
    if (!isOwner) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        if (v == 'edit') {
          await Get.to(() => const JobCreatePage());
        } else if (v == 'edit2') {
          // Fallback: if a dedicated edit page exists
        } else if (v == 'delete') {
          final confirm = await Get.dialog<bool>(
            AlertDialog(
              title: Text('delete_job'.tr),
              content: Text('delete_job_confirm'.tr),
              actions: [
                TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
                TextButton(onPressed: () => Get.back(result: true), child: Text('delete'.tr), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)),
              ],
            ),
          );
          if (confirm == true) {
            try {
              final repo = context.read<JobsRepository>();
              await repo.deleteJob(j.postId);
              Get.snackbar('success'.tr, 'job_deleted_successfully'.tr);
              _load();
            } catch (e) {
              Get.snackbar('error'.tr, e.toString());
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Iconsax.edit_2_copy, size: 18), SizedBox(width: UI.sm), Text('edit'.tr)])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Iconsax.trash_copy, size: 18, color: Theme.of(context).colorScheme.error), SizedBox(width: UI.sm), Text('delete'.tr, style: TextStyle(color: Theme.of(context).colorScheme.error))])),
      ],
    );
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[];
    if (_categoryId != null) {
      final match = _categories.where((c) => c.categoryId == _categoryId).toList();
      final name = match.isNotEmpty ? match.first.name : 'category'.tr;
      chips.add(_chip('$name', () => setState(() => _categoryId = null)));
    }
    if ((_type ?? '').isNotEmpty) chips.add(_chip(_type!, () => setState(() => _type = null)));
    if ((_payPer ?? '').isNotEmpty) chips.add(_chip(_payPer!, () => setState(() => _payPer = null)));
    if (_locationCtrl.text.trim().isNotEmpty) chips.add(_chip(_locationCtrl.text.trim(), () => _locationCtrl.clear()));
    if (_salaryMinCtrl.text.trim().isNotEmpty || _salaryMaxCtrl.text.trim().isNotEmpty) {
      chips.add(_chip('${_salaryMinCtrl.text.trim().isEmpty ? '0' : _salaryMinCtrl.text.trim()} - ${_salaryMaxCtrl.text.trim().isEmpty ? '∞' : _salaryMaxCtrl.text.trim()}', () {
        _salaryMinCtrl.clear();
        _salaryMaxCtrl.clear();
        setState(() {});
      }));
    }
    return Container(
      decoration: BoxDecoration(
        color: UI.surfaceCard(context),
        borderRadius: BorderRadius.circular(UI.rLg),
        boxShadow: UI.softShadow(context),
      ),
      padding: EdgeInsets.all(UI.md),
      child: Row(children: [
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 8, children: chips.isEmpty ? [Text('no_filters'.tr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: UI.subtleText(context)))] : chips),
        ),
        TextButton.icon(onPressed: _openFilters, icon: const Icon(Iconsax.setting_4_copy, size: 18), label: Text('filters'.tr))
      ]),
    );
  }

  Widget _chip(String label, VoidCallback onClear) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () { onClear(); _load(); },
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Iconsax.filter_search_copy),
                SizedBox(width: UI.sm),
                Text('filters'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(onPressed: () { setState(() { _categoryId = null; _type = null; _payPer = null; _locationCtrl.clear(); _salaryMinCtrl.clear(); _salaryMaxCtrl.clear(); }); _load(); Get.back(); }, child: Text('clear'.tr)),
              ]),
              SizedBox(height: UI.md),

              // Category
              Text('select_category'.tr),
              SizedBox(height: UI.sm),
              DropdownButtonFormField<int?> (
                value: _categoryId,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: null, child: Text('all'.tr)),
                  ..._categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              SizedBox(height: UI.md),

              // Type
              Text('type'.tr),
              SizedBox(height: UI.sm),
              DropdownButtonFormField<String?> (
                value: _type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'full_time', child: Text('Full-time')),
                  DropdownMenuItem(value: 'part_time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'temporary', child: Text('Temporary')),
                  DropdownMenuItem(value: 'internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'remote', child: Text('Remote')),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              SizedBox(height: UI.md),

              // Pay per
              Text('pay_per'.tr),
              SizedBox(height: UI.sm),
              DropdownButtonFormField<String?> (
                value: _payPer,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'hour', child: Text('Hour')),
                  DropdownMenuItem(value: 'day', child: Text('Day')),
                  DropdownMenuItem(value: 'week', child: Text('Week')),
                  DropdownMenuItem(value: 'month', child: Text('Month')),
                  DropdownMenuItem(value: 'year', child: Text('Year')),
                ],
                onChanged: (v) => setState(() => _payPer = v),
              ),
              SizedBox(height: UI.md),

              // Location
              Text('location'.tr),
              SizedBox(height: UI.sm),
              TextField(controller: _locationCtrl, decoration: InputDecoration(hintText: 'search_location'.tr)),
              SizedBox(height: UI.md),

              // Salary range
              Text('salary_range'.tr),
              SizedBox(height: UI.sm),
              Row(children: [
                Expanded(child: TextField(controller: _salaryMinCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'salary_min'.tr))),
                SizedBox(width: UI.md),
                Expanded(child: TextField(controller: _salaryMaxCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'salary_max'.tr))),
              ]),

              SizedBox(height: UI.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Get.back(); _load(); },
                  icon: const Icon(Iconsax.tick_square_copy, size: 18),
                  label: Text('apply'.tr),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.all(UI.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: UI.lg),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: UI.surfaceCard(context), borderRadius: BorderRadius.circular(UI.rLg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(height: 160, radius: 0),
          Padding(
            padding: EdgeInsets.all(UI.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              SkeletonBox(height: 20, width: 200, radius: 8),
              SizedBox(height: 8),
              SkeletonBox(height: 14, width: 120, radius: 8),
              SizedBox(height: 8),
              SkeletonBox(height: 14, width: 180, radius: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chipSmall(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
