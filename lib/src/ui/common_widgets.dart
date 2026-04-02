import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controller.dart';
import '../models.dart';
import '../platform_support.dart';
import '../theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[kKhataGreen, Color(0xFF2A8E72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: kKhataGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'HR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: kKhataInk.withValues(alpha: 0.64),
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    this.prominent = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: prominent
              ? LinearGradient(
                  colors: <Color>[
                    accentColor,
                    accentColor.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: prominent
                          ? Colors.white.withValues(alpha: 0.16)
                          : accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: prominent ? Colors.white : accentColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: prominent ? Colors.white : kKhataInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                value,
                style:
                    (prominent
                            ? Theme.of(context).textTheme.headlineLarge
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(
                          color: prominent ? Colors.white : accentColor,
                        ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: prominent
                      ? Colors.white.withValues(alpha: 0.84)
                      : kKhataInk.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kKhataInk.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InsightChip extends StatelessWidget {
  const InsightChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.controller,
    required this.transaction,
    this.onTap,
  });

  final HisabRakhoController controller;
  final LedgerTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? kKhataDanger : kKhataSuccess;
    final subtitleParts = <String>[controller.formatDateTime(transaction.date)];
    if (transaction.dueDate != null) {
      subtitleParts.add('Due ${controller.formatDate(transaction.dueDate!)}');
    }
    if (transaction.paidOnTime != null) {
      subtitleParts.add(transaction.paidOnTime! ? 'On time' : 'Late');
    }
    if (transaction.isDisputed) {
      subtitleParts.add('Disputed');
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isCredit ? Icons.add_rounded : Icons.remove_rounded,
            color: color,
          ),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                transaction.note,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (transaction.receiptPath.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.receipt_long_rounded, size: 18),
              ),
            if (transaction.audioNotePath.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.mic_rounded, size: 18),
              ),
          ],
        ),
        subtitle: Text(subtitleParts.join(' | ')),
        trailing: Text(
          '${isCredit ? '+' : '-'} ${controller.displayCurrency(transaction.amount)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class TemplateTile extends StatelessWidget {
  const TemplateTile({
    super.key,
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
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
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class AdBannerStrip extends StatefulWidget {
  const AdBannerStrip({super.key, required this.enabled});

  final bool enabled;

  @override
  State<AdBannerStrip> createState() => _AdBannerStripState();
}

class _AdBannerStripState extends State<AdBannerStrip> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled && supportsMobileAds) {
      _loadBanner();
    }
  }

  @override
  void didUpdateWidget(covariant AdBannerStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && supportsMobileAds && _bannerAd == null) {
      _loadBanner();
    }
    if (!widget.enabled && _bannerAd != null) {
      _disposeBanner();
    }
  }

  void _loadBanner() {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: kBannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            return;
          }
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    banner.load();
    _bannerAd = banner;
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !supportsMobileAds) {
      return const SizedBox.shrink();
    }

    if (_loaded && _bannerAd != null) {
      return Container(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kKhataGreen.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.ad_units_rounded,
            color: kKhataAmber.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AdMob banner loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
