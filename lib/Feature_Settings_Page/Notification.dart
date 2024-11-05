import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

void showRegistrationComplete(BuildContext context) {
  final snackBar = SnackBar(
    content: AwesomeSnackbarContent(
      title: '등록 완료!',
      message: '주파수가 등록되었습니다!',
      contentType: ContentType.success,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
