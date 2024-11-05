import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_test/Controllers/Login/Login_Controller.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import '../Profile/Controller_Profile.dart';
import 'package:real_test/Profile_Page/Main_Profile.dart';

class ProfileController extends GetxController {
  var selectedImage = Rx<XFile?>(null);
  final ImagePicker _picker = ImagePicker();
  final LoginController loginController = Get.find(); // LoginController 인스턴스 가져오기
  final TextEditingController nameController = TextEditingController();
  final ControllerProfile profileController = Get.find<ControllerProfile>(); // ControllerProfile 인스턴스 가져오기

  Future<void> getImage(ImageSource imageSource) async {
    print('이미지 선택 시작');
    final XFile? selectImage = await _picker.pickImage(
      source: imageSource,
    );
    if (selectImage != null) {
      print('이미지 선택 완료: ${selectImage.path}');
      selectedImage.value = selectImage;
      //await uploadImage(selectImage.path);
    } else {
      print('이미지 선택 취소 또는 실패');
    }
  }

  Future<void> uploadImage(int id, String name, String filePath) async {
    print('이미지 업로드 시작');
    if (filePath != null) {
      print('파일 경로: $filePath');
      final url = dotenv.env['UPDATE_MEMBER_URL'] ?? ''; //.env 파일에서 UPDATE_MEMBER_URL 가져오기
      print('업로드 URL: $url');

      if (url.isEmpty) {
        Get.snackbar('실패', 'UPDATE_MEMBER_URL이 설정되지 않았습니다.');
        print('ERROR: UPDATE_MEMBER_URL이 설정되지 않았습니다.');
        return;
      }

      var request = http.MultipartRequest('PUT', Uri.parse(url));
      print('MultipartRequest 생성 완료');

      // 사용자 ID
      request.fields['id'] = id.toString(); // ID 설정
      print('request.fields["id"] = ${request.fields["id"]}');

      // 새로운 사용자 이름
      request.fields['name'] = name; // 입력된 이름 사용
      print('request.fields["name"] = ${request.fields["name"]}');

      // 새로운 사진 파일
      print('파일 추가 시작');
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        filePath,
        contentType: MediaType('image', 'jpeg'), // 적절한 MIME 타입 설정
      ));
      print('파일 추가 완료');

      try {
        print('요청 전송 중...');
        var response = await request.send();
        print('응답 상태 코드: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('이미지 업로드 성공');
          Get.snackbar('성공', '사진 업로드 성공');

          print('프로필 데이터 다시 가져오기 시작');
          await profileController.fetchProfiles(); // 데이터 다시 불러오기
          print('프로필 데이터 다시 가져오기 완료');

          Get.back(); // 페이지 닫기
          print('현재 페이지 닫음');

          // 기존 페이지를 닫고 MainProfilePage로 이동
          Get.off(() => MainProfilePage()); // MainProfilePage로 이동 및 기존 페이지를 대체
          print('MainProfilePage로 이동');
        } else {
          var responseData = await http.Response.fromStream(response);
          var responseBody = jsonDecode(responseData.body);
          print('응답 본문: $responseBody');

          Get.snackbar('실패', responseBody['message'] ?? '사진 업로드 실패');
          print('사진 업로드 실패: ${responseBody['message']}');
        }
      } catch (e) {
        Get.snackbar('오류', '사진 업로드 중 오류가 발생했습니다: $e');
        print('사진 업로드 중 오류 발생: $e');
      }
    } else {
      print('ERROR: 파일 경로가 null입니다.');
    }
  }

  Future<void> uploadjustname(int id, String name) async {
    print('이름만 업로드 시작');
    final url = dotenv.env['UPDATE_MEMBER_URL'] ?? ''; //.env 파일에서 UPDATE_MEMBER_URL 가져오기
    print('업로드 URL: $url');

    if (url.isEmpty) {
      Get.snackbar('실패', 'UPDATE_MEMBER_URL이 설정되지 않았습니다.');
      print('ERROR: UPDATE_MEMBER_URL이 설정되지 않았습니다.');
      return;
    }

    var request = http.Request('PUT', Uri.parse(url));
    print('Request 생성 완료');

    // 사용자 ID와 이름을 폼 데이터로 추가
    request.bodyFields = {
      'id': id.toString(),
      'name': name,
    };
    print('request.bodyFields: ${request.bodyFields}');

    try {
      print('요청 전송 중...');
      var response = await request.send();
      print('응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('데이터 업로드 성공');
        Get.snackbar('성공', '데이터 업로드 성공');

        print('프로필 데이터 다시 가져오기 시작');
        await profileController.fetchProfiles(); // 데이터 다시 불러오기
        print('프로필 데이터 다시 가져오기 완료');

        Get.back(); // 페이지 닫기
        print('현재 페이지 닫음');

        Get.off(() => MainProfilePage()); // MainProfilePage로 이동 및 기존 페이지를 대체
        print('MainProfilePage로 이동');
      } else {
        var responseData = await http.Response.fromStream(response);
        var responseBody = jsonDecode(responseData.body);
        print('응답 본문: $responseBody');

        Get.snackbar('실패', responseBody['message'] ?? '데이터 업로드 실패');
        print('데이터 업로드 실패: ${responseBody['message']}');
      }
    } catch (e) {
      Get.snackbar('오류', '데이터 업로드 중 오류가 발생했습니다: $e');
      print('데이터 업로드 중 오류 발생: $e');
    }
  }
}
