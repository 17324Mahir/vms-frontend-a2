import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';

/// Screen allowing registered users to directly reset their account password.
/// Follows the unified design system: light neutral canvas, crisp white card, and high-contrast typography.
class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final msg = await AuthService.instance.resetPassword(
        _emailController.text.trim(),
        newPass,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _successMessage = msg;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An unexpected error occurred while resetting password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: AppTheme.surfaceWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: const BorderSide(color: AppTheme.borderNeutral),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 400
                        ? AppTheme.space20
                        : AppTheme.space32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: AppTheme.space20),
                        const Divider(height: 1),
                        const SizedBox(height: AppTheme.space20),

                        // Title & Subtitle
                        const Text(
                          'Reset Account Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        const Text(
                          'Enter your registered email address and choose a new password.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // Educational advisory
                        _buildSecurityAdvisory(),
                        const SizedBox(height: AppTheme.space16),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          _buildErrorAlert(_errorMessage!),
                          const SizedBox(height: AppTheme.space16),
                        ],

                        // Success Banner
                        if (_successMessage != null) ...[
                          _buildSuccessAlert(_successMessage!),
                          const SizedBox(height: AppTheme.space20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Proceed to Sign In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                        ] else ...[
                          // Form Inputs
                          _buildEmailField(),
                          const SizedBox(height: AppTheme.space16),
                          _buildPasswordField(),
                          const SizedBox(height: AppTheme.space16),
                          _buildConfirmPasswordField(),
                          const SizedBox(height: AppTheme.space20),

                          // Submit Button
                          _buildSubmitButton(),
                          const SizedBox(height: AppTheme.space16),

                          // Demo auto-fill option
                          _buildDemoHelper(),
                          const SizedBox(height: AppTheme.space16),
                        ],

                        // Return to Login Link
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
                            },
                            icon: const Icon(Icons.arrow_back, size: 14),
                            label: const Text('Back to Sign In', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.navy900,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Text(
            'STARK GROUP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.borderSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.borderNeutral),
          ),
          child: const Text(
            'VMS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityAdvisory() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFCBD5E1)), // Slate 300
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, size: 18, color: AppTheme.navy900),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Educational Fleet Portal: Do not use your personal email password. Set a test password such as Password123!.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.navy900,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.errorRedBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.errorRedBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.errorRed),
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
    );
  }

  Widget _buildSuccessAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5), // Emerald 50
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFA7F3D0)), // Emerald 200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registered Email Address',
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
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: const InputDecoration(
            hintText: 'e.g. test@starkgroup.test',
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'Please enter your registered email address.';
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(trimmed)) return 'Please enter a valid email address.';
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
        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          enabled: !_isSubmitting,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Minimum 6 characters',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'Please enter a new password.';
            if (trimmed.length < 6) return 'Password must be at least 6 characters.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm New Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          enabled: !_isSubmitting,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => _handleReset(),
          decoration: InputDecoration(
            hintText: 'Re-enter new password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'Please confirm your new password.';
            if (trimmed != _passwordController.text.trim()) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleReset,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDemoHelper() {
    return OutlinedButton.icon(
      onPressed: () {
        _emailController.text = 'test@starkgroup.test';
        _passwordController.text = 'Password123!';
        _confirmPasswordController.text = 'Password123!';
      },
      icon: const Icon(Icons.flash_on_rounded, size: 16),
      label: const Text('Pre-fill with Demo Account', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: const BorderSide(color: AppTheme.borderNeutral),
      ),
    );
  }
}
