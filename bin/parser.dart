import "dart:io";

import "package:args/args.dart";

import "package:parser/parser.dart" as script_parser;

void main(List<String> arguments) {
  final argumentParser = ArgParser();

  argumentParser
    ..addOption(
      "debug",
      abbr: "d",
      defaultsTo: script_parser.debugLevel.toString(),
      callback: (String? level) => script_parser.debugLevel =
          (int.tryParse(level ?? "null") ?? script_parser.debugLevel),
      allowed: ["1", "2", "3", "4"],
    )
    ..addOption(
      "assets",
      abbr: "a",
      defaultsTo: script_parser.audioPath,
      callback: (String? path) =>
          script_parser.audioPath = (path ?? script_parser.audioPath),
    )
    ..addOption(
      "in",
      abbr: "i",
      defaultsTo: script_parser.fileScriptPath,
      callback: (String? path) =>
          script_parser.fileScriptPath = (path ?? script_parser.audioPath),
    )
    ..addOption(
      "out",
      abbr: "o",
      defaultsTo: script_parser.fileAppPath,
      callback: (String? path) =>
          script_parser.fileAppPath = (path ?? script_parser.audioPath),
    )
    ..addOption(
      "log",
      abbr: "l",
    )
    ..addFlag("native", negatable: true, callback: (isNative) {
      script_parser.defines["isJavascript"] = (!isNative).toString();
      script_parser.defines["isDart"] = isNative.toString();
    })
    ..addFlag("help", negatable: false, callback: (printHelp) {
      if (printHelp) {
        print(argumentParser.usage);
      }
    });

  final results = argumentParser.parse(arguments);

  final logScript = File(results["log"] ?? "log.txt");
  final logScriptExists = logScript.existsSync();

  if (script_parser.debugLevel >= 1) {
    script_parser.fileScriptLog.writeAsStringSync("");
  }

  script_parser.fileVariables.writeAsStringSync("");
  script_parser.fileApp.writeAsStringSync("");

  FileSystemEntity.isDirectory(script_parser.fileScript.path)
      .then((inputFileIsDirectory) {
    if (inputFileIsDirectory) {
      script_parser.error("\"${script_parser.fileScriptPath}\" is directory.");
    } else if (script_parser.fileScript.existsSync()) {
      var fileLines = script_parser.fileScript.readAsLinesSync();
      var formattedLines = <String>[];
      var formattedText = "";
      var isCommentary = false;
      var isNotTextSymbol = false;

      for (var line in fileLines) {
        script_parser.lineCounter++;

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
                    script_parser.formattedLine = formattedText.trim();

                    if (script_parser.debugLevel >= 5) {
                      print(
                          "${script_parser.lineCounter}: formattedText: \"${script_parser.formattedLine} \"");
                    }

                    script_parser.preprocessLine();

                    formattedText = "";

                    if (logScriptExists) {
                      formattedLines.add(script_parser.preprocessedLine);
                    }

                    if (script_parser.preprocessedLine.isNotEmpty) {
                      script_parser.parseLine();
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

      script_parser.fileVariables
          .writeAsStringSync("", mode: FileMode.writeOnlyAppend);

      if (logScriptExists) {
        final trustLogScript = logScript;

        trustLogScript.writeAsStringSync("");

        for (final line in formattedLines) {
          trustLogScript.writeAsStringSync("$line\n",
              mode: FileMode.writeOnlyAppend);
        }
      }
    } else {
      script_parser.error("\"${script_parser.fileScriptPath}\" not found.");
    }
  });
}
