import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart';

http.Client createStreamingHttpClient() => FetchClient(mode: RequestMode.cors);
