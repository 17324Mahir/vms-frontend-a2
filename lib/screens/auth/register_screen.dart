import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';

/// Screen allowing new users to create an account for the Stark Group VMS.
/// Follows the unified design system: light neutral canvas, crisp white card, and high-contrast typography.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        TextInput.finishAutofillContext();
        // Successfully registered and authenticated; navigate directly to Fleet Dashboard
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboardRoute);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred during registration. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Header
                          _buildBrandHeader(),
                          const SizedBox(height: AppTheme.space24),
                          const Divider(height: 1),
                          const SizedBox(height: AppTheme.space24),

                          // Screen Title & Subtitle
                          const Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space4),
                          const Text(
                            'Enter your details below to create an account.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: AppTheme.space20),

                          // Error message banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRedBg,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.errorRedBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                                  const SizedBox(width: AppTheme.space8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          // Name Field
                          const Text(
                            'Full Name *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                            decoration: _inputDecoration('e.g. Tony Stark', Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name.';
                              }
                              if (value.trim().length > 120) {
                                return 'Full name must not exceed 120 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Email Field
                          const Text(
                            'Email Address *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            autofillHints: const [AutofillHints.email, AutofillHints.username],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                            decoration: _inputDecoration('e.g. user@example.com', Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address.';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Password Field
                          const Text(
                            'Password *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                            decoration: _inputDecoration('Enter secure password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textMuted,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a password.';
                              }
                              if (value.trim().length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              if (value.trim().length > 72) {
                                return 'Password must not exceed 72 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Must be at least 6 characters.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Confirm Password Field
                          const Text(
                            'Confirm Password *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                            decoration: _inputDecoration('Re-enter password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textMuted,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // Submit Register Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Registering account...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ],
                                  )
                                : const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: AppTheme.space16),

                        // Link to Sign In
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                            ),
                          ],
                        ),

                        // Return to Home
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
                          },
                          icon: const Icon(Icons.arrow_back, size: 14, color: AppTheme.textMuted),
                          label: const Text('Return to Home', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandNavy,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'VMS',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Vehicle Management System',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textDisabled, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: AppTheme.textMuted, size: 18),
      filled: true,
      fillColor: AppTheme.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.borderNeutral),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.borderNeutral),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
    );
  }
}
