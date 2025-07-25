import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';

class AddCompleteScreen extends StatelessWidget {
  const AddCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TakingViewModel>(
      create: (_) => TakingViewModel(),
      child: const _AddCompleteScreenBody(),
    );
  }
}

class _AddCompleteScreenBody extends StatelessWidget {
  const _AddCompleteScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Remove app bar space
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "생성 완료!" button/text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                '생성 완료!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Clover image
            Image.asset(
              'assets/clover.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 50),
            // "확인" button
            GestureDetector(
              onTap: () {
                context.go('/taking-list');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF232B3A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}