import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:ui' as ui show Image;
// package publish gives warning for those imports
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _editNode = FocusNode();
  final _video = TextEditingController(
      text:
          "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4");
  ImageFormat _format = ImageFormat.JPEG;
  int _quality = 50;
  int _size = 0;
  int _timeMs = 0;

  int _imageDataSize;
  ui.Image _uiImageInData;
  Image _imageInData;

  int _imageFileSize;
  ui.Image _uiImageInFile;
  Image _imageInFile;

  String _tempDir;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Thumbnail Plugin example'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    isDense: true,
                    labelText: "Video URI",
                  ),
                  maxLines: null,
                  controller: _video,
                  focusNode: _editNode,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    _editNode.unfocus();
                  },
                ),
              ),
              Slider(
                value: _size * 1.0,
                onChanged: (v) => setState(() {
                  _editNode.unfocus();
                  _size = v.toInt();
                }),
                max: 512.0,
                divisions: 256,
                label: "$_size",
              ),
              Center(
                child: (_size == 0)
                    ? const Text("Original of the video's")
                    : Text("Max height/width: $_size(px)"),
              ),
              Slider(
                value: _timeMs * 1.0,
                onChanged: (v) => setState(() {
                  _editNode.unfocus();
                  _timeMs = v.toInt();
                }),
                max: 10.0 * 1000,
                divisions: 1000,
                label: "$_timeMs",
              ),
              Center(
                child: (_timeMs == 0)
                    ? const Text("The beginning of the video")
                    : Text("The closest frame at $_timeMs(ms) of the video"),
              ),
              Slider(
                value: _quality * 1.0,
                onChanged: (v) => setState(() {
                  _editNode.unfocus();
                  _quality = v.toInt();
                }),
                max: 100.0,
                divisions: 100,
                label: "$_quality",
              ),
              Center(child: Text("Quality: $_quality")),
              Padding(
                padding: const EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 8.0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    isDense: true,
                    labelText: "Thumbnail Format",
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Radio<ImageFormat>(
                              groupValue: _format,
                              value: ImageFormat.JPEG,
                              onChanged: (v) => setState(() {
                                _format = v;
                                _editNode.unfocus();
                              }),
                            ),
                            const Text("JPEG"),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Radio<ImageFormat>(
                              groupValue: _format,
                              value: ImageFormat.PNG,
                              onChanged: (v) => setState(() {
                                _format = v;
                                _editNode.unfocus();
                              }),
                            ),
                            const Text("PNG"),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Radio<ImageFormat>(
                              groupValue: _format,
                              value: ImageFormat.WEBP,
                              onChanged: (v) => setState(() {
                                _format = v;
                                _editNode.unfocus();
                              }),
                            ),
                            const Text("WebP"),
                          ]),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        Center(
                          child: (_uiImageInData == null)
                              ? Text("image_is_null")
                              : Text(
                                  "Image size: $_imageDataSize, width:${_uiImageInData?.width}, height:${_uiImageInData?.height}"),
                        ),
                        (_imageInData == null)
                            ? const SizedBox()
                            : _imageInData,
                        Container(
                          color: Colors.grey,
                          height: 1.0,
                        ),
                        Center(
                          child: (_uiImageInFile == null)
                              ? Text("file_is_null")
                              : Text(
                                  "File size: $_imageFileSize, width:${_uiImageInFile?.width}, height:${_uiImageInFile?.height}"),
                        ),
                        (_imageInFile == null)
                            ? const SizedBox()
                            : _imageInFile,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton(
                onPressed: () async {
                  File video =
                      await ImagePicker.pickVideo(source: ImageSource.camera);
                  setState(() {
                    _video.text = video.path;
                  });
                },
                child: Icon(Icons.videocam),
                tooltip: "Capture a video",
              ),
              const SizedBox(
                width: 5.0,
              ),
              FloatingActionButton(
                onPressed: () async {
                  File video =
                      await ImagePicker.pickVideo(source: ImageSource.gallery);
                  setState(() {
                    _video.text = video?.path;
                  });
                },
                child: Icon(Icons.local_movies),
                tooltip: "Pick a video",
              ),
              const SizedBox(
                width: 20.0,
              ),
              FloatingActionButton(
                tooltip: "Generate a data of thumbnail",
                onPressed: () async {
                  if (_imageInData != null) {
                    setState(() {
                      _imageInData = null;
                      _uiImageInData = null;
                    });
                  }

                  final thumbnail = await VideoThumbnail.thumbnailData(
                      video: _video.text,
                      imageFormat: _format,
                      maxHeightOrWidth: _size,
                      timeMs: _timeMs,
                      quality: _quality);

                  _imageDataSize = thumbnail.length;
                  print("image data size: $_imageDataSize");

                  _imageInData = Image.memory(thumbnail)
                    ..image.resolve(ImageConfiguration()).addListener(
                        ImageStreamListener((ImageInfo info, bool _) {
                      setState(() {
                        _uiImageInData = info.image;
                      });
                    }));
                },
                child: const Text("Data"),
              ),
              const SizedBox(
                width: 5.0,
              ),
              FloatingActionButton(
                tooltip: "Generate a file of thumbnail",
                onPressed: () async {
                  if (_imageInFile != null) {
                    setState(() {
                      _imageInFile = null;
                      _uiImageInFile = null;
                    });
                  }

                  final thumbnail = await VideoThumbnail.thumbnailFile(
                      video: _video.text,
                      thumbnailPath: _tempDir,
                      imageFormat: _format,
                      maxHeightOrWidth: _size,
                      timeMs: _timeMs,
                      quality: _quality);

                  print("thumbnail file is located: $thumbnail");

                  final file = File(thumbnail);
                  _imageFileSize = file.lengthSync();
                  final bytes = file.readAsBytesSync();

                  print("image file size: $_imageFileSize");

                  _imageInFile = Image.memory(bytes)
                    ..image.resolve(ImageConfiguration()).addListener(
                        ImageStreamListener((ImageInfo info, bool _) {
                      setState(() {
                        _uiImageInFile = info.image;
                      });
                    }));
                },
                child: const Text("File"),
              ),
              FloatingActionButton(
                tooltip: "YO",
                onPressed: () async {
                  if (_imageInFile != null) {
                    setState(() {
                      _imageInFile = null;
                      _uiImageInFile = null;
                    });
                  }
                  String yo = 'https://firebasestorage.googleapis.com/v0/b/hire-7dbb2.appspot.com/o/1573000398376.mp4?alt=media&token=4dfce3c4-60f2-4ee0-ba0b-b3805be6c529';
                  final thumbnail = await VideoThumbnail.thumbnailFile(
                      video: yo,
                      thumbnailPath: _tempDir,
                      imageFormat: _format,
                      maxHeightOrWidth: _size,
                      timeMs: _timeMs,
                      quality: _quality);

                  print("thumbnail file is located: $thumbnail");

                  final file = File(thumbnail);
                  _imageFileSize = file.lengthSync();
                  final bytes = file.readAsBytesSync();

                  print("image file size: $_imageFileSize");

                  _imageInFile = Image.memory(bytes)
                    ..image.resolve(ImageConfiguration()).addListener(
                        ImageStreamListener((ImageInfo info, bool _) {
                      setState(() {
                        _uiImageInFile = info.image;
                      });
                    }));
                },
                child: const Text("YO"),
              ),
            ],
          )),
    );
  }
}
