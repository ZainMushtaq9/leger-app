import 'package:flutter/material.dart';

import '../controller.dart';
import '../services/biometric_auth_service.dart';
import '../theme.dart';
import 'common_widgets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.controller,
    this.biometricAuthService,
  });

  final HisabRakhoController controller;
  final BiometricAuthService? biometricAuthService;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final List<String> _digits = <String>[];
  bool _submitting = false;
  bool _biometricAvailable = false;
  String _error = '';

  BiometricAuthService get _authService =>
      widget.biometricAuthService ?? _biometricAuthService;

  @override
  void initState() {
    super.initState();
    _prepareBiometricState();
  }

  Future<void> _prepareBiometricState() async {
    if (!widget.controller.settings.biometricUnlockEnabled) {
      return;
    }
    final available = await _authService.canAuthenticate();
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricAvailable = available;
    });
    if (available) {
      await _unlockWithBiometrics();
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _error = '';
    });
    final authenticated = await _authService.authenticate();
    if (!mounted || !authenticated) {
      return;
    }
    widget.controller.unlockWithBiometrics();
  }

  Future<void> _unlock() async {
    final pin = _digits.join();
    if (pin.length < 4) {
      setState(() {
        _error = 'Enter at least 4 digits.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = '';
    });

    final unlocked = widget.controller.unlockWithPin(pin);
    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      if (!unlocked) {
        _digits.clear();
        _error = 'The PIN was not correct.';
      }
    });
  }

  void _appendDigit(String digit) {
    if (_submitting || _digits.length >= 6) {
      return;
    }
    setState(() {
      _error = '';
      _digits.add(digit);
    });
  }

  void _removeDigit() {
    if (_submitting || _digits.isEmpty) {
      return;
    }
    setState(() {
      _digits.removeLast();
    });
  }

  Future<void> _showForgotPinHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset help'),
          content: const Text(
            'To reset the PIN, restore the app from your secure backup.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const BrandMark(size: 68),
                  const SizedBox(height: 20),
                  Text(
                    'Unlock Hisab Rakho',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your security PIN to continue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(6, (index) {
                      final filled = index < _digits.length;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? kKhataGreen : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? kKhataGreen
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: 1.6,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 22,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _error.isEmpty
                          ? (widget.controller.hasDecoyPinConfigured
                                ? Text(
                                    'A decoy PIN is also configured for privacy mode.',
                                    key: const ValueKey<String>('decoy'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: kKhataAmber),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox.shrink())
                          : Text(
                              _error,
                              key: const ValueKey<String>('error'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: kKhataDanger),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      ...List<Widget>.generate(9, (index) {
                        final digit = '${index + 1}';
                        return _LockPadButton(
                          label: digit,
                          onTap: () => _appendDigit(digit),
                        );
                      }),
                      _LockPadIconButton(
                        icon: Icons.backspace_outlined,
                        onTap: _removeDigit,
                      ),
                      _LockPadButton(
                        label: '0',
                        onTap: () => _appendDigit('0'),
                      ),
                      _LockPadIconButton(
                        icon: Icons.check_rounded,
                        onTap: _submitting ? null : _unlock,
                        filled: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_biometricAvailable)
                    FilledButton.tonalIcon(
                      onPressed: _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use fingerprint'),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showForgotPinHelp,
                    child: const Text('Forgot PIN?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockPadButton extends StatelessWidget {
  const _LockPadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _LockPadIconButton extends StatelessWidget {
  const _LockPadIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? kKhataGreen : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            color: filled
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
