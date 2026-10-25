import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// 为在线搜索 API 构造 HTTP 客户端；[proxy] 形如 `127.0.0.1:7890`，空则直连。
http.Client buildProxyClient(String proxy) {
  final p = proxy.trim();
  if (p.isEmpty) return http.Client();
  final ioClient = HttpClient()..findProxy = (uri) => 'PROXY $p';
  return IOClient(ioClient);
}
