import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brightness Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  String systemBrightness = '0';
  List<String> brightnessLevels = [];

  Future<void> setSystemBrightness(String brightness) async {
    try {
      double parsedBrightness = double.parse(brightness);

      if (parsedBrightness < 0.0 || parsedBrightness > 1.0) {
        throw 'Brightness value must be between 0.0 and 1.0';
      }

      await ScreenBrightness.instance
          .setSystemScreenBrightness(parsedBrightness);

      setState(() {
        systemBrightness = parsedBrightness.toStringAsFixed(3);
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'systemBrightness',
        parsedBrightness.toStringAsFixed(3),
      );
    } catch (e) {
      throw 'Failed to set system brightness';
    }
  }

  addBrightnessLevel(String brightness) async {
    try {
      double parsedBrightness = double.parse(brightness);

      setState(() {
        brightnessLevels.add(parsedBrightness.toStringAsFixed(3));
        brightnessLevels.sort();
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('brightnessLevels', brightnessLevels);
    } catch (e) {
      throw 'Failed to add brightness level';
    }
  }

  removeBrightnessLevel(String brightness) async {
    try {
      setState(() {
        brightnessLevels.remove(brightness);
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('brightnessLevels', brightnessLevels);
    } catch (e) {
      throw 'Failed to remove brightness level';
    }
  }

  getBrightnessLevelList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      brightnessLevels = prefs.getStringList('brightnessLevels') ?? [];
      systemBrightness = prefs.getString('systemBrightness') ?? '0';
    });
  }

  @override
  void initState() {
    super.initState();
    getBrightnessLevelList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Brightness Control"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: brightnessLevels.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'No Brightness Levels List',
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    spacing: 8.0,
                    children: [
                      ...brightnessLevels.map((level) {
                        return Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 400.0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  setSystemBrightness(level);
                                },
                                onLongPress: () {
                                  removeBrightnessLevel(level);
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8.0)),
                                  ),
                                  backgroundColor: systemBrightness == level
                                      ? Colors.yellow.shade100
                                      : Colors.white,
                                ),
                                child: Text(level.toString()),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Add System Brightness'),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Brightness',
                  hintText: 'Enter brightness value (0.0 - 1.0)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field cannot be empty';
                  }
                  if (double.tryParse(value)! > 1.0 ||
                      double.tryParse(value)! < 0.0) {
                    return 'Please enter a value between 0.0 and 1.0';
                  }
                  return null;
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    addBrightnessLevel(_textController.text);
                    _textController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        tooltip: 'Get System Brightness',
        child: const Icon(Icons.add),
      ),
    );
  }
}
