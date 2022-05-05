import "dart:io";
import "dart:convert";

int debugLevel = int.fromEnvironment("DEBUG", defaultValue: 4);
String audioPath =
    String.fromEnvironment("AUDIO_PATH", defaultValue: "app/audio/");
String fileScriptPath =
    String.fromEnvironment("FILE_SCRIPT", defaultValue: "main.script");
String fileVariablesPath = String.fromEnvironment("FILE_VARIABLES",
    defaultValue: "default_variables.js");
String fileAppPath = String.fromEnvironment("FILE_APP", defaultValue: "app.js");

final Map<String, String> base64Cache = <String, String>{};
final Map<String, String> defines = <String, String>{};
final List<bool> myArray = <bool>[];
final List<int> includeFilesLineCounter = <int>[];
final File fileScript = File(fileScriptPath);
final File fileScriptLog = File("${fileScriptPath}_log.txt");
final File fileVariables = File(fileVariablesPath);
final File fileApp = File(fileAppPath);
late String formattedLine;
late String preprocessedLine;
int lineCounter = 0;
int codeBracketCount = 0;
int menuBracketCount = 0;
bool isJavascript = false;
bool isDart = false;
Object? lastCalledFunction;

void error(errorText) => print("Error: $errorText");

void log([final Object? object, final int requiredDebugLevel = 1]) {
  if (debugLevel >= requiredDebugLevel) {
    fileScriptLog.writeAsStringSync(
        "$lineCounter: ${object ?? lastCalledFunction}\n",
        mode: FileMode.writeOnlyAppend);
  }
}

bool stringIsBase64(final String text) {
  lastCalledFunction = stringIsBase64;
  log(null, 1);

  log("text string: $text", 3);
  final textIsBase64 = (((text.length % 4) == 0) &&
      ((text.lastIndexOf("=") - text.indexOf("=")) == 1));
  log("isBase64: $textIsBase64", 3);

  return (textIsBase64);
}

String fileToBase64(final String filePath) {
  lastCalledFunction = fileToBase64;
  log(null, 1);

  log("file path: $filePath", 3);
  final file = File(filePath);

  log("file size: ${file.lengthSync()}", 3);
  final base64 = base64Encode(file.readAsBytesSync());

  return (base64);
}

bool isAlpha(String text) {
  lastCalledFunction = isAlpha;
  log(null, 1);

  return (!text.contains(RegExp("[^A-Za-z_]")));
}

bool toBool(Object? object) {
  var objectAsString = object.toString();

  if ((object == null) || (objectAsString.isEmpty)) {
    return (false);
  }

  var objectAsDouble = double.tryParse(objectAsString);

  if (objectAsDouble != null) {
    return (objectAsDouble > 0);
  }

  if (objectAsString == "true") {
    return (true);
  } else if (object == "false") {
    return (false);
  }

  return (objectAsString.isNotEmpty);
}

