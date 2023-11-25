

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:voice_input/event.dart';
import 'package:voice_input/voice_touch_point_change.dart';

class VoiceMessageSendWidget extends StatefulWidget {

  final Function(bool cancel, String path, int duration) sendVoiceMessage;
  final bool talentMassSend;
  final int maxDuration;
  final int minDuration;

  VoiceMessageSendWidget(this.sendVoiceMessage,
      {this.talentMassSend = false,
      this.maxDuration = 15,
      this.minDuration = 0})
      : super();

  @override
  State<StatefulWidget> createState() {
    return _VoiceMessageSendWidget();
  }
}

class _VoiceMessageSendWidget extends State<VoiceMessageSendWidget> with WidgetsBindingObserver {


  final double _height = 132;

  Timer? timer;
  Offset? position;
  int remind = 0;
  bool cancelHighlight = false;

  VoiceMessageSendWidgetStatus _status = VoiceMessageSendWidgetStatus.end;

  double bottom = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    eventBus.on<VoiceTouchPointChange>().listen((VoiceTouchPointChange bean) {
      // print('asldkfjslkadfjf ${bean.position}');

      //position 空代表手指停止移动，  有值代表手指正在移动
      if (mounted) {
        setState(() {

          position = bean.position;
          VoiceMessageSendWidgetStatus currentBean = bean.status;

          if(currentBean == VoiceMessageSendWidgetStatus.recording){

            if(_status != VoiceMessageSendWidgetStatus.recording){
              debugPrint('sdlfjlkf _speaking');
              _speaking();
            }

          } else{
            _status = bean.status;

            debugPrint('sdlfjlkf end');

            timer?.cancel();
            timer = null;

            if(cancelHighlight == true){
              debugPrint('sdlfjlkf cancelHighlight == true');

              // MediaUtil().stopRecordAudio();
              if(widget.minDuration < remind){
                widget.sendVoiceMessage(true, '', remind);
              } else {
                showToast('说话时间太短了',
                    dismissOtherToast: true,
                    position:ToastPosition.center,
                    radius: 8,
                    backgroundColor: Color.fromRGBO(0, 0, 0, 0.6),
                );
              }

            } else {
              debugPrint('sdlfjlkf _stopRecordAudio');
              _stopRecordAudio();//如果不是在取消区域手松开
            }
          }

          _status = bean.status;
          if(_status == VoiceMessageSendWidgetStatus.end){
            cancelHighlight = false;
          }
        });
      }
    });

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见

        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        _stopRecordAudio();//进入后台发出消息
        break;
      case AppLifecycleState.detached: // APP结束时调用
        break;
    }
  }

  _speaking() async {
    debugPrint('录制--开始');

    remind = 0;

    timer?.cancel();
    timer = null;

    timer = Timer.periodic(Duration(seconds: 1), (tmpTimer) {
      int count = tmpTimer.tick;
      if (count == widget.maxDuration) {
        _stopRecordAudio();

      }

      if (mounted) {
        setState(() {
          remind = count;
          if(count == widget.maxDuration){
            voiceSendEnough = true;
            eventBus.fire(VoiceTouchPointChange(null, VoiceMessageSendWidgetStatus.end));
          }
        });
      }
    });
  }

  //手松开 或者15s到了
  _stopRecordAudio(){
    debugPrint('录制--结束');

    if(widget.minDuration < remind){
        widget.sendVoiceMessage(false, 'filePath', remind == 0 ? 1 : remind);
      } else {
        showToast('说话时间太短了',
          dismissOtherToast: true,
          position:ToastPosition.center,
          radius: 8,
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.6),
        );
      }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_status == VoiceMessageSendWidgetStatus.end){
      return Container();
    }

    String title = '松开发送';
    cancelHighlight = false;
    if(_status == VoiceMessageSendWidgetStatus.recording){
      debugPrint('lkjlkjlkjlkj ${position?.dy}  $bottom');
      bottom = MediaQuery.of(context).size.height - (_height + kToolbarHeight + MediaQuery.of(context).padding.bottom);
      if (position != null && position!.dy <= bottom) {//适配刘海屏底部
        title = '松开取消发送';
        cancelHighlight = true;
      }
    }

    return Container(
      color: Colors.grey.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset(
            'assets/voice_send.gif',
            width: 160,
            height: 54,
            color: Colors.white,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            coverIntToMMss(remind),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 64,
          ),
          Image.asset(
            'assets/${cancelHighlight ? "message_voice_cancel.png" : "message_voice_cancel_default.png"}',
            width: 64,
            height: 64,
          ),
          const SizedBox(
            height: 24,
          ),
          ClipPath(
            clipper: VoiceSendArcClipper(),
            child: Container(
              height: _height + MediaQuery.of(context).padding.bottom,
              width: 375,
              color: cancelHighlight ? const Color(0xff3C3C3E) : Colors.cyan,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String coverIntToMMss(int count) {
    String time = "00:${widget.maxDuration}";

    int tmp = widget.maxDuration - count; //倒数 所以减一下

    if (tmp >= 10) {
      time = "00:$tmp";
    } else {
      time = "00:0$tmp";
    }

    return time;
  }
}


class VoiceSendArcClipper extends CustomClipper<Path>{

  @override
  Path getClip(Size size) {

    Path path = Path();

    path.moveTo(0, 35);

    //上面的半圆
    path.quadraticBezierTo(size.width / 2, -35, size.width, 35);

    path.lineTo(size.width, size.height);

    path.lineTo(0, size.height);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
