import 'package:flutter/material.dart';

import '../theme.dart';
import 'common_widgets.dart';

final List<_FeatureItem> _featureData = _featureItems;
final List<_FeatureGroup> _coreFeatureGroups = _coreGroups;
final List<_FeatureGroup> _noveltyFeatureGroups = _noveltyGroups;
final List<_ToolGroup> _featureToolGroups = _toolGroups;
const int _coreFeatureCount = 47;
const int _noveltyFeatureCount = 28;

class FeatureBibleScreen extends StatefulWidget {
  const FeatureBibleScreen({super.key});

  @override
  State<FeatureBibleScreen> createState() => _FeatureBibleScreenState();
}

class _FeatureBibleScreenState extends State<FeatureBibleScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredFeatures = _featureData.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.group.toLowerCase().contains(query) ||
          item.tool.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feature guide'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(text: 'All Features'),
              Tab(text: 'Core'),
              Tab(text: 'Advanced'),
              Tab(text: 'Tools'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _AllFeaturesTab(
              searchController: _searchController,
              filteredFeatures: filteredFeatures,
            ),
            const _CoreFeaturesTab(),
            const _NoveltyFeaturesTab(),
            const _ToolsMapTab(),
          ],
        ),
      ),
    );
  }
}

class _AllFeaturesTab extends StatelessWidget {
  const _AllFeaturesTab({
    required this.searchController,
    required this.filteredFeatures,
  });

  final TextEditingController searchController;
  final List<_FeatureItem> filteredFeatures;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        const _HeroCard(),
        const SizedBox(height: 16),
        const _TopThreeCard(),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText:
                'Search feature, tool, keyword, kisti, reminder, voice...',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            InsightChip(
              label: '${_featureData.length} total',
              color: kKhataGreen,
            ),
            InsightChip(label: '$_coreFeatureCount core', color: kKhataAmber),
            InsightChip(
              label: '$_noveltyFeatureCount new',
              color: kKhataSuccess,
            ),
            InsightChip(
              label: '${filteredFeatures.length} visible',
              color: kKhataDanger,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredFeatures.isEmpty)
          const EmptyStateCard(
            title: 'No match found',
            message:
                'Koi aur keyword try karein. Search title, tags, ya free tool name se bhi chalti hai.',
          )
        else
          ...filteredFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureCard(feature: feature),
            ),
          ),
      ],
    );
  }
}

class _CoreFeaturesTab extends StatelessWidget {
  const _CoreFeaturesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        const SectionHeader(
          title: 'Core Features',
          subtitle:
              '47 must-have features in 10 categories. Ye app ko market-ready aur credible banate hain.',
        ),
        const SizedBox(height: 16),
        ..._coreFeatureGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FeatureGroupCard(group: group),
          ),
        ),
      ],
    );
  }
}

class _NoveltyFeaturesTab extends StatelessWidget {
  const _NoveltyFeaturesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        const SectionHeader(
          title: 'Novelty Features',
          subtitle:
              '28 differentiators in 5 groups. Ye layer app ko smart recovery engine banati hai.',
        ),
        const SizedBox(height: 16),
        ..._noveltyFeatureGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FeatureGroupCard(group: group),
          ),
        ),
      ],
    );
  }
}