void preprocessLine() {
  if (formattedLine.startsWith("ifdef ")) {
    log("%ifdef", 1);

    formattedLine = formattedLine.split(" ").last.replaceFirst(";", "");

    log("value: \"$formattedLine\"", 2);

    myArray.add(toBool(defines[formattedLine]));

    preprocessedLine = "";
  } else if (formattedLine.startsWith("endif")) {
    log("%endif", 1);

    myArray.removeLast();

    preprocessedLine = "";

  } else if (formattedLine.startsWith("include")) {
    log("%include", 1);

    var includePath = formattedLine.split(" ").last.replaceFirst(";", "");

    log("value: \"$includePath\"", 2);

    var includeFile = File( includePath );

    FileSystemEntity.isDirectory( includePath )
      .then((inputFileIsDirectory) {
        if (inputFileIsDirectory) {
          error("\"$includePath\" is directory.");
        } else if (includeFile.existsSync()) {
          includeFilesLineCounter.add(0);
          var fileLines = includeFile.readAsLinesSync();
          var formattedText = "";
          var isCommentary = false;
          var isNotTextSymbol = false;

          for (var line in fileLines) {
            includeFilesLineCounter[ includeFilesLineCounter.length - 1 ]++;

            line = line.trim();
            isCommentary = false;

            if (line.isNotEmpty) {
              for (final rune in line.runes) {
                if (isCommentary) {
                  continue;
                }

                var symbol = String.fromCharCode(rune);
                formattedText += symbol;

                isNotTextSymbol = ((formattedText.length > 1) &&
                    (formattedText[formattedText.length - 2] == "\\"));

                if (!isNotTextSymbol) {
                  switch (symbol) {
                    case "#":
                      {
                        formattedText = formattedText
                            .replaceRange(formattedText.lastIndexOf("#"), null, "")
                            .trim();

                        isCommentary = true;

                        break;
                      }

                    case "{":
                    case "}":
                    case ";":
                      {
                        formattedLine = formattedText.trim();

                        if (debugLevel >= 5) {
                          print(
                              "${includeFilesLineCounter[ includeFilesLineCounter.length - 1 ]}: formattedText: \"$formattedLine \"");
                        }

                        preprocessLine();

                        formattedText = "";

                        if (preprocessedLine.isNotEmpty) {
                          parseLine();
                        }

                        break;
                      }
                  }
                }
              }

              if (formattedText.isNotEmpty) {
                formattedText += " ";
              }
            }
          }

          includeFilesLineCounter.removeLast();

          fileVariables
              .writeAsStringSync("", mode: FileMode.writeOnlyAppend);

        } else {
          error("\"$includePath\" not found.");
        }
      });

    preprocessedLine = "";

  } else if ((myArray.isNotEmpty) && (!myArray.last)) {
    log("%ifdef false", 3);

    log("value: \"$formattedLine\"", 3);

    preprocessedLine = "";
  } else if (codeBracketCount == 0) {
    lastCalledFunction = preprocessLine;
    log(null, 1);

    log("line: \"$formattedLine\"", 4);

    var isNotText = true;
    var formattedWords = formattedLine.split(" ");

    for (var wordIndex = 0; wordIndex < formattedWords.length; wordIndex++) {
      for (var matchCounter = 0;
          matchCounter < formattedWords[wordIndex].allMatches("\"").length;
          matchCounter++) {
        isNotText = !isNotText;
      }

      if (isNotText) {
        final word = formattedWords[wordIndex].replaceFirst(";", "").trim();

        if (defines.containsKey(word)) {
          formattedWords[wordIndex] = defines[word]!;
        }
      }
    }

    preprocessedLine = formattedWords.join(" ");

    log("preprocessed line: \"$preprocessedLine\"", 4);
  }
}

