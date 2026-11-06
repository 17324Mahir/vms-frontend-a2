import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/brand/stark_logo.dart';

/// Admin Login screen for the Stark Group VMS.
///
/// Authenticates against Spring Boot POST /api/auth/login, receiving a signed JWT access token.
/// Employs full inline validation, keyboard submission, loading indicators, and error mapping.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _authErrorMessage;
  bool _initializedFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      _initializedFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = args;
        _passwordFocusNode.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _authErrorMessage = null;
    });
    AuthService.instance.clearExpiredNotice();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text; // Do NOT trim password

    if (email.toLowerCase() == 'test' ||
        email.toLowerCase() == 'admin' ||
        email.toLowerCase() == 'demo') {
      email = 'test@starkgroup.test';
      if (password.isEmpty) {
        password = 'Password123!';
        _passwordController.text = password;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.login(email, password);

      if (!mounted) return;

      TextInput.finishAutofillContext();
      _passwordController.clear();
      setState(() => _isSubmitting = false);

      Navigator.of(context).pushReplacementNamed(AppRouter.dashboardRoute);
    } on ApiException catch (e) {
      if (!mounted) return;
      _passwordController.clear();
      setState(() {
        _isSubmitting = false;
        _authErrorMessage = e.message;
      });
      _passwordFocusNode.requestFocus();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _authErrorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      _passwordController.clear();
      setState(() {
        _isSubmitting = false;
        _authErrorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrandHeader(),
              const SizedBox(height: AppTheme.space24),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space24),
              ValueListenableBuilder<String?>(
                valueListenable: AuthService.instance.sessionExpiredMessage,
                builder: (context, sessionNotice, _) {
                  if (sessionNotice != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space16),
                      child: _buildSessionNoticeAlert(sessionNotice),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_authErrorMessage != null) ...[
                _buildAuthErrorAlert(_authErrorMessage!),
                const SizedBox(height: AppTheme.space16),
              ],
              _buildEmailField(),
              const SizedBox(height: AppTheme.space16),
              _buildPasswordField(),
              const SizedBox(height: AppTheme.space24),
              _buildSubmitButton(),
              const SizedBox(height: AppTheme.space16),
              _buildDemoCredentialsBox(),
              const SizedBox(height: AppTheme.space16),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarkLogo.light(size: StarkLogoSize.medium, showBadge: true),
        SizedBox(height: AppTheme.space16),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: AppTheme.space4),
        Text(
          'Enter your credentials to access the fleet registry.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionNoticeAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.statusMaintenanceBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.statusMaintenanceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.statusMaintenanceText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.statusMaintenanceText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthErrorAlert(String message) {
    final currentEmail = _emailController.text.trim();
    final isInvalidCreds =
        message.toLowerCase().contains('incorrect') ||
        message.toLowerCase().contains('invalid');

    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.errorRedBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.errorRedBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: AppTheme.errorRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (isInvalidCreds && currentEmail.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRouter.registerRoute,
                  arguments: currentEmail,
                );
              },
              child: Row(
                children: const [
                  Icon(
                    Icons.person_add_outlined,
                    size: 14,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Don\'t have an account? Register as new user',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _emailController,
          enabled: !_isSubmitting,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: const InputDecoration(hintText: 'user@example.com'),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Please enter your email address.';
            }
            final lower = trimmed.toLowerCase();
            if (lower == 'test' ||
                lower == 'admin' ||
                lower == 'demo' ||
                lower == 'fleet') {
              return null;
            }
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(trimmed)) {
              return 'Please enter a valid email address.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRouter.resetPasswordRoute,
                  arguments: _emailController.text.trim(),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          enabled: !_isSubmitting,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSubmit(),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      child: _isSubmitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Sign in'),
    );
  }

  Widget _buildDemoCredentialsBox() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Blue 50
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFBFDBFE)), // Blue 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.vpn_key_outlined,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 6),
              Text(
                'Demo Credentials',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Email: test@starkgroup.test\nPassword: Password123!',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textDark,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _emailController.text = 'test@starkgroup.test';
                      _passwordController.text = 'Password123!';
                    });
                    _handleSubmit();
                  },
            icon: const Icon(Icons.flash_on, size: 16),
            label: const Text(
              '1-Click Sign In as Demo Admin',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _emailController.text = 'test@starkgroup.test';
                _passwordController.text = 'Password123!';
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 6),
              minimumSize: const Size(0, 32),
              side: const BorderSide(color: AppTheme.primaryBlue),
            ),
            child: const Text(
              'Auto-fill Form Fields Only',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            TextButton(
              onPressed: () {
                final email = _emailController.text.trim();
                Navigator.of(context).pushReplacementNamed(
                  AppRouter.registerRoute,
                  arguments: email.isNotEmpty ? email : null,
                );
              },
              child: const Text(
                'Register here',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (AppRouter.isWebWorkspace)
          TextButton.icon(
            onPressed: () {
              AppRouter.returnToHome(context);
            },
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Return to Home', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
