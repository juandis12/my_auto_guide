package com.example.my_auto_guide

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
  private val channelName = "my_auto_guide/exact_alarms"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "canScheduleExactAlarms" -> {
            val can = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
              alarmManager.canScheduleExactAlarms()
            } else {
              true
            }
            result.success(can)
          }
          "requestScheduleExactAlarm" -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              val intent = Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
              intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              startActivity(intent)
            }
            result.success(true)
          }
          else -> result.notImplemented()
        }
      }
  }
}