void parseLine() {
  lastCalledFunction = parseLine;
  log(null, 1);

  log("line: \"$preprocessedLine\"", 4);

  if (codeBracketCount > 0) {
    log("code brackets count before: $codeBracketCount", 2);
    codeBracketCount += "{".allMatches(preprocessedLine).length;
    codeBracketCount -= "}".allMatches(preprocessedLine).length;
    log("code brackets count after: $codeBracketCount", 2);

    if (codeBracketCount > 0) {
      fileApp.writeAsStringSync(preprocessedLine,
          mode: FileMode.writeOnlyAppend);
    }
  } else if ((menuBracketCount > 0) && (menuBracketCount < 4)) {
    if (preprocessedLine == "}") {
      menuBracketCount--;
    }

    log("menu brackets count before: $menuBracketCount", 2);

    switch (menuBracketCount) {
      case 1:
        {
          preprocessedLine = preprocessedLine
              .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
              .trim();
          preprocessedLine = "_MenuName( $preprocessedLine );";

          menuBracketCount = 3;

          break;
        }

      case 2:
        {
          menuBracketCount = 0;

          preprocessedLine = "})();";

          break;
        }

      case 3:
        {
          preprocessedLine = preprocessedLine
              .replaceRange(preprocessedLine.lastIndexOf("{"), null, "")
              .trim();
          preprocessedLine = "_MenuLabel( $preprocessedLine, async () => { ";

          break;
        }
    }

    if (preprocessedLine != "}") {
      menuBracketCount += "{".allMatches(preprocessedLine).length;
      menuBracketCount -= "}".allMatches(preprocessedLine).length;
    }

    log("menu brackets count after: $menuBracketCount", 2);

    log("menu line: \"$preprocessedLine\"", 2);
    fileApp.writeAsStringSync(preprocessedLine, mode: FileMode.writeOnlyAppend);
  } else {
    /// statement "banana"
    ///
    /// banana banana banana
    if (preprocessedLine.startsWith("define ")) {
      log("@define", 1);

      final line = preprocessedLine.replaceFirst("define ", "").split("=");
      final key = line.first.trim();
      final value =
          line.last.replaceRange(line.last.lastIndexOf(";"), null, "").trim();

      log("key: \"$key\"", 3);
      log("value: \"$value\"", 3);

      defines[key] = value;
      log("defines: $defines", 3);
    } else if (preprocessedLine.startsWith("default ")) {
      log("@default", 1);

      final line = preprocessedLine.replaceFirst("default ", "").split("=");
      final key = line.first.trim();
      final value =
          line.last.replaceRange(line.last.lastIndexOf(";"), null, "").trim();
      log("key: \"$key\"", 2);
      log("value: \"$value\"", 2);

      fileVariables.writeAsStringSync("var $key = $value;\n",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("\$")) {
      log("@\$", 1);

      preprocessedLine = preprocessedLine.replaceFirst("\$", "").trim();

      fileApp.writeAsStringSync(preprocessedLine,
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("label ")) {
      log("@label", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf("{"), null, "")
          .replaceFirst("label ", "")
          .trim();
      log("value: \"$preprocessedLine\"", 2);

      fileApp.writeAsStringSync(
          "async function $preprocessedLine( _resolve ) {",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("}")) {
      log("@}", 1);

      if (menuBracketCount >= 4) {
        log("menu brackets count before: $menuBracketCount", 2);
        menuBracketCount--;
        log("menu brackets count after: $menuBracketCount", 2);

        if (menuBracketCount == 3) {
          preprocessedLine = "});";
          log("menu line: \"$preprocessedLine\"", 2);
        }
      }

      fileApp.writeAsStringSync(preprocessedLine.trim(),
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("if ")) {
      log("@if", 1);

      preprocessedLine = preprocessedLine.trim();
      log("value: \"$preprocessedLine\"", 2);

      fileApp.writeAsStringSync(preprocessedLine,
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("while ")) {
      log("@while", 1);

      preprocessedLine = preprocessedLine.trim();
      log("value: \"$preprocessedLine\"", 2);

      fileApp.writeAsStringSync(preprocessedLine,
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("jump ")) {
      log("@jump", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .replaceFirst("jump ", "")
          .trim();
      log("value: \"$preprocessedLine\"", 2);

      fileApp.writeAsStringSync("$preprocessedLine( _resolve );",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("return;")) {
      log("@return", 1);

      log("value: \"$preprocessedLine\"", 2);

      fileApp.writeAsStringSync("_resolve();", mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("\"")) {
      log("@\"\"", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .trim();
      log("value: \"$preprocessedLine\"", 3);

      fileApp.writeAsStringSync("_Say( $preprocessedLine );",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("...")) {
      log("@...", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .replaceFirst("...", "")
          .trim();
      log("value: \"$preprocessedLine\"", 3);

      fileApp.writeAsStringSync("_SayEx( $preprocessedLine );",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("scene ")) {
      log("@scene", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .replaceFirst("scene ", "")
          .trim();
      log("value: \"$preprocessedLine\"", 3);

      final words = preprocessedLine.split(" ");
      final filename = words
          .takeWhile((word) => (word != "with"))
          .toList(growable: false)
          .join("_");
      var appearance = words.skipWhile((word) => (word != "with")).toList()
        ..remove("with");

      fileApp.writeAsStringSync(
          "_Scene( $filename${(appearance.isNotEmpty) ? ", appearance_t.${appearance.join("_")}" : ", appearance_t.fade"} );",
          mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.startsWith("show ")) {
      log("@show", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .replaceFirst("show ", "")
          .trim();
      log("value: \"$preprocessedLine\"", 3);

      final words = preprocessedLine.split(" ");
      final filename = words
          .takeWhile((word) => (word != "with"))
          .toList(growable: false)
          .join("_");
      var appearance = words.skipWhile((word) => (word != "with")).toList()
        ..remove("with");

      fileApp.writeAsStringSync(
          "_Show( $filename${(appearance.isNotEmpty) ? ", appearance_t.${appearance.join("_")}" : ", appearance_t.fade"} );",
          mode: FileMode.writeOnlyAppend);
    } else if ((preprocessedLine.startsWith("play ")) ||
        (preprocessedLine.startsWith("stop ")) ||
        (preprocessedLine.startsWith("pause ")) ||
        (preprocessedLine.startsWith("resume "))) {
      log("@play", 1);

      preprocessedLine = preprocessedLine
          .replaceRange(preprocessedLine.lastIndexOf(";"), null, "")
          .trim();

      var words = preprocessedLine.split(" ");
      var isBase64 = words.contains("base64");
      var file = "";
      var function = "";
      var type = "";

      log("value: $words", 3);

      if (words.contains("sound")) {
        type = "SOUND";
        log("type changed: $type", 3);
      } else if (words.contains("music")) {
        type = "MUSIC";
        log("type changed: $type", 3);
      }

      if (words.contains("play")) {
        file = words.last;

        if (isBase64) {
          function = "_PlayBase64";
          log("function changed: $function", 3);

          if (file.contains("\"")) {
            if (!stringIsBase64(file)) {
              if (!base64Cache.containsKey(file)) {
                base64Cache[file] = fileToBase64(file);
              }

              file = "\"${base64Cache[file]}\"";
            }
          } else {
            if (!base64Cache.containsKey(file)) {
              base64Cache[file] = fileToBase64("$audioPath$file.mp3");
            }

            file = "\"${base64Cache[file]}\"";
          }

          file = ", $file, \"mp3\"";
        } else {
          function = "_Play";
          log("function changed: $function", 3);

          if (words.last.contains("\"")) {
            file = ", \"$audioPath${file.replaceAll("\"", "")}\"";
          } else {
            file = ", \"$audioPath$file.mp3\"";
          }
        }
      } else if (words.contains("stop")) {
        function = "_Stop";
        log("function changed: $function", 3);
      } else if (words.contains("pause")) {
        function = "_Pause";
        log("function changed: $function", 3);
      } else if (words.contains("resume")) {
        function = "_Resume";
        log("function changed: $function", 3);
      }

      fileApp.writeAsStringSync("$function( MediaType.$type$file );",
          mode: FileMode.writeOnlyAppend);

      // } else if ( preprocessedLine.startsWith( "code" ) ) {
      //     log( "@code", 1 );

      //     codeBracketCount = 1;

    } else if (preprocessedLine.startsWith("menu")) {
      log("@menu", 1);

      menuBracketCount = 1;

      fileApp.writeAsStringSync("( () => {", mode: FileMode.writeOnlyAppend);
    } else if (preprocessedLine.length > 1) {
      log("@other", 1);

      preprocessedLine =
          preprocessedLine.replaceAll("[", "{").replaceAll("]", "}");
      log("value: \"$preprocessedLine\"", 3);

      fileApp.writeAsStringSync(preprocessedLine,
          mode: FileMode.writeOnlyAppend);
    }
  }
}
