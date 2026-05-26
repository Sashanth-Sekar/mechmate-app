import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/shared/services/services.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// If the feature is disabled, the feature page shows a placeholder explaining
// that the feature is coming soon. When enabled, it calls the backend API.
// ---------------------------------------------------------------------------

class JobCardsScreen extends StatefulWidget {
  const JobCardsScreen({super.key});

  @override
  State<JobCardsScreen> createState() => _JobCardsScreenState();
}

class _JobCardsScreenState extends State<JobCardsScreen> {
  final ApiClient _client = ApiClient.instance;
  List<_JobData> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.jobCardsEnabled) _loadJobs();
  }

  Future<void> _loadJobs() async {
    // Check connectivity first
    if (!ConnectivityService.instance.isOnline) {
      if (mounted) {
        setState(() {
          _error = 'No internet connection. Please go online to load jobs.';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _error = null);

    try {
      // TODO: Replace with real API once backend job-cards endpoint is built.
      // For now, return empty list to demonstrate the full state cycle.
      final result = await _client.getList('/job-cards',
              fromJson: (json) => _JobData(
                    json['id'] as String? ?? '',
                    json['service'] as String? ?? '',
                    json['vehicleMake'] as String? ?? '',
                    json['vehicleNum'] as String? ?? '',
                    json['customer'] as String? ?? '',
                    json['status'] as String? ?? '',
                    (json['parts'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                  ))
          .timeout(const Duration(seconds: 10),
              onTimeout: () => throw const ApiException('Request timed out'));

      if (!mounted) return;
      setState(() {
        _jobs = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('JobCardsScreen: ApiException — $e');
      if (mounted) {
        setState(() {
        _error = e.message;
        _isLoading = false;
      });
      }
    } catch (e) {
      debugPrint('JobCardsScreen: unexpected error — $e');
      if (mounted) {
        setState(() {
        _error = 'Failed to load jobs. Pull to retry.';
        _isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ---- Feature disabled state -------------------------------------------------
    if (!FeatureFlags.jobCardsEnabled) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.construction_rounded,
            title: 'Job Cards',
            subtitle: 'This feature is coming soon. Stay tuned!',
          ),
        ),
      );
    }

    // ---- Active state -----------------------------------------------------------
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF4F5F0), Color(0xFFECEDE8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }

    if (_error != null) {
      return ErrorRetry(
        message: _error!,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _loadJobs();
        },
      );
    }

    if (_jobs.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Active Jobs',
        subtitle: 'Assigned jobs will appear here once a booking is confirmed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text('Active Jobs',
                    style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_jobs.length} Active',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              await _loadJobs();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) =>
                  _JobCard(isDark: isDark, data: _jobs[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data & UI below is unchanged from the previous mock version. Once the
// backend endpoint is ready, the model will be migrated to a proper
// code-generated type alongside the API service.
// ---------------------------------------------------------------------------

class _JobData {
  final String id;
  final String service;
  final String vehicleMake;
  final String vehicleNum;
  final String customer;
  final String status;
  final List<String> parts;
  const _JobData(this.id, this.service, this.vehicleMake, this.vehicleNum,
      this.customer, this.status, this.parts);
}

class _JobCard extends StatefulWidget {
  final bool isDark;
  final _JobData data;
  const _JobCard({required this.isDark, required this.data});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;

    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.work_rounded,
                  color: AppColors.cyanAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(d.service,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Rajdhani',
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary)),
                    const Spacer(),
                    Text(d.id,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600)),
                  ]),
                  Text('${d.vehicleMake} · ${d.vehicleNum}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.person_outline_rounded,
                size: 13,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted),
            const SizedBox(width: 4),
            Text(d.customer,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(d.status,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Parts Used',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: d.parts
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(p,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.cyanAccent,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: AppColors.primaryOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add Parts',
                        style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Complete',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_expanded ? 'Show Less' : 'Show Details',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600)),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryOrange,
                size: 18,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
