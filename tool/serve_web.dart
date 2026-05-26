import 'dart:io';

const _defaultPort = 8080;
const _defaultRoot = 'build/web';

Future<void> main(List<String> args) async {
  final port = _readIntArg(args, '--port') ?? _defaultPort;
  final rootPath = _readStringArg(args, '--root') ?? _defaultRoot;
  final root = Directory(rootPath);

  if (!root.existsSync()) {
    stderr.writeln(
      'Website bundle not found at "$rootPath". Run "flutter build web" first.',
    );
    exitCode = 64;
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'Serving ${root.absolute.path} at http://${server.address.host}:$port',
  );

  await for (final request in server) {
    await _serve(request, root);
  }
}

Future<void> _serve(HttpRequest request, Directory root) async {
  if (request.method != 'GET' && request.method != 'HEAD') {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
    await request.response.close();
    return;
  }

  final file = _resolveFile(request.uri, root);
  final contentType = _contentType(file.uri.pathSegments.last);

  request.response.headers
    ..set(HttpHeaders.contentTypeHeader, contentType)
    ..set(HttpHeaders.cacheControlHeader, 'no-cache');

  if (request.method == 'GET') {
    await request.response.addStream(file.openRead());
  }
  await request.response.close();
}

File _resolveFile(Uri requestUri, Directory root) {
  final segments = requestUri.pathSegments
      .where((segment) => segment.isNotEmpty && segment != '..')
      .toList();
  final relativePath = segments.isEmpty ? 'index.html' : segments.join('/');
  final requested = File.fromUri(root.uri.resolve(relativePath));

  if (requested.existsSync() &&
      requested.statSync().type == FileSystemEntityType.file) {
    return requested;
  }

  return File.fromUri(root.uri.resolve('index.html'));
}

String _contentType(String filename) {
  final extension = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';

  return switch (extension) {
    'html' => 'text/html; charset=utf-8',
    'js' => 'application/javascript; charset=utf-8',
    'css' => 'text/css; charset=utf-8',
    'json' => 'application/json; charset=utf-8',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'svg' => 'image/svg+xml',
    'webp' => 'image/webp',
    'ico' => 'image/x-icon',
    'wasm' => 'application/wasm',
    'woff' => 'font/woff',
    'woff2' => 'font/woff2',
    _ => 'application/octet-stream',
  };
}

int? _readIntArg(List<String> args, String name) {
  final raw = _readStringArg(args, name);
  return raw == null ? null : int.tryParse(raw);
}

String? _readStringArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) {
      return args[i + 1];
    }
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}
