import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onLoginSuccess;

  const SignInScreen({
    super.key,
    required this.state,
    required this.onLoginSuccess,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _staffIdController = TextEditingController(text: 'HN-00312');
  final _passwordController = TextEditingController(text: '123');
  String _selectedRole = 'Head Nurse (Shift Lead)';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final staffId = _staffIdController.text.trim();
    final password = _passwordController.text.trim();

    if (staffId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Staff ID.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.state.signInWithFirebase(staffId, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = 'Invalid Staff ID or Password. Please verify your credentials.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: AppColors.criticalRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerySmall = context.isVerySmallPhone;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 12.0 : 20.0,
              vertical: isVerySmall ? 16.0 : 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Sign In Card Container
                  Container(
                    padding: EdgeInsets.all(isVerySmall ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section with Logo
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.monitor_heart,
                                        size: 24,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'VITALERT',
                                    style: AppTypography.headlineLg(color: AppColors.textMain).copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NephroAsia Dialysis Center',
                                style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.borderLight, height: 1),
                        const SizedBox(height: 16),

                        // Title Section
                        Text(
                          'Sign In',
                          style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nurse station access · Authorized Personnel Only',
                          style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner (if any)
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Staff ID Field
                        Text(
                          'STAFF ID',
                          style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _staffIdController,
                          style: AppTypography.bodyLg(color: AppColors.textMain).copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. HN-00312 or SN-00123',
                            hintStyle: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        Text(
                          'PASSWORD',
                          style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: AppTypography.bodyLg(color: AppColors.textMain).copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            hintStyle: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Clinical Role Dropdown
                        Text(
                          'CLINICAL ROLE',
                          style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 18),
                              style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 13),
                              items: [
                                'Head Nurse (Shift Lead)',
                                'Staff Nurse',
                              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRole = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Access Nurse Station',
                                        style: AppTypography.bodyLg(
                                          color: Colors.white,
                                          weight: FontWeight.bold,
                                        ).copyWith(fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_rounded, size: 14),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer
                  Text(
                    'VITALERT Clinical Suite v1.0 · NephroAsia Dialysis Center',
                    style: AppTypography.bodyMd(
                      color: AppColors.textMuted,
                      fontSize: 11,
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
}
