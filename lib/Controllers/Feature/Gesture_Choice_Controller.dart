import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'DeviceID_Controller.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

class GestureChoiceController extends GetxController {
  var selectedGesture = ''.obs;
  var gestures = <Map<String, dynamic>>[].obs;
  var usedGestures = <String>[].obs; // 타입을 String으로 변경

  void selectGesture(String gestureName) {
    if (usedGestures.contains(gestureName)) {
      _showSnackbar("중복된 제스처", "이 제스처는 이미 사용되었습니다. 다른 제스처를 선택해주세요.");
      print('Error: Gesture "$gestureName" is already used.');
      throw Exception("Gesture already used");
    } else {
      selectedGesture.value = gestureName;
      print('제스처 선택됨: $gestureName');
    }
  }

  void _showSnackbar(String title, String message) {
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: Colors.transparent,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        borderRadius: 10,
        messageText: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: ContentType.warning,
        ),
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchGestures();
    fetchFeatures();
  }

  Future<void> fetchGestures() async {
    final url = dotenv.env['FIND_ALL_GESTURES'];
    print('URL from .env: $url');

    if (url == null) {
      print("Error: URL not found in .env file");
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        gestures.clear();

        final boundary = '--' + response.headers['content-type']!.split('boundary=')[1];
        final parts = response.body.split(boundary).where((part) => part.isNotEmpty && part != '--').toList();
        print('Number of parts: ${parts.length}');

        for (int i = 0; i < parts.length; i += 2) {
          final gestureDataPart = parts[i];

          if (i + 1 >= parts.length) {
            print("Warning: Parts length is odd or malformed; skipping the last part.");
            break;
          }

          final imageDataPart = parts[i + 1];

          if (gestureDataPart.contains('Content-Disposition: form-data; name="gestureData"')) {
            final gestureDataJson = gestureDataPart.split('\r\n\r\n')[1].split('\r\n')[0];
            print('Raw gesture data JSON: $gestureDataJson');

            final gestureData = jsonDecode(utf8.decode(gestureDataJson.codeUnits));
            print('Parsed gesture data: $gestureData');

            // 이미 디코딩된 description 사용
            final description = gestureData['description'];

            if (imageDataPart.contains('Content-Disposition: form-data; name="photo"')) {
              final imageBinaryData = imageDataPart.split('\r\n\r\n')[1].trim();
              final imageData = Uint8List.fromList(imageBinaryData.codeUnits);

              gestures.add({
                'name': gestureData['name'],
                'description': description,
                'image': imageData,
              });
              print('Gesture added: ${gestureData['name']}');
            }
          }
        }
        print('Total gestures loaded: ${gestures.length}');
      } else {
        print('Error: Failed to load gestures. Status code: ${response.statusCode}');
        throw Exception("Failed to load gestures");
      }
    } catch (e) {
      print("Error fetching gestures: $e");
    }
  }

  Future<void> fetchFeatures() async {
    final deviceIdController = Get.find<DeviceController>();
    final deviceId = deviceIdController.deviceid.value;

    final url = dotenv.env['IS_SELECTED'];
    print('URL from .env: $url');

    if (url == null) {
      print("Error: URL not found in .env file");
      return;
    }

    try {
      final response = await http.get(Uri.parse('$url?deviceId=$deviceId'));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response data: $responseData');  // 응답 데이터 구조를 확인

        final features = responseData['features'] as List;

        usedGestures.clear();

        for (var feature in features) {
          final gestureName = feature['gestureName'] as String;
          print('Parsed gestureName: $gestureName');  // gestureName 값 확인

          usedGestures.add(gestureName);
        }
        print('Used gestures: $usedGestures');
      } else {
        print('Error: Failed to load features. Status code: ${response.statusCode}');
        throw Exception("Failed to load features");
      }
    } catch (e) {
      print("Error fetching features: $e");
    }
  }
}
