import "dart:io";
import "dart:convert";

const debugLevel    = int.fromEnvironment(    "DEBUG",          defaultValue : 0 );
const path          = String.fromEnvironment( "ROOT_PATH",      defaultValue : "assets/" );
const appPath       = String.fromEnvironment( "APP_PATH",       defaultValue : "app/" );
const audioPath     = String.fromEnvironment( "AUDIO_PATH",     defaultValue : "audio/" );
const fileScript    = String.fromEnvironment( "FILE_SCRIPT",    defaultValue : ".script" );
const fileVariables = String.fromEnvironment( "FILE_VARIABLES", defaultValue : "default_variables.js" );
const fileApp       = String.fromEnvironment( "FILE_APP",       defaultValue : "app.js" );

int lineCounter = 0;

void error( errorText ) => print( "Error: $errorText" );

/// banana
class FormattedFile {
    static final _base64Cache        = < String, String >{};
    final        _defines            = < String, String >{};
    final        _fileScript;
    final        _fileScriptLog;
    final        _fileVariables      = File( path + fileVariables );
    final        _fileApp            = File( path + fileApp );
    var          _jsBracketCount     = 0;
    var          _line;
    var          _menuBracketCount   = 0;
    File   get   file                => _fileScript;
    String get   line                => _line;
    bool   get   isJs                => ( _jsBracketCount > 0 );
    set          line( String text ) => _line = text;

    Object? _lastCalledFunction;

    FormattedFile( String filePath )
        : _fileScript = File( filePath ),
        _fileScriptLog = File( "${ filePath }_log.txt" )
    {
        if ( debugLevel >= 1 ) {
            _fileScriptLog.writeAsStringSync( "" );
        }

        _fileVariables.writeAsStringSync( "" );
        _fileApp.writeAsStringSync( "" );
    }

    destructor() {
        _fileVariables.writeAsStringSync( "", mode : FileMode.writeOnlyAppend );
    }

    @override
    String toString() => "FormattedFile\nScript file: \"$_fileScript\"";

    /// banana
    void _log( [ final Object? object, final int requiredDebugLevel = 1 ] ) {
        if ( debugLevel >= requiredDebugLevel ) {
            _fileScriptLog.writeAsStringSync(
                "$lineCounter: ${ object ?? ( _lastCalledFunction ?? FormattedFile ) }\n",
                mode : FileMode.writeOnlyAppend
            );
        }
    }

    bool _isBase64( final String text ) {
        _lastCalledFunction = _isBase64;
        _log( null, 1 );

        _log( "text string: $text", 3 );
        final textIsBase64 = (
            ( ( text.length % 4 ) == 0 ) &&
            ( ( text.lastIndexOf( "=" ) - text.indexOf( "=" ) ) == 1 )
        );
        _log( "isBase64: $textIsBase64", 3 );

        return ( textIsBase64 );
    }

    String _toBase64( final String filePath ) {
        _lastCalledFunction = _toBase64;
        _log( null, 1 );

        _log( "file path: $filePath", 3 );
        final file = File( filePath );

        _log( "file size: ${ file.lengthSync() }", 3 );
        final base64 = base64Encode( file.readAsBytesSync() );

        return ( base64 );
    }

    bool _isAlpha( String text ) {
        _lastCalledFunction = _isAlpha;
        _log( null, 1 );

        return (
            !text.contains(
                RegExp( "[^A-Za-z_]" )
            )
        );
    }

