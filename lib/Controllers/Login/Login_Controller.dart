import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart'; // GetStorage 가져오기
import 'package:flutter/material.dart';
import '../../Sign_Up_Page/Sign_Up_Page.dart';
import 'package:real_test/Controllers/Profile/Controller_Profile.dart';

class LoginController extends GetxController {
  final storage = GetStorage(); // GetStorage 인스턴스 생성
  var username = ''.obs;
  var password = ''.obs;
  var errorMessage = ''.obs;
  var homeId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // 앱이 시작되면 storage에서 homeId를 불러와 저장
    homeId.value = storage.read('homeId') ?? 0;
    print('로그인 정보 로드 - Home ID: ${homeId.value}');
  }

  void setUsername(String value) {
    username.value = value;
  }

  void setPassword(String value) {
    password.value = value;
  }

  Future<void> login() async {
    final url = dotenv.env['LOGIN_URL'] ?? '';

    if (url.isEmpty) {
      errorMessage.value = '로그인 URL이 설정되지 않았습니다.';
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': username.value,
          'password': password.value,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (int.parse(data['status']) == 200) {
          homeId.value = data['data'];
          storage.write('homeId', homeId.value); // homeId를 GetStorage에 저장
          print('Home ID: ${homeId.value}');
          Get.snackbar('Success', '홈 로그인 성공!');

          // ControllerProfile을 등록하고 homeId 설정
          Get.put(ControllerProfile());
          final controllerProfile = Get.find<ControllerProfile>();
          controllerProfile.setHomeId(homeId.value);

          Get.toNamed('/mainProfile');
        } else {
          errorMessage.value = data['message'];
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        errorMessage.value = data['message'];
      } else {
        errorMessage.value = '서버 오류가 발생했습니다.';
      }
    } catch (e) {
      errorMessage.value = '네트워크 오류가 발생했습니다. ${e.toString()}';
    }
  }

  void clearHomeId() {
    homeId.value = 0;
    storage.remove('homeId'); // 저장된 homeId 삭제
    print('Home ID가 초기화되었습니다.');
  }

  @override
  void onClose() {
    super.onClose();
    clearHomeId(); // 앱 종료 시 homeId 삭제
  }

  void navigateToSignUp(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}