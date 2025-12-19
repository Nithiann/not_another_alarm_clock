package com.nithiann.not_another_alarm_clock

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nithiann.not_another_alarm_clock/system_sounds"
    private val APP_LAUNCH_CHANNEL = "com.nithiann.not_another_alarm_clock/app_launch"
    private val PERMISSION_CHANNEL = "com.nithiann.not_another_alarm_clock/permissions"
    private var currentMediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method channel for app launch
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_LAUNCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    try {
                        launchAppFromBackground()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to launch app: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Method channel for permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasFullScreenIntentPermission" -> {
                    try {
                        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            notificationManager.canUseFullScreenIntent()
                        } else {
                            // On Android 11 and below, full screen intent is granted automatically if declared in manifest
                            true
                        }
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check full screen intent permission: ${e.message}", null)
                    }
                }
                "requestFullScreenIntentPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            // On Android 11 and below, permission is granted automatically
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request full screen intent permission: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemAlarmUri" -> {
                    val alarmType = call.argument<Any>("type").toString() ?: "default"
                    try {
                        val uri = when (alarmType) {
                            "default" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            else -> {
                                // Try to get specific alarm
                                val alarmNumber = alarmType.replace("alarm_", "").toIntOrNull()
                                if (alarmNumber != null && alarmNumber in 1..10) {
                                    // Try to get alarm by position in list
                                    try {
                                        val manager = RingtoneManager(this)
                                        manager.setType(RingtoneManager.TYPE_ALARM)
                                        val cursor = manager.cursor
                                        if (cursor != null && cursor.count > 0 && cursor.moveToPosition(alarmNumber - 1)) {
                                            // Get the URI directly from the manager
                                            val ringtoneUri = manager.getRingtoneUri(alarmNumber - 1)
                                            ringtoneUri ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                        } else {
                                            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                        }
                                    } catch (e: Exception) {
                                        // Fall back to default on any error
                                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                    }
                                } else {
                                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                }
                            }
                        }
                        result.success(uri?.toString())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get system alarm URI: ${e.message}", null)
                    }
                }
                "playSystemAlarm" -> {
                    val alarmType = call.argument<Any>("type").toString() ?: "default"
                    try {
                        // Stop any currently playing media
                        currentMediaPlayer?.stop()
                        currentMediaPlayer?.release()
                        currentMediaPlayer = null
                        
                        val uri = when (alarmType) {
                            "default" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            else -> {
                                val alarmNumber = alarmType.replace("alarm_", "").toIntOrNull()
                                if (alarmNumber != null && alarmNumber in 1..10) {
                                    try {
                                        val manager = RingtoneManager(this)
                                        manager.setType(RingtoneManager.TYPE_ALARM)
                                        val cursor = manager.cursor
                                        if (cursor != null && cursor.count > 0 && cursor.moveToPosition(alarmNumber - 1)) {
                                            manager.getRingtoneUri(alarmNumber - 1) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                        } else {
                                            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                        }
                                    } catch (e: Exception) {
                                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                    }
                                } else {
                                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                }
                            }
                        }
                        
                        if (uri != null) {
                            // Use MediaPlayer to play system alarm with looping support
                            currentMediaPlayer = MediaPlayer().apply {
                                setDataSource(this@MainActivity, uri)
                                setAudioAttributes(
                                    android.media.AudioAttributes.Builder()
                                        .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                        .build()
                                )
                                isLooping = true
                                prepare()
                                start()
                            }
                            result.success(true)
                        } else {
                            result.error("ERROR", "Failed to get alarm URI", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to play system alarm: ${e.message}", null)
                    }
                }
                "stopSystemAlarm" -> {
                    try {
                        currentMediaPlayer?.stop()
                        currentMediaPlayer?.release()
                        currentMediaPlayer = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop system alarm: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        currentMediaPlayer?.stop()
        currentMediaPlayer?.release()
        currentMediaPlayer = null
    }
    
    private fun launchAppFromBackground() {
        // This method is called from the background isolate
        // We need to launch the MainActivity from a context
        val context = applicationContext
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
        }
        context.startActivity(intent)
    }
    
    companion object {
        @JvmStatic
        fun launchApp(context: Context) {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            }
            context.startActivity(intent)
        }
    }
}
