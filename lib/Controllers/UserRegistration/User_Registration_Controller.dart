import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:real_test/Controllers/Login/Login_Controller.dart';

class UserRegistrationController extends GetxController with WidgetsBindingObserver {
  final List<TextEditingController> nameControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> descriptionControllers = List.generate(3, (_) => TextEditingController());
  var imageBytes = <Rx<Uint8List?>>[].obs;
  final LoginController loginController = Get.find();
  var devices = [].obs;

  var isLoading = false.obs; // 로딩 상태 관리

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchAllDevices(); // 컨트롤러 초기화 시 서버에서 기기 목록 가져오기
  }

  Future<void> fetchAllDevices() async {
    if (isLoading.value) {
      // 이미 로딩 중이면 새로운 요청을 막음
      return;
    }

    print('fetchAllDevices 호출됨: 갱신 시작');

    devices.clear();
    imageBytes.clear();

    final String? url = dotenv.env['FIND_ALL_DEVICES'];

    if (url == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'FIND_ALL_DEVICES_URL이 설정되지 않았습니다.');
      });
      return;
    }

    final homeId = loginController.homeId.value;
    print('homeId: $homeId');
    final requestUrl = '$url?homeId=$homeId';

    isLoading.value = true; // 로딩 시작
    try {
      final response = await http.get(Uri.parse(requestUrl));
      print('서버 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('boundary=')) {
          final boundary = contentType.split('boundary=')[1];
          var parts = response.body.split('--$boundary');

          for (var part in parts) {
            if (part.contains('Content-Disposition: form-data; name="deviceData"')) {
              var deviceDataJson = part.split('\r\n\r\n')[1].split('\r\n')[0];
              var deviceData = jsonDecode(utf8.decode(deviceDataJson.codeUnits));
              devices.add({
                'name': deviceData['name'],
                'id': deviceData['deviceId'],
              });
              imageBytes.add(Rx<Uint8List?>(null));
            } else if (part.contains('Content-Disposition: form-data; name="photo"')) {
              var imageIndex = devices.length - 1;
              var imageBinaryData = part.split('\r\n\r\n')[1].trim().codeUnits;
              var bytes = Uint8List.fromList(imageBinaryData);
              if (imageIndex >= 0 && imageIndex < imageBytes.length) {
                imageBytes[imageIndex].value = bytes;
              }
            }
          }

          print('전체 기기 조회 성공: ${devices.length}개의 기기가 로드되었습니다.');
        }
      } else if (response.statusCode == 400) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar('Error', '홈을 찾을 수 없습니다.');
        });
      } else {
        var responseData = jsonDecode(response.body);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar('Error', responseData['message'] ?? '전체 기기 조회 실패');
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', '전체 기기 조회 중 오류 발생: $e');
      });
    } finally {
      isLoading.value = false; // 로딩 종료
    }

    print('fetchAllDevices 완료됨: 갱신 종료');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화될 때마다 기기 목록을 새로 고침
    if (state == AppLifecycleState.resumed) {
      fetchAllDevices();
    }
  }

  @override
  void onClose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in descriptionControllers) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
