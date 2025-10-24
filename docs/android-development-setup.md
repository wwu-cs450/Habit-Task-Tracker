# How to set up development for Android

## Install Flutter

[Here](https://docs.flutter.dev/platform-integration/android/setup) is the official documentation for setting up Flutter for Android development.

You can download and install Flutter manually from their website, but in this guide we'll install it through VS Code.

1. [Install the Flutter extension.](vscode:extension/Dart-Code.flutter)
2. When prompted, download the Flutter SDK.
3. In the Command Palette (`Ctrl` / `Cmd` + `Shift` + `P`), select **Flutter: Run Flutter Doctor**. The output should show that Android Studio is not installed.

## Install Android Studio

You won't need to open Android Studio to run the project, just to install the Android SDK. You can grab the download from [here](https://developer.android.com/studio). If it displays "Your device is not available," try using Chrome/Chromium.

---

You'll need to unzip and copy the files to Program Files (or `/usr/local/`) and run `bin/studio64.exe` (or `bin/studio`) to launch the setup wizard. Click through the wizard and wait for it to download the SDK and emulator.

Once you've gotten to the welcome page, select **More actions**. It may show up as three dots next to the **Clone repository** option. Then select **SDK Manager > SDK Tools > Android SDK Command-line Tools (latest)** and press **OK** to install the command-line tools needed for Flutter.

Lastly, run `flutter doctor` again to make sure "Android toolchain" doesn't have any issues. You'll have to run `flutter doctor --android-licenses` to accept the Android licenses.

## Set up Android device

You can set up the project to use the emulator that comes with Android studio--instructions [here](https://docs.flutter.dev/platform-integration/android/setup). To set up the project on your physical Android device:

1. [Enable developer options and USB debugging](https://developer.android.com/studio/debug/dev-options)
2. If on Windows, [install USB drivers](https://developer.android.com/studio/run/oem-usb)
3. Connect your device to your computer with a USB cable
4. In the popup on your Android device, allow USB debugging
4. Run `flutter devices` to verify that Flutter is connected to your device

## Build and run project

1. Navigate to the root folder of the Flutter project. At the time of writing, this is `habit_task_tracker/`
2. Run `flutter run` to build the app and open on your connected device

Alternatively, you can run `flutter build apk` and then `flutter install`.
