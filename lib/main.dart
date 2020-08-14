import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

void main() {
  // 增加详细的错误日志
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode)
      exit(1);
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.red,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: '颜值大师'),
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
  int _counter = 0;
  //用户通过摄像头或图片库选择的照片
  File _image;
  //记录接口返回的颜值信息或错误提示
  var _faceInfo = null;
  //记录用户返回的错误码：0 表示成功，其他表示错误
  var _errorCode;

  // 定义选取照片的函数
  void choosePic(ImageSource source) async{
//    _faceInfo = null;
    var image = await ImagePicker.pickImage(source: source);

    // 把用户选择的照片存储到 _image
    setState(() {
      _image = image;
    });

    print(image);

    getFactInfo();
    // 休眠5秒
//    sleep(Duration(seconds:5));
//    print("5s task");

  }

  // 调用API 获取颜值信息
  void getFactInfo() async{
    // 鉴权
    var dio = Dio();
    var url= 'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=5EPDjkewL4EPkDLgC7hRgtg4&client_secret=Muc5n4a8LLmNA1cExaTnSMLFdpsivwp7';
    Response response = await dio.post(url);

    var access_token = response.data['access_token'];
    print(access_token);

    // 把图片从file 类型转为 base64 字符串类型
    List<int> imageBytes = await _image.readAsBytes();
    var base64Img = base64Encode(imageBytes);

    // 调用颜值检测API
    var url2 = "https://aip.baidubce.com/rest/2.0/face/v3/detect?access_token="+access_token;
    var faceInfoResult = await dio.post(url2, options: new Options(contentType: "application/json"),
        data: {
          'image': base64Img,
          'image_type': 'BASE64',
          'face_field': 'age,beauty,expression,face_shape,gender,glasses',

        });

    print("--face info result----------->");
    print(faceInfoResult);
    print("----------->");

    if(faceInfoResult.data["error_msg"] == "SUCCESS") {
      setState(() {
        _faceInfo = faceInfoResult.data["result"]["face_list"][0];
        _errorCode = faceInfoResult.data["error_code"];
      });
    } else {
      setState(() {
        _faceInfo = faceInfoResult.data["error_msg"];
        _errorCode = faceInfoResult.data["error_code"];
      });

    }
  }


  // 渲染整个页面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: renderBody(),
      floatingActionButton: renderFloatingActionButton(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // 渲染头部
  Widget renderAppBar(){
    return AppBar(
      title: Text(widget.title),
      centerTitle: true,
    );
  }

  // 渲染页面主体
  Widget renderBody(){
    if(_image == null){
      return Center(
          child: Text("请选择照片！"),
      );
    }
    // 设置显示照片，以及宽高的模式
    return renderResult();
  }

  // 返回图片
  Widget renderResult(){
    return Stack(
      children: <Widget>[
        Image.file(_image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        renderBox(),
      ],
    );
  }

  Widget renderBox() {
    if(_errorCode != 0){
      print("aaaa");
      print(_faceInfo);
      return Center(
        child: Container(
          color: Colors.white54,
          width: 300,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: Text(_faceInfo == null ? "loading...": _faceInfo,
                        textAlign: TextAlign.center,
                         style: TextStyle(
                           fontSize: 20,
                           color: Colors.black,
                        ),)
                  )
                ],
              )
            ]

          ),
        ),
      );
    } else {
      print("bbbb");
      print(_faceInfo);
      return Center(
        child: Container(
          color: Colors.white54,
          width: 300,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('年龄：${_faceInfo['age']} 岁'),
                  Text('颜值：${_faceInfo['beauty']} 分'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('表情：${_faceInfo['expression']['type']} '),
                  Text('脸型： ${_faceInfo['face_shape']['type']}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('性别：${_faceInfo['gender']['type']} '),
                  Text('眼镜：${_faceInfo['glasses']['type']}'),
                ],
              )
            ],
          ),
        ),
      );
    }
  }

  // 渲染 底部的 浮动按钮
  Widget renderFloatingActionButton(){
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
      // 第一个相册按钮
      FloatingActionButton(
        onPressed: (){
          choosePic(ImageSource.camera);
        },
        tooltip: 'Increment',
        child: Icon(Icons.photo_camera),
      ),

    // 第二个照片按钮
    FloatingActionButton(
      onPressed: (){
        choosePic(ImageSource.gallery);
      },
      tooltip: 'Increment',
      child: Icon(Icons.photo_library),
      )
      ],
    );
  }

}
