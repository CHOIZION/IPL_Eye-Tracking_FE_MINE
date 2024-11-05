import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:real_test/Color/constants.dart';
import 'package:real_test/User_Registration_Page/Machine_Recognition.dart';
import 'package:real_test/Controllers/Feature/Start_Controller.dart'; // StartController 임포트

class RegistrationBtn extends StatelessWidget {
  final double? width;
  final double? height;

  const RegistrationBtn({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final StartController startController = Get.put(StartController()); // StartController 인스턴스 생성

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 아이 트래킹 시작하기 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () {
              startController.startEyeTracking(); // 아이 트래킹 시작하기 버튼을 눌렀을 때 startEyeTracking 메서드 호출
            },
            child: const Text(
              '아이 트래킹 시작하기',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 기기 등록하러 가기 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                _createRoute(),
              );
            },
            child: const Text(
              '기기 등록하러 가기',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// 페이지 간 애니메이션 넣기
Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => MachineRecognitionPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeIn;
      final tween = Tween(begin: begin, end: end);
      final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: child,
      );
    },
  );
}
