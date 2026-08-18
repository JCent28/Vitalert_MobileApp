import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const SignInScreen({super.key, required this.onLoginSuccess});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _staffIdController = TextEditingController(text: 'RN-04812');
  final _pinController = TextEditingController(text: '123456');
  bool _isLoading = false;

  final FocusNode _staffIdFocusNode = FocusNode();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _staffIdFocusNode.addListener(() => setState(() {}));
    _pinFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _pinController.dispose();
    _staffIdFocusNode.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10006063),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          size: 44,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Title & Subtitle
                  Text(
                    'VITALERT',
                    style: AppTypography.headlineLg(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NephroAsia Dialysis Center',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  // Staff ID
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'STAFF ID',
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurface,
                        fontSize: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _staffIdFocusNode.hasFocus
                            ? AppColors.primaryContainer
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _staffIdController,
                      focusNode: _staffIdFocusNode,
                      style: AppTypography.bodyLg(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: _staffIdFocusNode.hasFocus
                              ? AppColors.primaryContainer
                              : AppColors.outline,
                        ),
                        hintText: 'RN-04812',
                        hintStyle: AppTypography.bodyLg(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PIN',
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurface,
                        fontSize: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _pinFocusNode.hasFocus
                            ? AppColors.primaryContainer
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      obscureText: true,
                      style: AppTypography.bodyLg(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: _pinFocusNode.hasFocus
                              ? AppColors.primaryContainer
                              : AppColors.outline,
                        ),
                        hintText: '••••••',
                        hintStyle: AppTypography.bodyLg(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: AppTypography.bodyLg(
                                color: AppColors.onPrimary,
                                weight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    'VITALERT v1.0',
                    style: AppTypography.labelCaps(
                      color: AppColors.outline,
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
