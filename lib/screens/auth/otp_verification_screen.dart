import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/user_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String password;
  final String? phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.password,
    this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Verify OTP - pass registration data so a new user is created
      // with the full name / password / phone number from the register form.
      final otpSuccess = await userProvider.verifyOtp(
        widget.email,
        _otpController.text.trim(),
        fullName: widget.fullName.isNotEmpty ? widget.fullName : null,
        password: widget.password.isNotEmpty ? widget.password : null,
        phone: widget.phoneNumber,
      );

      if (!mounted) return;

      if (otpSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pushReplacementNamed(context, '/schedule');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_countdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await userProvider.requestOtp(widget.email);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        setState(() {
          _countdown = 60;
        });
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive horizontal padding: wider on tablets/desktop (>600px)
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = isWide ? 48.0 : 24.0;
            final maxFormWidth = 480.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'We sent a verification code to\n${widget.email}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // OTP Field
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP Code',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP code';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 digits';
                            }
                            if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                              return 'OTP must contain only digits';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Verify Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerifyOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify Email'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Resend OTP
                        Center(
                          child: TextButton(
                            onPressed: _countdown > 0 || _isResending
                                ? null
                                : _handleResendOtp,
                            child: Text(
                              _countdown > 0
                                  ? 'Resend OTP in $_countdown s'
                                  : _isResending
                                  ? 'Resending...'
                                  : 'Resend OTP',
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Back to Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already verified?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
