import 'dart:typed_data';
import 'dart:ui' as ui;

/// 用 Flutter 引擎解码任意支持的图片格式（含多数机型的 HEIC），
/// 等比缩放到 [maxSize] 以内后重新编码为 PNG。
///
/// crop_your_image 底层使用 image 包解码，不支持 HEIC 等格式且失败时
/// 会在 isolate 中抛空值异常，因此进入裁剪页前先归一化。
/// 解码失败（格式不支持/文件损坏）返回 null。
Future<Uint8List?> normalizeToPng(Uint8List bytes, {int maxSize = 1080}) async {
  if (bytes.isEmpty) return null;
  try {
    final probe = await ui.instantiateImageCodec(bytes);
    final probeFrame = await probe.getNextFrame();
    final src = probeFrame.image;
    final srcW = src.width;
    final srcH = src.height;
    src.dispose();

    int? targetW;
    int? targetH;
    if (srcW > maxSize || srcH > maxSize) {
      if (srcW >= srcH) {
        targetW = maxSize;
      } else {
        targetH = maxSize;
      }
    }

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetW,
      targetHeight: targetH,
    );
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    if (png == null) return null;
    return png.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
