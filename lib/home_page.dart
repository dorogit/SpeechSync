import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  bool isRecorderReady = false;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    recorder.stopRecorder();
    player.stopPlayer();
    super.dispose();
  }

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Mic perms not granted';
    }

    await recorder.openRecorder();
    isRecorderReady = true;

    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<String> getTemporaryFilePath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/audio.wav';
  }

  Future<void> record() async {
    final path = await getTemporaryFilePath();
    await recorder.startRecorder(toFile: path, codec: Codec.pcm16WAV);
  }

  Future<void> stop() async {
    if (!isRecorderReady) return;
    final path = await recorder.stopRecorder();
    final audioFile = File(path!);

    print("recorded audio: $audioFile and this is the path $path");
  }

  Future<void> play() async {
    final path = await getTemporaryFilePath();

    await player.openPlayer();
    await player.startPlayer(fromURI: path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 17, 17),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 17, 17),
        title: Image.asset(
          'assets/images/logo.png',
          width: MediaQuery.of(context).size.width * 0.5,
          height: AppBar().preferredSize.height,
          fit: BoxFit.contain,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: (context, snapshot) {
                final duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;
                return Text('${duration.inSeconds} s');
              },
            ),
            const Text(
              "Please hold the button and record your English voice",
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 193)),
            ),
            const Text(
              "Note that it can only translate English at the moment!",
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 193)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
              child: SizedBox(
                height: 90,
                width: 90,
                child: FloatingActionButton(
                  onPressed: () async {
                    if (recorder.isRecording) {
                      await stop();
                    } else {
                      await record();
                    }
                    setState(() {});
                  },
                  backgroundColor: const Color.fromARGB(255, 255, 255, 193),
                  shape: const CircleBorder(),
                  child: recorder.isRecording
                      ? const Icon(Icons.pause)
                      : const Icon(Icons.mic),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await play();
              },
              child: const Text('Play Recorded Audio'),
            ),
          ],
        ),
      ),
    );
  }
}
