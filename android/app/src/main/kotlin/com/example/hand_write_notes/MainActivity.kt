package com.example.hand_write_notes

import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "install_permission_checker"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isInstallPermissionGranted") {
                val isGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    packageManager.canRequestPackageInstalls()
                } else {
                    try {
                        Settings.Secure.getInt(
                            contentResolver,
                            Settings.Secure.INSTALL_NON_MARKET_APPS
                        ) == 1
                    } catch (e: Settings.SettingNotFoundException) {
                        false
                    }
                }
                result.success(isGranted)
            } else {
                result.notImplemented()
            }
        }
    }
}
