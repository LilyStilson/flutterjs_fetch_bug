# flutterjs_fetch_bug

Repository, demonstrating a bug with flutter_js library with its fetch functionality.

## The bug
Apparently, `fetch` in `flutter_js` library is not working properly. It does not escape automatically special characters in the response body, which leads to inability to parse the response as JSON.
I made this repository and a Cloudflare worker to demonstrate the bug.

### Faulty behavior
After I do this
```javascript
let response = await fetch("https://flutterjs-test.nightskystudio.workers.dev/faulty")
let json = await response.json()
```
I expect `json` to be an object with parsed JSON object from the response. But instead, I get a string with the response body. This shows that something went wrong when parsing the response.
After some tinkering, I found out that `fetch` in `flutter_js` does not escape special characters automatically and, in fact, does not support them at all.
This poses a problem, because sometimes APIs DO return a sequence of `\r\n\t` and other special characters, which are not escaped, and thus, cannot be parsed by the JS engine.

### Expected behavior
This will work as expected:
```javascript
let response = await fetch("https://lutterjs-test.nightskystudio.workers.dev/normal")
let json = await response.json()
```
`json` will be an object with parsed JSON object from the response. Since return in `/normal` path does not contain any special characters.

## Remarks
I was at least partially certain that this library will provide me with functionality that is very close to V8, but here we are...

## Reproducing the bug
1. Clone this repository
2. `cd flutterjs_fetch_bug`
3. Run `flutter pub get`
4. Run `flutter run`
5. After application runs, select `Normal`/`Faulty` from the dropdown menu and press on the FAB button.

   Under `Text output:` you will see direct output that was received from the JavaScript runtime.

   Under `JSON output:` you will see the result of trying to re-parse `JSON.stringify` call by Dart language.
   
   The output of JsRuntime function `callFetch(type)` is an object with the source json parsing result and the type of that result. If it's an `object`, then fetch was successful and the response was parsed as JSON. If it's a `string`, then fetch was unsuccessful and the response was not parsed as JSON. (also, btw, `response.json()` should fail if the response is not a valid JSON, but it doesn't and fallbacks to `response.text()`, which is another bug)
