package com.example.oom_demo

import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.app.ActivityManager
import android.content.Intent
import android.os.Debug
import android.os.SystemClock
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fpsoverlay/system"
    private val AUDIOCHANNEL = "com.example.audio/system"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSystemStats") {
                val stats = getAppSystemStats()
                result.success(stats)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getAppSystemStats(): Map<String, Any> {
        val cpuUsage = getAppCpuUsage()
        val memoryUsage = getAppMemoryUsage()
        return mapOf("cpu" to cpuUsage, "memory" to memoryUsage)
    }

    private var lastCpuTime: Long = 0
    private var lastUptime: Long = 0

    private fun getAppCpuUsage(): String {
        try {
            // 当前进程的 CPU 时间（单位：毫秒）
            val appCpuTime = Debug.threadCpuTimeNanos() / 1_000_000
            // 系统的运行时间（单位：毫秒）
            val uptime = SystemClock.elapsedRealtime()

            if (lastCpuTime == 0L || lastUptime == 0L) {
                // 初始化采样时间
                lastCpuTime = appCpuTime
                lastUptime = uptime
                return "Calculating..."
            }

            // 计算 CPU 使用率
            val cpuUsage = 100 * (appCpuTime - lastCpuTime).toFloat() / (uptime - lastUptime)

            // 更新上次采样时间
            lastCpuTime = appCpuTime
            lastUptime = uptime

            return String.format("%.2f%%", cpuUsage.coerceIn(0f, 100f)) // 限制结果在 0-100% 之间
        } catch (e: Exception) {
            e.printStackTrace()
            return "N/A"
        }
    }

    private fun getAppMemoryUsage(): String {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(memoryInfo)
        val totalPss = memoryInfo.totalPss // in KB
        return (totalPss / 1024).toString() // Convert to MB
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        /// 设置状态栏透明，导航栏沉浸。
//    getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
        window.statusBarColor = Color.TRANSPARENT
    }
}