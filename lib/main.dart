import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_js/extensions/fetch.dart';
import 'package:flutter_js/flutter_js.dart';

class JSRuntime {
  final JavascriptRuntime _runtime = getJavascriptRuntime();

  static const _internalCode = """async function callFetch(type) {
    const response = await fetch("https://flutterjs-test.nightskystudio.workers.dev/" + type);
    const json = await response.json();
    return JSON.stringify({
      "result": json,
      "type": typeof(json)
    });
}
""";

  JSRuntime() {
    _runtime.evaluate(_internalCode);
  }

  JsEvalResult runtimeEval(String code) => _runtime.evaluate(code);

  Future<JsEvalResult> runtimeEvalAsync(String code) async {
    await _runtime.enableFetch();
    _runtime.enableHandlePromises();

    var asyncResult = await _runtime.evaluateAsync(code);
    _runtime.executePendingJob();

    final promiseResolved = await _runtime.handlePromise(asyncResult);

    return promiseResolved;
  }

  Future<String> callFetch(String type) async {
    final String code = "callFetch(\"$type\")";
    JsEvalResult result = await runtimeEvalAsync(code); 

    String json = result.stringResult.replaceAll("\\\"", "\"");
    return json;
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends HookWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final JSRuntime jsRuntime = JSRuntime();

    final output = useState("");
    final jsonOutput = useState("");
    final requestType = useState("normal");

    const options = [
      DropdownMenuItem(value: "normal", child: Text("Normal")),
      DropdownMenuItem(value: "faulty", child: Text("Faulty")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          children: [
            DropdownButton(value: requestType.value, items: options, onChanged: (value) => requestType.value = value as String),
            const Text("Text output:"),
            Text(output.value),
            const Text("JSON output:"),
            Text(jsonOutput.value),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        output.value = await jsRuntime.callFetch(requestType.value);

        try {
          Map json = jsonDecode(output.value);
          List<String> decodedMap = [];
          json.forEach((key, value) {
            decodedMap.add("$key = $value");
          });
          jsonOutput.value = decodedMap.join("\n");
        } catch (e) {
          jsonOutput.value = "Error decoding JSON. Exception: $e";
        }

      }, child: const Icon(Icons.download)),
    );
  }

}