    void preprocessLine() {
        if ( _jsBracketCount == 0 ) {
            _lastCalledFunction = preprocessLine;
            _log( null, 1 );

            _log( "line: $_line", 4 );
            _defines.forEach( ( key, value ) {
                key.allMatches( _line ).forEach( ( Match match ) {
                    if ( match.start > 0 ) {
                        if ( match.end < ( _line.length - 1 ) ) {
                            if ( ( !_isAlpha( _line[ match.start - 1 ] ) ) && ( !_isAlpha( _line[ match.start + 1 ] ) ) ) {
                                _line = _line.replaceFirst( key, value, match.start );
                            }

                        } else {
                            if ( !_isAlpha( _line[ match.start - 1 ] ) ) {
                                _line = _line.replaceFirst( key, value, match.start );
                            }
                        }

                    } else {
                        if (
                            ( match.end > ( _line.length - 1 ) ) ||
                            ( !_isAlpha( _line[ match.end ] ) )
                        ) {
                            _line = _line.replaceFirst( key, value, match.start );
                        }
                    }
                } );
            } );
            _log( "preprocessed line: \"$_line\"", 4 );
        }
    }

    void parseLine() {
        _lastCalledFunction = parseLine;
        _log( null, 1 );

        _log( "line: \"$_line\"", 4 );

        if ( _jsBracketCount > 0 ) {
            _log( "javascript brackets count before: $_jsBracketCount", 2 );
            _jsBracketCount += "{".allMatches( _line ).length;
            _jsBracketCount -= "}".allMatches( _line ).length;
            _log( "javascript brackets count after: $_jsBracketCount", 2 );

            if ( _jsBracketCount > 0 ) {
                _fileApp.writeAsStringSync( "$_line", mode : FileMode.writeOnlyAppend );
            }

        } else if ( ( _menuBracketCount > 0 ) && ( _menuBracketCount < 4 ) ) {
            if ( _line == "}" ) {
                _menuBracketCount--;
            }

            _log( "menu brackets count before: $_menuBracketCount", 2 );

            switch ( _menuBracketCount ) {
                case 1:
                {
                    _line = _line.replaceRange( _line.lastIndexOf( ";" ), null, "" ).trim();
                    _line = "_MenuName( $_line );";

                    _menuBracketCount = 3;

                    break;
                }

                case 2:
                {
                    _menuBracketCount = 0;

                    _line = "})();";

                    break;
                }

                case 3:
                {
                    _line = _line.replaceRange( _line.lastIndexOf( "{" ), null, "" ).trim();
                    _line = "_MenuLabel( $_line, async () => { ";

                    break;
                }
            }

            if ( _line != "}" ) {
                _menuBracketCount += "{".allMatches( _line ).length;
                _menuBracketCount -= "}".allMatches( _line ).length;
            }

            _log( "menu brackets count after: $_menuBracketCount", 2 );

            _log( "menu line: \"$_line\"", 2 );
            _fileApp.writeAsStringSync( "$_line", mode : FileMode.writeOnlyAppend );

        } else {
            /// statement "banana"
            ///
            /// banana banana banana
            if ( _line.startsWith( "define " ) ) {
                _log( "\@define", 1 );

                final line = _line.replaceFirst( "define ", "" ).split( "=" );
                final key = line.first.trim();
                final value = line
                    .last.replaceRange( line.last.lastIndexOf( ";" ), null, "" )
                    .trim()
                ;

                _log( "key: \"$key\"", 3 );
                _log( "value: \"$value\"", 3 );

                _defines[ key ] = value;
                _log( "defines: $_defines", 3 );

            } else if ( _line.startsWith( "default " ) ) {
                _log( "\@default", 1 );

                final line = _line.replaceFirst( "default ", "" ).split( "=" );
                final key = line.first.trim();
                final value = line.last.replaceRange( line.last.lastIndexOf( ";" ), null, "" ).trim();
                _log( "key: \"$key\"", 2 );
                _log( "value: \"$value\"", 2 );

                _fileVariables.writeAsStringSync( "var $key = $value;\n", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "\$" ) ) {
                _log( "\@\$", 1 );

                _line = _line.replaceFirst( "\$", "" ).trim();

                _fileApp.writeAsStringSync( "$_line", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "label " ) ) {
                _log( "\@label", 1 );

                _line = _line.replaceRange( _line.lastIndexOf( "{" ), null, "" )
                    .replaceFirst( "label ", "" )
                    .trim();
                _log( "value: \"$_line\"", 2 );

                _fileApp.writeAsStringSync( "async function $_line( _resolve ) {", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "}" ) ) {
                _log( "\@}", 1 );

                if ( _menuBracketCount >= 4 ) {
                    _log( "menu brackets count before: $_menuBracketCount", 2 );
                    _menuBracketCount--;
                    _log( "menu brackets count after: $_menuBracketCount", 2 );

                    if ( _menuBracketCount == 3 ) {
                        _line = "});";
                        _log( "menu line: \"$_line\"", 2 );
                    }
                }

                _fileApp.writeAsStringSync( "${ _line.trim() }", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "if " ) ) {
                _log( "\@if", 1 );

                _line = _line.trim();
                _log( "value: \"$_line\"", 2 );

                _fileApp.writeAsStringSync( "$_line", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "while " ) ) {
                _log( "\@while", 1 );

                _line = _line.trim();
                _log( "value: \"$_line\"", 2 );

                _fileApp.writeAsStringSync( "$_line", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "jump " ) ) {
                _log( "\@jump", 1 );

                _line = _line.replaceRange( _line.lastIndexOf( ";" ), null, "" )
                    .replaceFirst( "jump ", "" )
                    .trim();
                _log( "value: \"$_line\"", 2 );

                _fileApp.writeAsStringSync( "$_line( _resolve );", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "return;" ) ) {
                _log( "\@return", 1 );

                _log( "value: \"$_line\"", 2 );

                _fileApp.writeAsStringSync( "_resolve();", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "\"" ) ) {
                _log( "\@\"\"", 1 );

                _line = _line.replaceRange( _line.lastIndexOf( ";" ), null, "" ).trim();
                _log( "value: \"$_line\"", 3 );

                _fileApp.writeAsStringSync( "_Say( $_line ); await _WaitInput();", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "..." ) ) {
                _log( "\@...", 1 );

                _line = _line.replaceRange( _line.lastIndexOf( ";" ), null, "" )
                    .replaceFirst( "...", "" )
                    .trim();
                _log( "value: \"$_line\"", 3 );

                _fileApp.writeAsStringSync( "_SayEx( $_line ); await _WaitInput();", mode : FileMode.writeOnlyAppend );

            } else if (
                ( _line.startsWith( "play " ) ) ||
                ( _line.startsWith( "stop " ) ) ||
                ( _line.startsWith( "pause " ) ) ||
                ( _line.startsWith( "resume " ) )
            ) {
                _log( "\@play", 1 );

                _line = _line.replaceRange( _line.lastIndexOf( ";" ), null, "" )
                    .trim();

                var line = _line.split( " " );
                var isBase64 = line.contains( "base64" );
                var file = "";
                var function = "";
                var type = "";

                _log( "value: $line", 3 );

                if ( line.contains( "sound" ) ) {
                    type = "SOUND";
                    _log( "type changed: $type", 3 );

                } else if ( line.contains( "music" ) ) {
                    type = "MUSIC";
                    _log( "type changed: $type", 3 );
                }

                if ( line.contains( "play" ) ) {
                    file = line.last;

                    if ( isBase64 ) {
                        function = "_PlayBase64";
                        _log( "function changed: $function", 3 );

                        if ( file.contains( "\"" ) ) {
                            if ( !_isBase64( file ) ) {
                                if ( !_base64Cache.containsKey( file ) ) {
                                    _base64Cache[ file ] = _toBase64( file );
                                }

                                file = "\"${ _base64Cache[ file ] }\"";

                            }

                        } else {
                            if ( !_base64Cache.containsKey( file ) ) {
                                _base64Cache[ file ] = _toBase64( "$path$appPath$audioPath$file.mp3" );
                            }

                            file = "\"${ _base64Cache[ file ] }\"";
                        }

                        file = ", $file, \"mp3\"";

                    } else {
                        function = "_Play";
                        _log( "function changed: $function", 3 );

                        if ( line.last.contains( "\"" ) ) {
                            file = ", \"$path$appPath$audioPath${ file.replaceAll( "\"", "" ) }\"";

                        } else {
                            file = ", \"$path$appPath$audioPath$file.mp3\"";
                        }
                    }

                } else if ( line.contains( "stop" ) ) {
                    function = "_Stop";
                    _log( "function changed: $function", 3 );

                } else if ( line.contains( "pause" ) ) {
                    function = "_Pause";
                    _log( "function changed: $function", 3 );

                } else if ( line.contains( "resume" ) ) {
                    function = "_Resume";
                    _log( "function changed: $function", 3 );
                }

                _fileApp.writeAsStringSync( "$function( MediaType.$type$file );", mode : FileMode.writeOnlyAppend );

            } else if ( _line.startsWith( "javascript" ) ) {
                _log( "\@javascript", 1 );

                _jsBracketCount = 1;

            } else if ( _line.startsWith( "menu" ) ) {
                _log( "\@menu", 1 );

                _menuBracketCount = 1;

                _fileApp.writeAsStringSync( "( () => {", mode : FileMode.writeOnlyAppend );

            } else if ( _line.length > 1 ) {
                _log( "\@FUNC() (\"\")", 1 );

                _line = _line
                    .replaceAll( "[", "{" )
                    .replaceAll( "]", "}" )
                ;

                _log( "value: \"$_line\"", 3 );

                _fileApp.writeAsStringSync( "${ _line }await _WaitInput();", mode : FileMode.writeOnlyAppend );
            }
        }
    }
}

