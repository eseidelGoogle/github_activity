import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:perf/config.dart';

DateTime fromGitHubStamp(int stamp) {
  return new DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
}

Duration timeUntil(DateTime future) {
  return future.difference(new DateTime.now());
}

dynamic main(List args) async {
  Uri uri = new Uri(
    scheme: 'https',
    host: 'api.github.com',
    path: 'rate_limit',
  );
  var response =
      await http.get(uri, headers: {'Authorization': 'token $token'});
  Map responseMap = json.decode(response.body);
  Map limits = responseMap['rate'];
  Map search = responseMap['resources']['search'];

  Duration limitsUntil = timeUntil(fromGitHubStamp(limits['reset']));
  print("${limits['remaining']} of ${limits['limit']}, resets $limitsUntil");
  Duration searchUntil = timeUntil(fromGitHubStamp(search['reset']));
  print("${search['remaining']} of ${search['limit']}, resets $searchUntil");
}
