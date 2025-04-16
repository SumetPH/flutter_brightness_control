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

  double systemBrightness = 0;
  List<String> brightnessLevels = [];

  Future<void> getSystemBrightness() async {
    try {
      double brightness = await ScreenBrightness.instance.system;
      setState(() {
        systemBrightness = double.parse(brightness.toStringAsFixed(3));
      });
    } catch (e) {
      throw 'Failed to get system brightness';
    }
  }

  Future<void> setSystemBrightness(double brightness) async {
    try {
      if (brightness < 0.0 || brightness > 1.0) {
        throw 'Brightness value must be between 0.0 and 1.0';
      }

      await ScreenBrightness.instance.setSystemScreenBrightness(brightness);
      setState(() {
        systemBrightness = brightness;
      });
    } catch (e) {
      throw 'Failed to set system brightness';
    }
  }

  addBrightnessLevel(double brightness) async {
    try {
      setState(() {
        brightnessLevels.add(brightness.toString());
        brightnessLevels.sort();
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('brightnessLevels', brightnessLevels);
    } catch (e) {
      throw 'Failed to add brightness level';
    }
  }

  removeBrightnessLevel(double brightness) async {
    try {
      setState(() {
        brightnessLevels.remove(brightness.toString());
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
    });
  }

  @override
  void initState() {
    super.initState();
    getSystemBrightness();
    getBrightnessLevelList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Brightness Control"),
      ),
      body: Padding(
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...brightnessLevels.map((level) {
                        return OutlinedButton(
                          onPressed: () {
                            setSystemBrightness(double.parse(level));
                          },
                          onLongPress: () {
                            removeBrightnessLevel(double.parse(level));
                          },
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                            ),
                            backgroundColor:
                                systemBrightness == double.parse(level)
                                    ? Colors.yellow.shade100
                                    : Colors.white,
                          ),
                          child: Text(level.toString()),
                        );
                      }),
                    ],
                  ),
                ],
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
                    addBrightnessLevel(double.parse(_textController.text));
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
