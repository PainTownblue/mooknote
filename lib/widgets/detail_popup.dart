import 'package:flutter/material.dart';

/// 平板宽屏下的详情弹窗：居中圆角卡片承载详情页
Future<T?> showDetailPopup<T>(BuildContext context, Widget child) {
  final size = MediaQuery.of(context).size;
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MediaQuery.removePadding(
          context: ctx,
          removeTop: true,
          child: SizedBox(
            width: size.width >= 900 ? 560 : double.infinity,
            height: size.height * 0.92,
            child: child,
          ),
        ),
      ),
    ),
  );
}
