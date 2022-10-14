import "dart:io";

// Copyright 2013, the Dart project authors.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:

//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google LLC nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
import "package:args/args.dart";

import "package:parser/parser.dart" as script_parser;

void main(List<String> arguments) {
  final argumentParser = ArgParser();

  argumentParser
    ..addOption(
      "debug",
      abbr: "d",
      callback: (String? level) => script_parser.debugLevel =
          (int.tryParse(level ?? "null") ?? script_parser.debugLevel),
      allowed: ["0", "1", "2", "3", "4"],
    )
    ..addOption(
      "assets",
      callback: (String? path) {
        if (path != null) {
          script_parser.audioPath = path;
        }
      },
    )
    ..addOption(
      "in",
      abbr: "i",
      callback: (String? path) {
        if (path != null) {
          script_parser.fileScriptPath = path;
        }
      },
    )
    ..addOption(
      "out",
      abbr: "o",
      callback: (String? path) {
        if (path != null) {
          script_parser.fileAppPath = path;
        }
      },
    )
    ..addOption(
      "log",
      callback: (String? path) {
        if (path != null) {
          script_parser.fileScriptLog = File(path);
        }
      },
    )
    ..addFlag("native", negatable: true, callback: (bool? isNative) {
      if (isNative != null) {
        script_parser.defines["isJavascript"] = (!isNative).toString();
        script_parser.defines["isDart"] = isNative.toString();
      }
    })
    ..addFlag("help", negatable: false, callback: (bool? printHelp) {
      if ((printHelp != null) && (printHelp)) {
        print(argumentParser.usage);
      }
    });

  argumentParser.parse(arguments);

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

                    formattedLines.add(script_parser.preprocessedLine);

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
    } else {
      script_parser.error("\"${script_parser.fileScriptPath}\" not found.");
    }
  });
}
