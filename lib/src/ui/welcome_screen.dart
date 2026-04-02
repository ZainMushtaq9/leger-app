import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final PageController _onboardingController = PageController();
  final List<ShopDraft> _extraShops = <ShopDraft>[];

  int _stepIndex = 0;
  int _onboardingPage = 0;
  UserType _selectedType = UserType.shopkeeper;
  AppThemeMode _selectedThemeMode = AppThemeMode.system;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _selectedType = settings.userType;
    _selectedThemeMode = settings.themeMode;
    _nameController.text = settings.shopName == 'Hisab Rakho Store'
        ? ''
        : settings.shopName;
    _phoneController.text = settings.organizationPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_stepIndex == 0 && _onboardingPage < 2) {
      await _onboardingController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_stepIndex == 2 && !_formKey.currentState!.validate()) {
      return;
    }

    if (_stepIndex < 3) {
      setState(() {
        _stepIndex += 1;
      });
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.controller.completeOnboarding(
      userType: _selectedType,
      organizationName: _nameController.text.trim(),
      organizationPhone: _phoneController.text.trim(),
      language: AppLanguage.english,
      themeMode: _selectedThemeMode,
      additionalShops: _extraShops,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.copy.setupSavedMessage)),
    );
  }

  void _skipOnboarding() {
    setState(() {
      _stepIndex = 1;
    });
  }

  Future<void> _addExtraShop() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    var selectedType = UserType.shopkeeper;

    final result = await showModalBottomSheet<ShopDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.controller.copy.addAnotherShopLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: widget.controller.copy.shopNameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: widget.controller.copy.phoneLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'User Type'),
                    items: UserType.values
                        .map(
                          (type) => DropdownMenuItem<UserType>(
                            value: type,
                            child: Text(
                              AppTerminology.forUserType(
                                type,
                                language: AppLanguage.english,
                              ).userTypeLabel,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(widget.controller.copy.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              return;
                            }
                            Navigator.of(context).pop(
                              ShopDraft(
                                name: name,
                                phone: phoneController.text.trim(),
                                userType: selectedType,
                              ),
                            );
                          },
                          child: Text(widget.controller.copy.saveLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _extraShops.add(result);
    });
  }

  Widget _stepContent() {
    final copy = widget.controller.copy;
    switch (_stepIndex) {
      case 0:
        return SizedBox(
          height: 420,
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _onboardingController,
                  onPageChanged: (value) {
                    setState(() {
                      _onboardingPage = value;
                    });
                  },
                  children: const <Widget>[
                    _OnboardingSlide(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Track credit with clarity',
                      body:
                          'Keep every customer, balance, and entry in one place without paper notes.',
                      accentColor: kKhataGreen,
                    ),
                    _OnboardingSlide(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Send reminders in one tap',
                      body:
                          'Use WhatsApp or SMS reminders with soft, normal, and urgent tones.',
                      accentColor: kKhataAmber,
                    ),
                    _OnboardingSlide(
                      icon: Icons.insights_rounded,
                      title: 'Recover faster with smart actions',
                      body:
                          'Daily follow-ups, recovery insights, and reports help you focus on the right customers.',
                      accentColor: kKhataSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(3, (index) {
                  final active = index == _onboardingPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 26 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? kKhataGreen
                          : kKhataGreen.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              copy.businessTypeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            ...UserType.values.map((type) {
              final terms = AppTerminology.forUserType(
                type,
                language: AppLanguage.english,
              );
              final selected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected ? kKhataGreen : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? kKhataGreen
                            : kKhataGreen.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                terms.userTypeLabel,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: selected
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${terms.entitySingular}, ${terms.creditLabel}, ${terms.outstandingLabel}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.84)
                                          : kKhataInk.withValues(alpha: 0.65),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected ? Colors.white : kKhataGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      case 2:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                copy.workspaceTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(copy.workspaceSubtitle),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: copy.shopNameLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return copy.shopNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: copy.phoneLabel),
              ),
            ],
          ),
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Appearance and workspaces',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kKhataGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: kKhataGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'App language',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'English is active in this build.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppThemeMode>(
              initialValue: _selectedThemeMode,
              decoration: InputDecoration(labelText: copy.themeLabel),
              items: AppThemeMode.values
                  .map(
                    (themeMode) => DropdownMenuItem<AppThemeMode>(
                      value: themeMode,
                      child: Text(widget.controller.themeModeLabel(themeMode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedThemeMode = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              copy.extraShopsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(copy.extraShopsSubtitle),
            const SizedBox(height: 14),
            if (_extraShops.isEmpty)
              Text(copy.noExtraShopLabel)
            else
              ..._extraShops.map(
                (shop) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kKhataGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text('${shop.name} • ${shop.phone}'),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addExtraShop,
              icon: const Icon(Icons.add_business_rounded),
              label: Text(copy.addAnotherShopLabel),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.controller.copy;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: <Widget>[
            Row(
              children: <Widget>[
                const BrandMark(size: 58),
                const Spacer(),
                if (_stepIndex == 0)
                  TextButton(
                    onPressed: _saving ? null : _skipOnboarding,
                    child: const Text('Skip'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _stepIndex == 0 ? 'Welcome to Hisab Rakho' : copy.welcomeTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _stepIndex == 0
                  ? 'Set up your shop, protect the app, and start tracking customers in a few steps.'
                  : copy.welcomeSubtitle,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: (_stepIndex + 1) / 4,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<int>(_stepIndex),
                child: _stepContent(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                if (_stepIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _stepIndex -= 1),
                      child: Text(copy.backLabel),
                    ),
                  ),
                if (_stepIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _next,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _stepIndex == 0 && _onboardingPage < 2
                          ? 'Next'
                          : _stepIndex == 3
                          ? copy.finishSetupLabel
                          : copy.continueLabel,
                    ),
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

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: accentColor),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                InsightChip(label: 'Offline ready', color: kKhataGreen),
                InsightChip(label: 'Fast follow-up', color: kKhataAmber),
                InsightChip(label: 'Reports included', color: kKhataSuccess),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
