import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 毛玻璃主题背景层：封面图 + 模糊 + 深色遮罩
/// 用 ImageFiltered 模糊静态图片（开销低于 BackdropFilter 实时模糊）
class FrostedBackground extends StatelessWidget {
  final String? coverPath;

  const FrostedBackground({super.key, this.coverPath});

  @override
  Widget build(BuildContext context) {
    if (coverPath == null || coverPath!.isEmpty) {
      // 无封面兜底：纯色玻璃底
      return const ColoredBox(color: Color(0xFF121418));
    }
    // 模糊背景无需原图分辨率，按屏幕物理宽解码并封顶，避免超大封面解码 OOM
    final mq = MediaQuery.of(context);
    final decodeWidth =
        (mq.size.width * mq.devicePixelRatio).clamp(1, 1080).toInt();
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Image.file(
            File(coverPath!),
            fit: BoxFit.cover,
            cacheWidth: decodeWidth,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF121418)),
          ),
        ),
        // 深色遮罩，保证内容可读
        const ColoredBox(color: Color(0x73000000)), // 黑 ~45%
      ],
    );
  }
}