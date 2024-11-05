import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // 바이너리 데이터를 처리하기 위해 추가
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart'; // WidgetsBindingObserver를 사용하기 위해 추가
import 'package:real_test/Controllers/Profile/Models_Profile.dart';
import 'package:real_test/Controllers/Login/Login_Controller.dart';

class ControllerProfile extends GetxController with WidgetsBindingObserver {
  var profiles = <ModelsProfile>[].obs; // 전체 프로필 목록을 저장할 Observable 리스트
  var imageBytes = <Rx<Uint8List?>>[].obs; // 이미지 바이너리 데이터를 저장할 리스트
  var homeId = 0.obs;

  final LoginController loginController = Get.find();

  // 새로운 변수: 매핑된 데이터를 저장할 리스트
  var mappedProfiles = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 관찰자 추가

    homeId.value = loginController.homeId.value;
    fetchProfiles();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 생명주기 관찰자 제거
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포커스를 얻었을 때 실행되는 코드
      fetchProfiles();
    }
  }

  @override
  void onPageResume() {
    // 페이지로 돌아올 때 데이터 갱신
    fetchProfiles();
  }

  void setHomeId(int id) {
    homeId.value = id;
    fetchProfiles();
  }

  // 매핑된 데이터를 추출하는 함수 추가
  List<Map<String, dynamic>> getMappedProfiles() {
    return mappedProfiles.toList(); // 저장된 매핑 데이터 리스트 반환
  }

  Future<void> fetchProfiles() async {
    final url = dotenv.env['FIND_ALL_MEMBERS_URL'] ?? '';
    if (url.isEmpty) {
      print('FIND_ALL_MEMBERS_URL is not defined in .env file');
      return;
    }

    try {
      final requestUrl = Uri.parse('$url?homeId=${homeId.value}');
      final response = await http.get(requestUrl);

      // 응답 헤더 출력
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        String contentType = response.headers['content-type'] ?? '';
        print('Content-Type: $contentType');

        if (contentType.contains('multipart/form-data')) {
          String boundary = contentType.split("boundary=")[1];
          List<String> parts = response.body.split("--$boundary");

          profiles.clear();
          imageBytes.clear();
          mappedProfiles.clear(); // 이전에 저장된 매핑 데이터 초기화

          // 홈 아이디 별로 멤버들을 저장할 Map
          Map<int, List<ModelsProfile>> groupedProfiles = {};

          // 추가된 부분: 응답 파트별로 로그 출력
          print('Total Parts: ${parts.length}');

          int profileIndex = -1; // 프로필과 이미지 매칭을 위한 인덱스

          for (String part in parts) {
            if (part.contains("Content-Disposition")) {
              // 파트의 헤더와 내용을 분리
              var headerAndBody = part.split('\r\n\r\n');
              if (headerAndBody.length < 2) continue; // 잘못된 파트 무시

              String headers = headerAndBody[0];
              String body = headerAndBody[1].trim();

              // 헤더 출력
              print('Part Headers: $headers');

              if (headers.contains('name="memberData"')) {
                // JSON 데이터를 UTF-8로 디코딩
                var jsonData = jsonDecode(utf8.decode(body.codeUnits));

                String name = jsonData['name'];
                int memberId = jsonData['memberId'];
                int homeIdFromServer = homeId.value; // 서버에서 가져온 homeId

                ModelsProfile profile = ModelsProfile(
                  id: memberId,
                  name: name,
                );

                // 홈 아이디별로 멤버를 그룹화
                if (!groupedProfiles.containsKey(homeIdFromServer)) {
                  groupedProfiles[homeIdFromServer] = [];
                }
                groupedProfiles[homeIdFromServer]!.add(profile);

                // 멤버 아이디 로그 출력
                print('Member Data - Member ID: $memberId, Name: $name, Home ID: $homeIdFromServer');

                profileIndex++; // 프로필 인덱스 증가
                imageBytes.add(Rx<Uint8List?>(null)); // 이미지 자리 확보

              } else if (headers.contains('name="photo"')) {
                // 이미지 데이터 처리
                var imageData = body.codeUnits;
                var bytes = Uint8List.fromList(imageData);

                // 이미지 데이터 크기 로그 출력
                print('Photo Data - Size: ${bytes.length} bytes');

                if (profileIndex >= 0 && profileIndex < imageBytes.length) {
                  imageBytes[profileIndex].value = bytes;
                } else {
                  print('Error: Profile index out of range for image data');
                }
              }
            }
          }

          // 그룹별로 멤버 아이디 정렬 후 프로필 매핑
          groupedProfiles.forEach((homeIdKey, memberList) {
            memberList.sort((a, b) => a.id.compareTo(b.id)); // 멤버 아이디로 정렬

            for (var i = 0; i < memberList.length; i++) {
              final profile = memberList[i];
              // 매핑된 결과 로그 출력
              print('Mapped Profile: Home ID: $homeIdKey, Profile ${i + 1}: Member ID: ${profile.id}, Name: ${profile.name}');

              // 매핑된 데이터 저장
              mappedProfiles.add({
                'homeId': homeIdKey,
                'profileIndex': i + 1,
                'memberId': profile.id,
                'name': profile.name,
              });

              profiles.add(profile);
              // 이미지 데이터는 이미 위에서 처리됨
            }
          });

        } else {
          print("Unexpected Content-Type: $contentType");
        }
      } else if (response.statusCode == 400) {
        print('Error 400: 사용자를 찾을 수 없습니다.');
      } else {
        print('Error: Failed to load profiles with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  void addProfile(ModelsProfile profile) {
    profiles.add(profile);
    imageBytes.add(Rx<Uint8List?>(null)); // 새 프로필 추가 시 이미지 데이터 리스트도 동기화
  }
}
