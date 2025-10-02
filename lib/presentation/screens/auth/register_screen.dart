// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../core/constants/app_constants.dart';
// import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _fullNameController = TextEditingController();

//   String _selectedRole = AppConstants.rolePurchasing;
//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _usernameController.dispose();
//     _fullNameController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleRegister() async {
//     if (_formKey.currentState!.validate()) {
//       await ref.read(authStateProvider.notifier).signUp(
//             email: _emailController.text.trim(),
//             password: _passwordController.text,
//             username: _usernameController.text.trim(),
//             fullName: _fullNameController.text.trim(),
//             role: _selectedRole,
//           );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authStateProvider);

//     // Show success/error messages
//     ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
//       if (next.hasError) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Registration failed: ${next.error}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       } else if (next.hasValue && next.value != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Registration successful!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     });

//     return Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => context.go('/login'),
//           ),
//         ),
//         body: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxWidth: 400, // Batas maksimal lebar di desktop
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 24),
//                     Text(
//                       'Create Account',
//                       style:
//                           Theme.of(context).textTheme.headlineMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Register to get started',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             color: Colors.grey,
//                           ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 32),

//                     // Full Name
//                     TextFormField(
//                       controller: _fullNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Full Name',
//                         prefixIcon: Icon(Icons.person),
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter full name';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Username
//                     TextFormField(
//                       controller: _usernameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Username',
//                         prefixIcon: Icon(Icons.account_circle),
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter username';
//                         }
//                         if (value.length < 3) {
//                           return 'Username must be at least 3 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Email
//                     TextFormField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: const InputDecoration(
//                         labelText: 'Email',
//                         prefixIcon: Icon(Icons.email),
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter email';
//                         }
//                         if (!value.contains('@')) {
//                           return 'Please enter valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Password
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: !_isPasswordVisible,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: const Icon(Icons.lock),
//                         border: const OutlineInputBorder(),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isPasswordVisible
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isPasswordVisible = !_isPasswordVisible;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter password';
//                         }
//                         if (value.length < 6) {
//                           return 'Password must be at least 6 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Confirm Password
//                     TextFormField(
//                       controller: _confirmPasswordController,
//                       obscureText: !_isConfirmPasswordVisible,
//                       decoration: InputDecoration(
//                         labelText: 'Confirm Password',
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         border: const OutlineInputBorder(),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isConfirmPasswordVisible
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isConfirmPasswordVisible =
//                                   !_isConfirmPasswordVisible;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please confirm password';
//                         }
//                         if (value != _passwordController.text) {
//                           return 'Passwords do not match';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Role Dropdown
//                     DropdownButtonFormField<String>(
//                       initialValue: _selectedRole,
//                       decoration: const InputDecoration(
//                         labelText: 'Role',
//                         prefixIcon: Icon(Icons.work),
//                         border: OutlineInputBorder(),
//                       ),
//                       items: const [
//                         DropdownMenuItem(
//                           value: AppConstants.rolePurchasing,
//                           child: Text('Purchasing'),
//                         ),
//                         DropdownMenuItem(
//                           value: AppConstants.roleWarehouse,
//                           child: Text('Warehouse'),
//                         ),
//                         DropdownMenuItem(
//                           value: AppConstants.roleFinance,
//                           child: Text('Finance'),
//                         ),
//                         DropdownMenuItem(
//                           value: AppConstants.roleAdmin,
//                           child: Text('Admin'),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedRole = value!;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 24),

//                     // Register Button
//                     SizedBox(
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: authState.isLoading ? null : _handleRegister,
//                         style: ElevatedButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: authState.isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.white,
//                                   ),
//                                 ),
//                               )
//                             : const Text(
//                                 'Register',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Login Link
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text('Already have an account?'),
//                         TextButton(
//                           onPressed: () => context.go('/login'),
//                           child: const Text('Login here'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ));
//   }
// }
