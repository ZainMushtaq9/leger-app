import 'package:flutter/material.dart';

import '../controller.dart';

enum _AuthMode { login, register, forgotPassword }

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      switch (_mode) {
        case _AuthMode.login:
          await widget.controller.signInToCloudAccountWithCredentials(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );
          _showSnack('Signed in successfully.');
          break;
        case _AuthMode.register:
          await widget.controller.registerCloudAccount(
            displayName: _nameController.text,
            email: _emailController.text,
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
          );
          _showSnack('Account created. Verify your email to continue.');
          break;
        case _AuthMode.forgotPassword:
          await widget.controller.sendCloudPasswordReset(
            identifier: _identifierController.text,
          );
          _showSnack('Password reset email sent.');
          break;
      }
    } catch (error) {
      _showSnack(_cleanError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
    });
    try {
      await widget.controller.signInToCloudAccountWithGoogle();
      _showSnack('Signed in with Google.');
    } catch (error) {
      _showSnack(_cleanError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _switchMode(_AuthMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
    });
  }

  String _cleanError(Object error) {
    final text = error.toString().trim();
    if (text.startsWith('Bad state: ')) {
      return text.substring('Bad state: '.length);
    }
    return text;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to your workspace to unlock your shop ledger, backups, and reports.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Login'),
                        selected: _mode == _AuthMode.login,
                        onSelected: (_) => _switchMode(_AuthMode.login),
                      ),
                      ChoiceChip(
                        label: const Text('Register'),
                        selected: _mode == _AuthMode.register,
                        onSelected: (_) => _switchMode(_AuthMode.register),
                      ),
                      ChoiceChip(
                        label: const Text('Forgot Password'),
                        selected: _mode == _AuthMode.forgotPassword,
                        onSelected: (_) =>
                            _switchMode(_AuthMode.forgotPassword),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.06,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: switch (_mode) {
                            _AuthMode.login => _buildLoginForm(),
                            _AuthMode.register => _buildRegisterForm(),
                            _AuthMode.forgotPassword =>
                              _buildForgotPasswordForm(),
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey<String>('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email or phone number'),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Enter your email or phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Enter your password';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Signing in...' : 'Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signInWithGoogle,
          icon: const Icon(Icons.account_circle_rounded),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _busy
                ? null
                : () => _switchMode(_AuthMode.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey<String>('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email address'),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty || !text.contains('@')) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'Optional, used for phone-based login',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Confirm password',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim() != _passwordController.text.trim()) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Creating account...' : 'Register'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signInWithGoogle,
          icon: const Icon(Icons.account_circle_rounded),
          label: const Text('Continue with Google'),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm() {
    return Column(
      key: const ValueKey<String>('forgot'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Enter the email address or phone number linked to your account. We will send the password reset email to the registered email.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Email or phone number'),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Enter your email or phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Sending...' : 'Send Reset Email'),
        ),
      ],
    );
  }
}
