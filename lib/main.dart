/*
    Chess exercises manager : organise your chess exercises and play them
    against the device.
    Copyright (C) 2020  Laurent Bernabe

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'translations.dart';
import 'package:devicelocale/devicelocale.dart';

import 'game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final currentLocaleStr = await Devicelocale.currentLocale;
  await allTranslations.init(currentLocaleStr.substring(0, 2));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: allTranslations.text('app_title'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: allTranslations.text('main_title')),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: allTranslations.supportedLocales(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform =
      const MethodChannel('loloof64.chess_utils/engine_discovery');
  var _engines = [];

  @override
  void initState() {
    super.initState();
    _updateInstalledEngines().catchError((err) {
      print("Failed to get installed engines : ${err.toString()}");
    });
  }

  Future<void> _updateInstalledEngines() async {
    var engines;
    try {
      await platform.invokeMethod('copyAllEnginesToAppDir');
      var enginesJoined = await platform.invokeMethod('getEnginesList');

      if (enginesJoined == null || enginesJoined.length == 0)
        engines = [];
      else
        engines = enginesJoined.split(",").toList();
    } catch (e) {
      print("Failed to update installed engines ${e.toString()}");
      engines = [];
    }

    engines.sort();

    setState(() {
      _engines = engines;
    });
  }

  Future<void> _selectEngine(engineName) async {
    try {
      await platform.invokeMethod('chooseEngine', engineName);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GamePage()),
      );
    } catch (e) {
      print("Failed to select engine");
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget enginesChild;

    if (_engines.length > 0) {
      enginesChild = Center(
        child: Column(
          children: [
            Text(
              allTranslations.text('select_engine_message'),
              style: TextStyle(fontSize: 20),
            ),
            Expanded(child: ListView(
              shrinkWrap: true,
              children: _engines.map((current) {
                return FlatButton(
                  child: Text(
                    current,
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () => _selectEngine(current),
                );
              }).toList(),
            ),)
          ],
        ),
      );
    } else {
      enginesChild = Center(
        child: Text(
          allTranslations.text("no_oex_engine"),
          style: TextStyle(fontSize: 20),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: enginesChild,
    );
  }
}
