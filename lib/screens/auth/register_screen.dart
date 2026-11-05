import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/ambient_grid_pattern.dart';
import '../../widgets/animated/border_beam.dart';

/// Screen allowing new users to create an account for the Stark Group VMS.
/// Follows the unified design system: light neutral canvas, crisp white card, and high-contrast typography.
/// Checks existing accounts strictly based on email address.
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

  final _emailFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailAlreadyExists = false;
  String? _existingEmail;
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      _initializedFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = args;
        _checkEmailAvailability();
      }
    }
  }

  void _fillUniqueNewAccount() {
    final rand = DateTime.now().millisecondsSinceEpoch % 100000;
    setState(() {
      _nameController.text = 'Fleet Operator';
      _emailController.text = 'operator$rand@starkfleet.com';
      _passwordController.text = 'Password123!';
      _confirmPasswordController.text = 'Password123!';
      _emailAlreadyExists = false;
      _existingEmail = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      _checkEmailAvailability();
    }
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return;
    }

    try {
      final exists = await AuthService.instance.checkEmailExists(email);
      if (mounted && email == _emailController.text.trim()) {
        setState(() {
          _emailAlreadyExists = exists;
          _existingEmail = exists ? email : null;
          if (exists) {
            _errorMessage = null;
          }
        });
      }
    } catch (_) {
      // Best-effort check; ignore errors
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    final rawEmail = _emailController.text.trim();
    setState(() => _isLoading = true);

    // Explicit pre-check to validate account strictly based on email address
    try {
      final emailExists = await AuthService.instance.checkEmailExists(rawEmail);
      if (emailExists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailAlreadyExists = true;
            _existingEmail = rawEmail;
          });
        }
        return;
      }
    } catch (_) {
      // Continue to register if check endpoint has temporary issue
    }

    try {
      await AuthService.instance.register(
        _nameController.text.trim(),
        rawEmail,
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboardRoute);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 409 || e.code == 'DUPLICATE_EMAIL') {
          setState(() {
            _emailAlreadyExists = true;
            _existingEmail = rawEmail;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = e.message;
          });
        }
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientGridPattern(
              spacing: 28,
              dotRadius: 1.0,
              dotColor: Color(0xFFE2E8F0),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: BorderBeam(
                    borderRadius: AppTheme.radiusLg,
                    beamColor: const Color(0xFF38BDF8),
                    accentColor: AppTheme.primaryBlue,
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
                              // Brand Header
                              _buildBrandHeader(),
                              const SizedBox(height: AppTheme.space20),
                              const Divider(height: 1),
                              const SizedBox(height: AppTheme.space20),

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
                          'Enter your details below to register for the fleet portal.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // Security Advisory banner
                        _buildSecurityAdvisory(),
                        const SizedBox(height: AppTheme.space12),

                        // Quick 1-Click New Account Helper
                        _buildQuickRegistrationHelper(),
                        const SizedBox(height: AppTheme.space16),

                        // Account Already Exists by Email Banner
                        if (_emailAlreadyExists) ...[
                          _buildAccountExistsAlert(_existingEmail ?? _emailController.text.trim()),
                          const SizedBox(height: AppTheme.space16),
                        ],

                        // General Error message banner
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

                        // Email Field (Account Existence Validation strictly on email)
                        const Text(
                          'Email Address *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                          decoration: _inputDecoration('e.g. user@example.com', Icons.email_outlined),
                          onChanged: (_) {
                            if (_emailAlreadyExists) {
                              setState(() => _emailAlreadyExists = false);
                            }
                          },
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
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                          decoration: _inputDecoration('Enter secure fleet password', Icons.lock_outline).copyWith(
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          autocorrect: false,
                          enableSuggestions: false,
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
                        const SizedBox(height: AppTheme.space20),

                        // Submit Register Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: AppTheme.space20),

                        // Login Redirection Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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
  ],
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
              'Security Advisory: This is an educational demo portal. Do not enter personal Google or banking passwords. Create a unique demo password (e.g. Password123!).',
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

  Widget _buildQuickRegistrationHelper() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Emerald 50
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFBBF7D0)), // Emerald 200
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, size: 20, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Quick-Fill Unique Account',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Generate unique credentials with 0 conflicts.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _fillUniqueNewAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            child: const Text('Auto-Fill'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountExistsAlert(String email) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Existing Account Detected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'An account with email "$email" is already registered.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRouter.loginRoute,
                      arguments: email,
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 14),
                  label: const Text('Sign In to Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fillUniqueNewAccount,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Use New Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.textMuted, size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: const BorderSide(color: AppTheme.borderNeutral),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: const BorderSide(color: AppTheme.borderNeutral),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}
