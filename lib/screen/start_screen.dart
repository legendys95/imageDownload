import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

  String _status = '';

  Dio _dio = Dio();

  Future<void> _downloadImage() async {
    setState(() {
      _status = 'Downloading image...';
    });

    final url = 'https://images.rawpixel.com/image_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDIzLTA4L3Jhd3BpeGVsb2ZmaWNlMjBfYV9kaWdpdGFsX3JlbmRlcmluZ19kaWdpdGFsX2FydF9jb21tZXJjaWFsX2Jhbl8xNmY1NTllNC00MzU3LTRkOWYtOTUyNi04NGFhNDA4NzEzMzlfMS5qcGc.jpg'; // Replace with your image URL

    final directories = await getExternalStorageDirectories();
    final primaryDirectory = directories![0];

    final picturesDirectory = Directory('${primaryDirectory.path}/Pictures');
    if (!await picturesDirectory.exists()) {
      await picturesDirectory.create(recursive: true);
    }

    final filePath = '${picturesDirectory.path}/image24.jpg';
    final file = File(filePath);

    if (await file.exists()) {
      setState(() {
        _status = 'Image already downloaded: $filePath';
      });
      return;
    }

    try {
      final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes));
      final bytes = response.data;

      await file.writeAsBytes(bytes);

     // await _triggerMediaScan(filePath);

      setState(() {
        _status = 'Image downloaded to: $filePath';
      });
    } catch (e) {
      setState(() {
        _status = 'Error downloading image: $e';
      });
    }
  }


  Future<void> _triggerMediaScan(String filePath) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final method = MethodChannel('flutter.dev/media_scan');
      await method.invokeMethod('scanFile', <String, dynamic>{
        'filePath': filePath,
        'platform': platform,
      });
    } on PlatformException catch (e) {
      print('Failed to trigger media scan: ${e.message}');
    }
  }

  /*Future<void> _downloadImage() async {
    setState(() {
      _status = 'Downloading image...';
    });

    final url = 'https://images.rawpixel.com/image_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDIzLTA4L3Jhd3BpeGVsb2ZmaWNlMjBfYV9kaWdpdGFsX3JlbmRlcmluZ19kaWdpdGFsX2FydF9jb21tZXJjaWFsX2Jhbl8xNmY1NTllNC00MzU3LTRkOWYtOTUyNi04NGFhNDA4NzEzMzlfMS5qcGc.jpg'; // Replace with your image URL

    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final directories = await getExternalStorageDirectories();
    final primaryDirectory = directories![0];

    final picturesDirectory = Directory('${primaryDirectory.path}/Pictures');
    if (!await picturesDirectory.exists()) {
      await picturesDirectory.create(recursive: true);
    }

    final filePath = '${picturesDirectory.path}/${Random()}_image.jpg';

    File file = File(filePath);
    await file.writeAsBytes(bytes);



    setState(() {
      _status = 'Image downloaded to: $filePath';
    });
  }*/


  Future<List<File>> _getImagesFromFolder() async {
    final directories = await getExternalStorageDirectories();
    final primaryDirectory = directories![0];
    final picturesDirectory = Directory('${primaryDirectory.path}/Pictures');

    List<File> imageFiles = [];

    if (await picturesDirectory.exists()) {
      await for (var entity in picturesDirectory.list()) {
        if (entity is File) {
          if (_isImageFile(entity.path)) {
            imageFiles.add(entity);
          }
        }
      }
    }

    return imageFiles;
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    final extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Downloader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _downloadImage,
              child: Text('Download Image'),
            ),
            SizedBox(height: 20),
            Text(_status),

            ElevatedButton(
              onPressed: () async {
                final images = await _getImagesFromFolder();
                setState(() {
                  _status = 'Total images found: ${images.length}';
                });
              },
              child: Text('Get Images from Folder'),
            ),

          ],
        ),
      ),
    );
  }
}
