import 'package:ccd/controllers/OtpController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatelessWidget {
  OtpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String email =
        (args != null && args['email'] != null) ? args['email'] : '';

    // Only create controller once per email
    final OtpController controller = Get.put(OtpController(email), tag: email);

    final defaultPinTheme = PinTheme(
      width: 53,
      height: 53,
      textStyle: const TextStyle(
          fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.blue),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Colors.blue[50],
      ),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset('assets/images/message.png',
                  width: 159.5, height: 177.8),
              const SizedBox(height: 30),
              const Text(
                'Verify Code',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    letterSpacing: 0.29,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  children: <TextSpan>[
                    const TextSpan(text: 'We sent a code to ('),
                    TextSpan(
                      text: email,
                      style: const TextStyle(color: Color(0xFF5B7FFF)),
                    ),
                    const TextSpan(
                        text: '). \nEnter it here to verify your identity'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Pinput does not need Obx, as it only writes to the controller
              Center(
                child: Pinput(
                  length: 5,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  onChanged: controller.setOtp,
                  onCompleted: (value) {
                    controller.setOtp(value);
                    controller.verifyOtp();
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Only the text and AppButton need Obx
              Obx(() => GestureDetector(
                    onTap: controller.isResending.value
                        ? null
                        : controller.resendOtp,
                    child: Text(
                      controller.isResending.value
                          ? 'Sending...'
                          : 'Resend Code',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5B7FFF),
                        decoration: TextDecoration.underline,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
              const SizedBox(height: 30),

              Obx(() => ElevatedButton(
                    onPressed: controller.isVerifying.value
                        ? null
                        : controller.verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(50), // full-width button
                      backgroundColor: Colors.deepPurple,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isVerifying.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text("Verifying...",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ],
                          )
                        : const Text(
                            "Verify",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
