import 'package:booking/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('主题 token 与视觉规范一致', () {
    expect(AppColors.bg, const Color(0xFFF3F4F6));
    expect(AppColors.brand, const Color(0xFF16A34A));
    expect(AppRadius.card, 14);
  });
}
