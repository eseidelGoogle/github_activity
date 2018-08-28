import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:perf/config.dart';

dynamic main(List<String> args) async {
  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag('cache');
  ArgResults argResults = parser.parse(args);

  List<String> orgs = ['flutter', 'dart-lang'];

  if (argResults['cache']) {
    for (String org in orgs) {
      List<String> repos = await fetchRepoNames(org);
      for (String repoName in repos) {
        String jsonString = await fetchContributorStats(repoName);
        await new File("$repoName.json").writeAsString(jsonString);
      }
    }
  }

  // DateTime now = new DateTime.now();
  // DateTime start = now.subtract(new Duration(days: 180));

  // String jsonString = await fetchContributorStats('flutter/flutter');
  // List authorMaps = json.decode(jsonString);
  // List<Result> results = authorMaps.map<Result>((Map authorMap) {
  //   return new Result()
  //     ..login = authorMap['author']['login']
  //     ..count = countSince(authorMap, start);
  // });
  // results = results.where((a) => a.count > 0).toList();
  // results.sort((a, b) => a.count.compareTo(b.count));
  // results.forEach((result) {
  //   print("${result.login} : ${result.count}");
  // });
}

int countSince(Map authorMap, DateTime start) {
  List<Map> weekMaps = authorMap['weeks'];
  return weekMaps.map<int>((Map weekMap) {
    DateTime weekTime =
        new DateTime.fromMillisecondsSinceEpoch(weekMap['w'] * 1000);
    return weekTime.isAfter(start) ? weekMap['c'] : 0;
  }).reduce((a, b) => a + b);
}

Future<String> fetchContributorStats(String repoName) async {
  int retries = 3;
  while (retries > 0) {
    Uri uri = new Uri(
      scheme: 'https',
      host: 'api.github.com',
      path: 'repos/$repoName/stats/contributors',
    );
    var response =
        await http.get(uri, headers: {'Authentication': 'token $token'});

    if (response.statusCode == 202) {
      print("202.  Waiting 20s before retry.");
      sleep(new Duration(seconds: 20));
      continue;
    }

    return response.body;
  }
  return null;
}

Future<List<String>> fetchRepoNames(String org) async {
  String jsonString = await fetchReposList(org);
  List<Map> reposMaps = json.decode(jsonString);
  return reposMaps.map((Map reposMap) => reposMap['full_name']).toList();
}

Future<String> fetchReposList(String org) async {
  Uri uri = new Uri(
    scheme: 'https',
    host: 'api.github.com',
    path: 'orgs/$org/repos',
  );
  var response =
      await http.get(uri, headers: {'Authorization': 'token $token'});

  return response.body;
}

class Result {
  String login;
  int count;
}