void main( List< String > args ) {
    final logScript = ( args.isNotEmpty ) ? File( args[ 0 ] ) : null;
    final logScriptExists = ( logScript != null ) ? logScript.existsSync() : false;

    final inputFile = FormattedFile( "${ path + fileScript }" );

    late final bool inputFileIsDirectory;

    FileSystemEntity.isDirectory( inputFile.file.path ).then(
        ( isDirectory ) => inputFileIsDirectory = isDirectory
    );

    if ( inputFileIsDirectory ) {
        error( "\"${ path + fileScript }\" is directory." );

    } else if ( inputFile.file.existsSync() ) {
        var fileLines = inputFile.file.readAsLinesSync();
        var formattedLines = < String >[];
        var formattedText = "";
        var isCommentary = false;
        var isText = false;

        for ( var line in fileLines ) {
            lineCounter++;

            line = line.trim();
            isCommentary = false;

            if ( line.isNotEmpty ) {
                line.runes.forEach( ( int rune ) {
                    if ( isCommentary ) {
                        return;
                    }

                    var symbol = String.fromCharCode( rune );
                    formattedText += symbol;

                    /// banana
                    isText = (
                        ( formattedText.length > 1 ) &&
                        ( formattedText[ formattedText.length - 1 ] == "\\" )
                    );

                    if ( !isText ) {
                        switch ( symbol ) {
                            case "#":
                            {
                                formattedText = formattedText
                                    .replaceRange( formattedText.lastIndexOf( "#" ), null, "" )
                                    .trim();

                                isCommentary = true;

                                break;
                            }

                            case "{":
                            case "}":
                            case ";":
                            {
                                inputFile.line = formattedText.trim();

                                if ( debugLevel >= 5 ) {
                                    print( "$lineCounter: formattedText: \"${ inputFile.line }\"" );
                                }

                                formattedText = "";

                                inputFile.preprocessLine();

                                if ( logScriptExists ) {
                                    formattedLines.add( inputFile.line );
                                }

                                inputFile.parseLine();

                                break;
                            }
                        }
                    }
                } );

                if ( formattedText.isNotEmpty ) {
                    formattedText += " ";
                }
            }
        }

        inputFile.destructor();

        if ( logScriptExists ) {
            final trustLogScript = logScript;

            trustLogScript.writeAsStringSync( "" );

            formattedLines.forEach( ( String line ) => trustLogScript.writeAsStringSync( "$line\n", mode : FileMode.writeOnlyAppend ) );
        }

    } else {
        error( "\"${ path + fileScript }\" not found." );
    }
}