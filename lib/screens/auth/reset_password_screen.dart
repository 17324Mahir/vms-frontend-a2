import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';

enum _ResetStep {
  requestOtp,
  verifyOtpAndReset,
  success,
}

/// Screen allowing registered users to verify their account via email OTP
/// and reset their account password.
/// Follows the Stark Group design system: neutral canvas, crisp white card, and high-contrast typography.
class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _verifyFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _codeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  _ResetStep _currentStep = _ResetStep.requestOtp;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  String? _errorMessage;
  String? _infoNotice;
  String? _demoOtp;
  bool _emailSent = false;
  String? _accountEmail;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    setState(() {
      _errorMessage = null;
      _infoNotice = null;
    });

    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final result = await AuthService.instance.sendPasswordResetCode(email);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _accountEmail = email;
          _demoOtp = result.demoOtp;
          _emailSent = result.emailSent;
          _infoNotice = result.message;
          _currentStep = _ResetStep.verifyOtpAndReset;
        });
        _codeFocusNode.requestFocus();
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
          _errorMessage = 'An unexpected error occurred while requesting verification code.';
        });
      }
    }
  }

  Future<void> _handleVerifyAndReset() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_verifyFormKey.currentState!.validate()) {
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
      final msg = await AuthService.instance.verifyResetCode(
        _accountEmail ?? _emailController.text.trim(),
        _codeController.text.trim(),
        newPass,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _infoNotice = msg;
          _currentStep = _ResetStep.success;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _codeController.clear();
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
          _errorMessage = 'An unexpected error occurred while resetting password.';
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
              constraints: const BoxConstraints(maxWidth: 460),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrandHeader(),
                      const SizedBox(height: AppTheme.space20),
                      const Divider(height: 1),
                      const SizedBox(height: AppTheme.space20),

                      // Step 1: Request OTP by Email
                      if (_currentStep == _ResetStep.requestOtp) ...[
                        _buildRequestOtpStep(),
                      ] else if (_currentStep == _ResetStep.verifyOtpAndReset) ...[
                        _buildVerifyOtpStep(),
                      ] else if (_currentStep == _ResetStep.success) ...[
                        _buildSuccessStep(),
                      ],

                      const SizedBox(height: AppTheme.space16),

                      // Back to Sign In Link
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
              'Security Advisory: This is an educational demo portal. Do not use personal Google or email passwords. Use a demo fleet password (e.g. Password123!).',
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

  Widget _buildRequestOtpStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            'Enter your registered email address to verify your account and receive a 6-digit verification code.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: AppTheme.space16),

          _buildSecurityAdvisory(),
          const SizedBox(height: AppTheme.space16),

          if (_errorMessage != null) ...[
            _buildErrorAlert(_errorMessage!),
            const SizedBox(height: AppTheme.space16),
          ],

          // Email Field
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
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) => _handleRequestOtp(),
            decoration: const InputDecoration(
              hintText: 'e.g. test@starkgroup.test',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Please enter your registered email address.';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(trimmed)) return 'Please enter a valid email address.';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space20),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleRequestOtp,
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
                : const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AppTheme.space16),

          // Pre-fill Demo Account Helper
          OutlinedButton.icon(
            onPressed: () {
              _emailController.text = 'test@starkgroup.test';
            },
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Pre-fill Demo Account (test@starkgroup.test)', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: const BorderSide(color: AppTheme.borderNeutral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyOtpStep() {
    return Form(
      key: _verifyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentStep = _ResetStep.requestOtp;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Verify Code & Set Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            _emailSent
                ? 'A 6-digit verification code was sent to your inbox: ${_accountEmail ?? _emailController.text.trim()}.'
                : 'A 6-digit verification code was generated for ${_accountEmail ?? _emailController.text.trim()}.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: AppTheme.space16),

          // Demo Mode OTP Box
          if (_demoOtp != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Blue 50
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: const Color(0xFFBFDBFE)), // Blue 200
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 18, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Demo Environment OTP Code:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _codeController.text = _demoOtp!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Text(
                            'Auto-Fill Code',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _demoOtp!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppTheme.navy900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
          ],

          if (_errorMessage != null) ...[
            _buildErrorAlert(_errorMessage!),
            const SizedBox(height: AppTheme.space16),
          ],

          // OTP Code Field
          const Text(
            '6-Digit Verification Code',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: AppTheme.space4),
          TextFormField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '123456',
              prefixIcon: Icon(Icons.lock_clock_outlined, size: 18),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Please enter the 6-digit verification code.';
              if (trimmed.length != 6) return 'Verification code must be exactly 6 digits.';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),

          // New Password Field
          const Text(
            'New Password',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
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
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
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
          const SizedBox(height: AppTheme.space16),

          // Confirm Password Field
          const Text(
            'Confirm New Password',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
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
            onFieldSubmitted: (_) => _handleVerifyAndReset(),
            decoration: InputDecoration(
              hintText: 'Re-enter new password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
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
          const SizedBox(height: AppTheme.space20),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleVerifyAndReset,
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
                : const Text('Verify Code & Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AppTheme.space12),

          // Pre-fill Safe Test Password Helper
          OutlinedButton.icon(
            onPressed: () {
              _passwordController.text = 'Password123!';
              _confirmPasswordController.text = 'Password123!';
            },
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Fill Test Password (Password123!)', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: const BorderSide(color: AppTheme.borderNeutral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5), // Emerald 50
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: const Color(0xFFA7F3D0)), // Emerald 200
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 40, color: Color(0xFF059669)),
              const SizedBox(height: AppTheme.space12),
              const Text(
                'Password Successfully Updated!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                _infoNotice ?? 'Your password has been changed. You can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF065F46),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space24),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
          },
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Proceed to Sign In'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
