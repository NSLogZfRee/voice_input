import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:voice_input/event.dart';
import 'package:voice_input/message_voice_send_widget.dart';
import 'package:voice_input/voice_touch_point_change.dart';

void main() {
  runApp(const OKToast(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool voiceLongPress = false; //是否长按了 按住说话
  bool canPass = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerMove: (PointerMoveEvent move) {
              if (canPass == true &&
                voiceLongPress == true && voiceSendEnough == false) {
                  eventBus.fire(VoiceTouchPointChange(
                  move.localPosition, VoiceMessageSendWidgetStatus.recording));
                }
            },
            onPointerUp: (PointerUpEvent event) {
              voiceLongPress = false;

              eventBus.fire(
              VoiceTouchPointChange(null, VoiceMessageSendWidgetStatus.end));
            },
            child: Column(
              children: [
                Expanded(child: Container()),
                GestureDetector(
                  onLongPressDown: (LongPressDownDetails details) async {
                    voiceSendEnough = false;
                    canPass = true;
                    eventBus.fire(VoiceTouchPointChange(null, VoiceMessageSendWidgetStatus.recording));
                    voiceLongPress = true;
                  },
                  child: Container(
                    color: Colors.orange,
                    height: 50,
                    child: Center(
                      child: Text(
                        '按住说话',
                      ),
                    ),
                  ),
                )
              ],
            )
          ),
          Container(
            // color: Colors.orange,
            child: VoiceMessageSendWidget((cancel, path, seconds) {
              if (cancel == true) {
                return;
              }

            }),
          ),
        ],
      ),
    );
  }
}
