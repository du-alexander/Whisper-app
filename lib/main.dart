import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:aes256gcm/aes256gcm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'displayContents.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Encrypt Files'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _fileName = 'no file selected';
  String _labelText = 'Please use generated password';
  String _goButtonText = 'Encrypt & Send';
  String _passwordDisplayText = '';
  List<PlatformFile>? _paths;
  String? _path;
  //String? _directoryPath;
  //String? _extension;
  String _password = '';
  //bool _loadingPath = false;
  final bool _multiPick = false;
  String? _contents = 'no file selected';
  final _controller = TextEditingController();
  File? _myFile;
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();
  bool _mode = false; //false = encrypt, true = decrypt
  
  void _openFileExplorer() async {
    //setState(() => _loadingPath = true);
    try {
      //_directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: _multiPick,
      ))
          ?.files;
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } catch (ex) {
      print(ex);
    }
    if (!mounted) return;
    setState(() {
      //_loadingPath = false;
      //print(_paths!.first.extension);
      _fileName = _paths!.first.name; //!= null ? _paths!.map((e) => e.name).toString() : '...';
      _path = _paths!.first.path;
      _myFile = File('$_path');
      getContent();
    });
  }

  void _doStuff() async {
    _contents = await _myFile?.readAsString();
    //print(_contents);
    String _encrypted;
    String _decrypted;
    Directory outDir;
    outDir = await getApplicationDocumentsDirectory();
    String? outPath = outDir.path;
    File outFile;
    if(!_mode){
      _generateKey();
      _encrypted = await Aes256Gcm.encrypt(_contents!, _password);
      //print(_encrypted);
      outFile = File('$outPath/cypher.txt');
      outFile.writeAsString(_encrypted);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password Copied to clipboard!'),
          duration: Duration(milliseconds: 1000),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1000),() {
        Share.shareFiles([outFile.path]);
      });
    }
    else {
      _decrypted = await Aes256Gcm.decrypt(_contents!, _password);
      //print(_decrypted);
      outFile = File('$outPath/plain.txt');
      outFile.writeAsString(_decrypted);
      _contents = await outFile.readAsString();
      gotoDisplay();
    }
  }

  void _pickFile() {
    _openFileExplorer();
  }

  void _generateKey() {
    if (!_mode) {
      setState(() {
        //_password = 'EIqhyx7hXcgqXWN36SKfKpBaaF41kM1p'; //Test Password
        _password = getRandomString(32);
      });
      _copyPassword();
      //print(_password);
    }
  }

  void getContent() async{
    _contents = await _myFile?.readAsString();
  }

  void gotoDisplay() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayScreen(title: _contents!)
        ));
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _password));
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.insert_drive_file,
                size: 100,
                color: Colors.blue,
            ),
            TextButton(
              onPressed: gotoDisplay,
              child: Text(
                '$_fileName',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.black
                ),

              ),
            ),

            ElevatedButton(
                onPressed: _doStuff,
                child:
                Text(
                    _goButtonText
                )
            ),

            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _labelText,
              ),
              enabled: _mode,
              obscureText: true,
              controller: _controller,
              onSubmitted: (String value) async {
                setState(() {
                  if(_mode) {
                    _password = value;
                  }
                });

              }
            ),

            Text(
              _passwordDisplayText,
              style: const TextStyle(
                fontSize: 15
              ),
            ),

            ListTile(
              title: const Text('Encrypt'),
              leading: Radio<bool>(
                value: false,
                groupValue: _mode,
                onChanged: (mode) {
                  setState(() {
                    _mode = false;
                    _labelText = 'Please use generated password';
                    _password = '';
                    _passwordDisplayText = '';
                    _goButtonText = 'Encrypt & Send';
                    //_passwordButtonText = 'Generate Password';
                    _controller.clear();
                  });
                },
              ),

            ),
            ListTile(
              title: const Text('Decrypt'),
              leading: Radio<bool>(
                value: true,
                groupValue: _mode,
                onChanged: (mode) {
                  setState(() {
                    _mode = true;
                    _labelText = 'Enter password';
                    _password = '';
                    _passwordDisplayText = '';
                    _goButtonText = 'Decrypt & Display';
                    // _passwordButtonText = 'Please Enter Password';
                    _controller.clear();
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _pickFile,
        tooltip:'Upload File',
        child:
          const Icon(Icons.upload_file),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
