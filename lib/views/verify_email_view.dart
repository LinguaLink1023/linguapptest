import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer show log;

import 'package:linguapp/constants/routes.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Verify')),
      body: Column(
        children: [
          const Text('已发送验证链接至您的邮箱，请先验证'),
          const Text('如果没有收到，点击下面按钮重新发送'),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              developer.log((user?.emailVerified).toString());
              developer.log((user?.email).toString());

              await user?.sendEmailVerification();

              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text('Send email verification.'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}
