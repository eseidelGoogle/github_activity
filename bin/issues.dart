import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:perf/config.dart';

dynamic main(List args) async {
  assert(args.length > 1);
  String author = args.last;

  DateTime now = new DateTime.now();
  DateTime since = now.subtract(new Duration(days: 180));
  print("Pulling issues since $since");

// Would like to know involvement rates in PRs
// https://github.com/flutter/plugins/pulls?utf8=%E2%9C%93&q=is%3Apr+is%3Aclosed+involves%3Acollinjackson+-author%3Acollinjackson+

// Issues (authored, involved)
// PRs (authored, reviewed, involved)

  String sinceString = since.toIso8601String().substring(0, 10);

  String authoredIssueQuery =
      "is:issue author:$author org:flutter created:>=$sinceString";
  String involvedIssueQuery =
      "is:issue involves:$author -author:$author org:flutter created:>=$sinceString";
  String authoredPrQuery =
      "is:pr author:$author org:flutter created:>=$sinceString";
  String reviewedPrQuery =
      "is:pr reviewed-by:$author org:flutter closed:>=$sinceString";
  String involvedPrQuery =
      "is:pr involves:$author -author:$author org:flutter created:>=$sinceString";

  int authoredIssues = await countIssues(authoredIssueQuery);
  int involvedIssues = await countIssues(involvedIssueQuery);
  int authoredPrs = await countIssues(authoredPrQuery);
  int reviewedPrs = await countIssues(reviewedPrQuery);
  int involvedPrs = await countIssues(involvedPrQuery);

  print(
      "GitHub PRs (authored: $authoredPrs, reviewed: $reviewedPrs, involved: $involvedPrs); Issues (authored: $authoredIssues, involved: $involvedIssues)");
}

Future<int> countIssues(String query) async {
  return (await searchIssues(query))['total_count'];
}

Future<Map> searchIssues(String query) async {
  Uri uri = new Uri(
      scheme: 'https',
      host: 'api.github.com',
      path: 'search/issues',
      queryParameters: {
        'q': query,
      });
  var response =
      await http.get(uri, headers: {'Authorization': 'token $token'});
  if (response.statusCode != 200) {
    print("Error ${response.statusCode}");
    print(response.body);
    return {};
  }
  return json.decode(response.body);
}