class _ToolsMapTab extends StatelessWidget {
  const _ToolsMapTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: <Widget>[
        const SectionHeader(
          title: 'Free Tools Map',
          subtitle:
              'Offline aur cloud dono tracks ready hain. Har block mein primary stack aur alternatives diye gaye hain.',
        ),
        const SizedBox(height: 16),
        ..._featureToolGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ToolGroupCard(group: group),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: <Color>[kKhataGreen, kKhataGreen.withValues(alpha: 0.88)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const BrandMark(size: 50),
            const SizedBox(height: 18),
            Text(
              'Feature guide',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the current feature set, grouped capabilities, and supporting tools in one place.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopThreeCard extends StatelessWidget {
  const _TopThreeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Featured capabilities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'These high-impact workflows are worth highlighting and refining further.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kKhataInk.withValues(alpha: 0.64),
              ),
            ),
            const SizedBox(height: 14),
            const _PriorityFeatureTile(
              featureNo: 56,
              title: 'Kisti Installment Planner',
              subtitle:
                  'Real-life Pakistan collection behavior ko match karta hai. Negotiated partial payments ko easy banata hai.',
              color: kKhataAmber,
            ),
            const SizedBox(height: 10),
            const _PriorityFeatureTile(
              featureNo: 57,
              title: 'Payment Promise Tracker',
              subtitle:
                  '“Kal dunga” promises ko track karta hai aur follow-up actions auto-prioritize karta hai.',
              color: kKhataDanger,
            ),
            const SizedBox(height: 10),
            const _PriorityFeatureTile(
              featureNo: 62,
              title: 'Customer Self-Service Web Portal',
              subtitle:
                  'Customer ko app install nahi karni padti. Sirf link khol kar apna balance aur history dekh leta hai.',
              color: kKhataSuccess,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityFeatureTile extends StatelessWidget {
  const _PriorityFeatureTile({
    required this.featureNo,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final int featureNo;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$featureNo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _FeatureItem feature;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: feature.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '#${feature.id}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: feature.color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feature.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kKhataInk.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                InsightChip(label: feature.group, color: feature.color),
                InsightChip(
                  label: 'Free tool: ${feature.tool}',
                  color: kKhataGreen,
                ),
                ...feature.tags
                    .take(2)
                    .map((tag) => InsightChip(label: tag, color: kKhataAmber)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGroupCard extends StatelessWidget {
  const _FeatureGroupCard({required this.group});

  final _FeatureGroup group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                InsightChip(
                  label: '${group.items.length} items',
                  color: group.color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kKhataInk.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 14),
            ...group.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FeatureBullet(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '#${item.id} ${item.title}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: item.color),
          ),
          const SizedBox(height: 4),
          Text(item.description),
          const SizedBox(height: 8),
          Text(
            'Free tool: ${item.tool}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kKhataInk.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolGroupCard extends StatelessWidget {
  const _ToolGroupCard({required this.group});

  final _ToolGroup group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(group.icon, color: group.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kKhataInk.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 14),
            ...group.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(item.usage),
                      const SizedBox(height: 6),
                      Text(
                        'Alternatives: ${item.alternatives}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kKhataInk.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
    required this.tool,
    required this.color,
    required this.tags,
  });

  final int id;
  final String title;
  final String description;
  final String group;
  final String tool;
  final Color color;
  final List<String> tags;
}

class _FeatureGroup {
  const _FeatureGroup({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<_FeatureItem> items;
}

class _ToolGroup {
  const _ToolGroup({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<_ToolItem> items;
}

class _ToolItem {
  const _ToolItem({
    required this.title,
    required this.usage,
    required this.alternatives,
  });

  final String title;
  final String usage;
  final String alternatives;
}

const List<_FeatureItem> _featureItems = <_FeatureItem>[
  _FeatureItem(
    id: 1,
    title: 'Smart Reminder System',
    description:
        'Rule-based tone selection for soft, normal, and strict reminders without paid AI.',
    group: 'Smart Intelligence',
    tool: 'Local rule engine',
    color: kKhataGreen,
    tags: <String>['reminder', 'whatsapp', 'automation'],
  ),
  _FeatureItem(
    id: 2,
    title: 'Recovery Score',
    description:
        'Local scorecard based on payment behavior, overdue days, and pending balance.',
    group: 'Smart Intelligence',
    tool: 'Offline scoring formula',
    color: kKhataSuccess,
    tags: <String>['score', 'risk', 'insight'],
  ),
  _FeatureItem(
    id: 5,
    title: 'Daily Action Engine',
    description:
        'Sorts overdue accounts by amount and urgency so the owner knows who to contact first.',
    group: 'Action Layer',
    tool: 'Local filtering logic',
    color: kKhataAmber,
    tags: <String>['daily', 'priority', 'follow-up'],
  ),
  _FeatureItem(
    id: 6,
    title: 'Voice Input (Urdu)',
    description:
        'Mic button captures Roman Urdu or Urdu phrases like “Ali ko 5000 udhaar likho”.',
    group: 'Voice / Input',
    tool: 'SpeechRecognizer / speech_to_text',
    color: kKhataAmber,
    tags: <String>['voice', 'urdu', 'input'],
  ),
  _FeatureItem(
    id: 7,
    title: 'Customer View Link',
    description:
        'Shareable web statement page so customers can check balance without installing the app.',
    group: 'Pakistan-First UX',
    tool: 'Firebase Hosting free tier',
    color: kKhataGreen,
    tags: <String>['portal', 'web', 'share'],
  ),
  _FeatureItem(
    id: 8,
    title: 'Emotional Message Templates',
    description:
        'Soft, normal, and strict message presets for different collection situations.',
    group: 'Communication',
    tool: 'Local template library',
    color: kKhataDanger,
    tags: <String>['template', 'tone', 'message'],
  ),
  _FeatureItem(
    id: 9,
    title: 'Recovery Gamification',
    description:
        'Monthly recovery wins, activity streaks, and momentum indicators to keep usage consistent.',
    group: 'UX',
    tool: 'Local progress tracking',
    color: kKhataSuccess,
    tags: <String>['streak', 'gamification', 'motivation'],
  ),
  _FeatureItem(
    id: 10,
    title: 'Offline-First Mode',
    description:
        'App keeps working without internet and syncs when a connection returns.',
    group: 'Core Foundation',
    tool: 'Firestore cache / local DB',
    color: kKhataGreen,
    tags: <String>['offline', 'sync', 'low-data'],
  ),
  _FeatureItem(
    id: 56,
    title: 'Kisti Installment Planner',
    description:
        'Break pending balance into realistic installments and produce a simple recovery plan.',
    group: 'Pakistan-First Ideas',
    tool: 'Local installment calculator',
    color: kKhataAmber,
    tags: <String>['kisti', 'installment', 'planner'],
  ),
  _FeatureItem(
    id: 57,
    title: 'Payment Promise Tracker',
    description:
        'Track “kal dunga” commitments, promised dates, and missed follow-ups in one place.',
    group: 'Pakistan-First Ideas',
    tool: 'Local reminders + date engine',
    color: kKhataDanger,
    tags: <String>['promise', 'follow-up', 'date'],
  ),
  _FeatureItem(
    id: 62,
    title: 'Customer Self-Service Web Portal',
    description:
        'Mobile-friendly page showing balance, transactions, and status through a unique link.',
    group: 'Pakistan-First Ideas',
    tool: 'Firebase Hosting + Firestore',
    color: kKhataSuccess,
    tags: <String>['self-service', 'portal', 'web'],
  ),
  _FeatureItem(
    id: 64,
    title: 'Credit Limit Suggestion',
    description:
        'Warn the user before adding more credit to risky accounts with weak payment history.',
    group: 'Forecasting',
    tool: 'Rule-based threshold logic',
    color: kKhataDanger,
    tags: <String>['limit', 'warning', 'risk'],
  ),
  _FeatureItem(
    id: 70,
    title: 'PDF Statement Export',
    description:
        'Create a shareable statement summary for WhatsApp, printing, or business follow-up.',
    group: 'Operations',
    tool: 'pdf package',
    color: kKhataGreen,
    tags: <String>['pdf', 'statement', 'export'],
  ),
];

const List<_FeatureGroup> _coreGroups = <_FeatureGroup>[
  _FeatureGroup(
    title: 'Tracking Essentials',
    subtitle:
        'Foundational tracking features that every serious recovery app needs.',
    color: kKhataGreen,
    items: <_FeatureItem>[
      _FeatureItem(
        id: 10,
        title: 'Offline-First Mode',
        description:
            'Run core flows even when internet is weak or unavailable.',
        group: 'Core Foundation',
        tool: 'Firestore cache / local DB',
        color: kKhataGreen,
        tags: <String>['offline'],
      ),
      _FeatureItem(
        id: 70,
        title: 'PDF Statement Export',
        description: 'Share ledger proof in a familiar format.',
        group: 'Operations',
        tool: 'pdf package',
        color: kKhataGreen,
        tags: <String>['pdf'],
      ),
    ],
  ),
  _FeatureGroup(
    title: 'Recovery Actions',
    subtitle:
        'Must-have reminder and action workflows that users expect immediately.',
    color: kKhataAmber,
    items: <_FeatureItem>[
      _FeatureItem(
        id: 1,
        title: 'Smart Reminder System',
        description: 'Auto tone selection for reminders.',
        group: 'Smart Intelligence',
        tool: 'Local rule engine',
        color: kKhataAmber,
        tags: <String>['reminder'],
      ),
      _FeatureItem(
        id: 5,
        title: 'Daily Action Engine',
        description: 'Show who to follow up today.',
        group: 'Action Layer',
        tool: 'Local filtering logic',
        color: kKhataAmber,
        tags: <String>['actions'],
      ),
      _FeatureItem(
        id: 8,
        title: 'Emotional Message Templates',
        description: 'Ready-made soft, normal, and strict wording.',
        group: 'Communication',
        tool: 'Local template library',
        color: kKhataAmber,
        tags: <String>['templates'],
      ),
    ],
  ),
  _FeatureGroup(
    title: 'Insight Layer',
    subtitle:
        'Market credibility usually depends on clear, simple risk indicators.',
    color: kKhataDanger,
    items: <_FeatureItem>[
      _FeatureItem(
        id: 2,
        title: 'Recovery Score',
        description: 'Reliability score based on local behavior data.',
        group: 'Smart Intelligence',
        tool: 'Offline scoring formula',
        color: kKhataDanger,
        tags: <String>['score'],
      ),
      _FeatureItem(
        id: 64,
        title: 'Credit Limit Suggestion',
        description: 'Warn before risky new credit.',
        group: 'Forecasting',
        tool: 'Rule-based threshold logic',
        color: kKhataDanger,
        tags: <String>['limit'],
      ),
    ],
  ),
];

const List<_FeatureGroup> _noveltyGroups = <_FeatureGroup>[
  _FeatureGroup(
    title: 'Pakistan-First Ideas',
    subtitle:
        'Features built around actual negotiation and payment behavior in Pakistan.',
    color: kKhataAmber,
    items: <_FeatureItem>[
      _FeatureItem(
        id: 56,
        title: 'Kisti Installment Planner',
        description: 'Turn one balance into a practical installment plan.',
        group: 'Pakistan-First Ideas',
        tool: 'Local installment calculator',
        color: kKhataAmber,
        tags: <String>['kisti'],
      ),
      _FeatureItem(
        id: 57,
        title: 'Payment Promise Tracker',
        description: 'Track verbal promises and missed dates.',
        group: 'Pakistan-First Ideas',
        tool: 'Local reminders + date engine',
        color: kKhataAmber,
        tags: <String>['promise'],
      ),
      _FeatureItem(
        id: 62,
        title: 'Customer Self-Service Web Portal',
        description:
            'Let the customer open a link instead of installing an app.',
        group: 'Pakistan-First Ideas',
        tool: 'Firebase Hosting + Firestore',
        color: kKhataAmber,
        tags: <String>['portal'],
      ),
    ],
  ),
  _FeatureGroup(
    title: 'Voice and Friction Reduction',
    subtitle: 'Shorten the path from conversation to ledger entry.',
    color: kKhataSuccess,
    items: <_FeatureItem>[
      _FeatureItem(
        id: 6,
        title: 'Voice Input (Urdu)',
        description: 'Capture spoken commands for quick entries.',
        group: 'Voice / Input',
        tool: 'SpeechRecognizer / speech_to_text',
        color: kKhataSuccess,
        tags: <String>['voice'],
      ),
      _FeatureItem(
        id: 9,
        title: 'Recovery Gamification',
        description: 'Keep usage sticky through streaks and progress wins.',
        group: 'UX',
        tool: 'Local progress tracking',
        color: kKhataSuccess,
        tags: <String>['streak'],
      ),
    ],
  ),
];

const List<_ToolGroup> _toolGroups = <_ToolGroup>[
  _ToolGroup(
    title: 'Offline / Zero Internet',
    subtitle: 'Core app behavior that should keep running on-device.',
    color: kKhataGreen,
    icon: Icons.offline_bolt_rounded,
    items: <_ToolItem>[
      _ToolItem(
        title: 'Speech Recognition',
        usage:
            'Use speech_to_text or Android SpeechRecognizer for Urdu voice capture.',
        alternatives: 'speech_to_text, native Kotlin bridge',
      ),
      _ToolItem(
        title: 'Local Scoring and Predictions',
        usage: 'Compute recovery score, urgency, and payment chance on-device.',
        alternatives: 'Pure Dart formulas, local SQLite calculations',
      ),
      _ToolItem(
        title: 'Installment and Promise Logic',
        usage:
            'Track kisti plans and promised payment dates without any paid API.',
        alternatives: 'Hive, SQLite, Isar',
      ),
    ],
  ),
  _ToolGroup(
    title: 'Cloud / Free Tier',
    subtitle:
        'Only the lightweight cloud pieces needed for sync and web sharing.',
    color: kKhataAmber,
    icon: Icons.cloud_queue_rounded,
    items: <_ToolItem>[
      _ToolItem(
        title: 'Firebase Hosting',
        usage: 'Serve the customer self-service portal and shared statements.',
        alternatives: 'Netlify, Vercel, GitHub Pages',
      ),
      _ToolItem(
        title: 'Firestore',
        usage: 'Realtime sync, cloud backup, and simple shareable records.',
        alternatives: 'Supabase free tier, Appwrite Cloud',
      ),
      _ToolItem(
        title: 'AdMob',
        usage: 'Free banner monetization with lightweight placements.',
        alternatives: 'Meta Audience Network later if needed',
      ),
    ],
  ),
  _ToolGroup(
    title: 'Sharing and Communication',
    subtitle: 'Free integrations that feel native to the user.',
    color: kKhataDanger,
    icon: Icons.share_rounded,
    items: <_ToolItem>[
      _ToolItem(
        title: 'WhatsApp Intent / wa.me',
        usage: 'Open reminders and payment confirmations directly in WhatsApp.',
        alternatives: 'SMS intent, generic share sheet',
      ),
      _ToolItem(
        title: 'PDF Export',
        usage: 'Generate statements for print, WhatsApp, or manual follow-up.',
        alternatives: 'printing package, screenshot-based summary',
      ),
    ],
  ),
];
