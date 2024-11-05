import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:real_test/Controllers/UserRegistration/User_Registration_Controller.dart';
import 'package:real_test/Color/constants.dart';

class AlreadyDevicePart extends StatelessWidget {
  final UserRegistrationController controller = Get.find<UserRegistrationController>();

  AlreadyDevicePart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (controller.devices.isEmpty) {
        return const Center(
          child: Text('등록된 기기가 없습니다.'),
        );
      } else {
        return ListView.builder(
          itemCount: controller.devices.length,
          itemBuilder: (context, index) {
            final device = controller.devices[index];
            final imageBytes = controller.imageBytes.length > index ? controller.imageBytes[index].value : null;
            final bool isLastItem = index == controller.devices.length - 1;

            return Column(
              children: [
                const Divider(color: AppColors.greyLineColor, thickness: 0.5),
                ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: imageBytes != null
                        ? Image.memory(imageBytes)
                        : const Icon(Icons.devices),
                  ),
                  title: Text(device['name']),
                  subtitle: Text('ID: ${device['id']}'),
                  onTap: () {
                    // 기기 클릭 시 기능 추가 예정
                  },
                ),
                if (isLastItem)
                  const Divider(color: AppColors.greyLineColor, thickness: 0.5),
              ],
            );
          },
        );
      }
    });
  }
}
