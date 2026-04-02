import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class CommunityBlacklistScreen extends StatefulWidget {
  const CommunityBlacklistScreen({
    super.key,
    required this.controller,
    required this.customer,
  });

  final HisabRakhoController controller;
  final Customer customer;

  @override
  State<CommunityBlacklistScreen> createState() =>
      _CommunityBlacklistScreenState();
}

class _CommunityBlacklistScreenState extends State<CommunityBlacklistScreen> {
  late final TextEditingController _queryController;
  String _selectedCity = '';
  CommunityRiskLevel? _selectedRiskLevel;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController()..addListener(_refresh);
  }

  @override
  void dispose() {
    _queryController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openReportSheet(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    final report = await showModalBottomSheet<_CommunityReportDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CommunityReportSheet(
          controller: widget.controller,
          customer: liveCustomer,
          initialRiskLevel: CommunityRiskLevel.blacklist,
        );
      },
    );

    if (report == null || !context.mounted) {
      return;
    }
    await widget.controller.reportCustomerToCommunityBlacklist(
      customerId: liveCustomer.id,
      reason: report.reason,
      note: report.note,
      riskLevel: report.riskLevel,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Community report saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final liveCustomer =
            widget.controller.customerById(widget.customer.id) ??
            widget.customer;
        final matches = widget.controller.communityBlacklistMatchesForCustomer(
          liveCustomer.id,
        );
        final entries = widget.controller.searchCommunityBlacklist(
          query: _queryController.text,
          city: _selectedCity,
          riskLevel: _selectedRiskLevel,
        );
        final cities = widget.controller.communityBlacklistCities;
        final watchCount = entries
            .where((entry) => entry.riskLevel == CommunityRiskLevel.watch)
            .length;
        final blacklistCount = entries
            .where((entry) => entry.riskLevel == CommunityRiskLevel.blacklist)
            .length;

        return Scaffold(
          appBar: AppBar(title: const Text('Community Blacklist')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              if (!widget.controller.communityBlacklistEnabled) ...<Widget>[
                const EmptyStateCard(
                  title: 'Community blacklist is off',
                  message:
                      'Enable the community blacklist in Settings before viewing matches or creating risk reports.',
                ),
              ] else ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          liveCustomer.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          matches.isEmpty
                              ? 'No matching report was found for this customer in the local community wall.'
                              : '${matches.length} matching community report(s) were found. Use extra caution during follow-up.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            InsightChip(
                              label: liveCustomer.city.trim().isEmpty
                                  ? 'City unknown'
                                  : liveCustomer.city.trim(),
                              color: kKhataAmber,
                            ),
                            InsightChip(
                              label: matches.isEmpty
                                  ? 'No matches'
                                  : '${matches.length} match(es)',
                              color: matches.isEmpty
                                  ? kKhataSuccess
                                  : kKhataDanger,
                            ),
                          ],
                        ),
                        if (widget.controller.canWriteData) ...<Widget>[
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _openReportSheet(context, liveCustomer),
                            icon: const Icon(Icons.gpp_bad_rounded),
                            label: const Text('Report This Customer'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Search Community Wall',
                  subtitle:
                      'Search local risk notes by phone, CNIC, customer name, city, or reason.',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            labelText: 'Search',
                            hintText: 'Name, phone, city, CNIC, reason',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'City filter',
                          ),
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All cities'),
                            ),
                            ...cities.map(
                              (city) => DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CommunityRiskLevel?>(
                          initialValue: _selectedRiskLevel,
                          decoration: const InputDecoration(
                            labelText: 'Risk filter',
                          ),
                          items: <DropdownMenuItem<CommunityRiskLevel?>>[
                            const DropdownMenuItem<CommunityRiskLevel?>(
                              value: null,
                              child: Text('All risk levels'),
                            ),
                            ...CommunityRiskLevel.values.map(
                              (level) => DropdownMenuItem<CommunityRiskLevel?>(
                                value: level,
                                child: Text(
                                  widget.controller.communityRiskLevelLabel(
                                    level,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRiskLevel = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            InsightChip(
                              label: '${entries.length} results',
                              color: kKhataGreen,
                            ),
                            InsightChip(
                              label: '$watchCount watch',
                              color: kKhataAmber,
                            ),
                            InsightChip(
                              label: '$blacklistCount blacklist',
                              color: kKhataDanger,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (matches.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Matched Reports',
                    subtitle:
                        'These entries were matched using the current customer phone number, CNIC, or city.',
                  ),
                  const SizedBox(height: 12),
                  ...matches.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BlacklistEntryCard(
                        controller: widget.controller,
                        entry: entry,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Community Wall',
                  subtitle: 'Recent local reports and watch notes.',
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const EmptyStateCard(
                    title: 'No reports found',
                    message:
                        'No community entry matched this filter. You can report the current customer if needed.',
                  )
                else
                  ...entries
                      .take(20)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BlacklistEntryCard(
                            controller: widget.controller,
                            entry: entry,
                          ),
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BlacklistEntryCard extends StatelessWidget {
  const _BlacklistEntryCard({required this.controller, required this.entry});

  final HisabRakhoController controller;
  final CommunityBlacklistEntry entry;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(entry.riskLevel);
    final shopName = controller.shopById(entry.shopId)?.name ?? 'Archived shop';
    final subtitleParts = <String>[
      if (entry.city.trim().isNotEmpty) entry.city.trim(),
      if (entry.phone.trim().isNotEmpty) entry.phone.trim(),
      shopName,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entry.customerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                InsightChip(
                  label: controller.communityRiskLevelLabel(entry.riskLevel),
                  color: riskColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitleParts.join(' | '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kKhataInk.withValues(alpha: 0.66),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.reason,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (entry.note.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(entry.note.trim()),
            ],
            const SizedBox(height: 10),
            Text(
              controller.formatDateTime(entry.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kKhataInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityReportSheet extends StatefulWidget {
  const _CommunityReportSheet({
    required this.controller,
    required this.customer,
    required this.initialRiskLevel,
  });

  final HisabRakhoController controller;
  final Customer customer;
  final CommunityRiskLevel initialRiskLevel;

  @override
  State<_CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<_CommunityReportSheet> {
  late final TextEditingController _reasonController;
  late final TextEditingController _noteController;
  late CommunityRiskLevel _riskLevel;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _noteController = TextEditingController();
    _riskLevel = widget.initialRiskLevel;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A reason is required.')));
      return;
    }
    Navigator.of(context).pop(
      _CommunityReportDraft(
        reason: reason,
        note: _noteController.text.trim(),
        riskLevel: _riskLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Report to community wall',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Save a factual risk note for ${widget.customer.name}. It will stay in the local community wall and in backups.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CommunityRiskLevel>(
              initialValue: _riskLevel,
              decoration: const InputDecoration(labelText: 'Risk level'),
              items: CommunityRiskLevel.values
                  .map(
                    (value) => DropdownMenuItem<CommunityRiskLevel>(
                      value: value,
                      child: Text(
                        widget.controller.communityRiskLevelLabel(value),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _riskLevel = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Repeated broken promises, bounced cheque, etc.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Short factual note for internal community view',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityReportDraft {
  const _CommunityReportDraft({
    required this.reason,
    required this.note,
    required this.riskLevel,
  });

  final String reason;
  final String note;
  final CommunityRiskLevel riskLevel;
}

Color _riskColor(CommunityRiskLevel level) {
  switch (level) {
    case CommunityRiskLevel.watch:
      return kKhataAmber;
    case CommunityRiskLevel.blacklist:
      return kKhataDanger;
  }
}
