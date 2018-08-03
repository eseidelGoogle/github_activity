import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:perf/config.dart';

dynamic main(List args) async {
  assert(args.length > 1);
  String author = args.last;

  DateTime now = new DateTime.now();
  DateTime since = now.subtract(new Duration(days: 30));
  print("Pulling commits since $since");
  List<String> countStrings = [];
  for (String repoName in repos) {
    stdout.write("checking $repoName...");
    int count = (await commitsSince(repoName, author, since)).length;
    if (count > 0) countStrings.add("$count to $repoName");
    stdout.write(" $count\n");
  }
  print(countStrings.join(', '));
}

Future<List<Map>> commitsSince(
    String repoName, String author, DateTime since) async {
  List commits = [];
  bool haveNext = true;
  int maxRequests = 10;
  int page = 0;
  while (haveNext && maxRequests > 0) {
    page += 1;
    maxRequests -= 1;
    Uri uri = new Uri(
        scheme: 'https',
        host: 'api.github.com',
        path: 'repos/$repoName/commits',
        queryParameters: {
          'author': author,
          'since': since.toIso8601String(),
          'per_page': '100',
          'page': page.toString(),
        });
    var response =
        await http.get(uri, headers: {'Authorization': 'token $token'});
    if (response.statusCode != 200) {
      print("Error ${response.statusCode} checking $repoName.");
      return [];
    }
    haveNext = response.headers['link'] != null;
    commits.addAll(json.decode(response.body));
  }
  return commits;
}
