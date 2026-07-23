import 'package:http/http.dart' as http;
import 'streaming_client_io.dart' if (dart.library.js_interop) 'streaming_client_web.dart';

http.Client getStreamingHttpClient() => createStreamingHttpClient();
