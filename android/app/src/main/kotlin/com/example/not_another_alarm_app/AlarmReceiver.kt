package com.nithiann.not_another_alarm_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Wake up the device
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "AlarmReceiver::WakeLock"
        )
        wakeLock.acquire(10 * 60 * 1000L) // 10 minutes max
        
        // Don't launch MainActivity here - the full-screen intent notification will handle it
        // Launching here causes double opening of the alarm screen
        // The notification service's full-screen intent will automatically launch the app
        
        // Release wake lock after a short delay
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }, 1000)
    }
}

