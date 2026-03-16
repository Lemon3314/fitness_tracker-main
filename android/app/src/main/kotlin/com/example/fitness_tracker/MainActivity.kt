package com.example.fitness_tracker

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 1. 繼承 SensorEventListener 才能讓這個類別具有「聽力」
class MainActivity : FlutterActivity(), SensorEventListener {

    private val CHANNEL = "com.example.fitness/steps"
    private var dailySteps = 0
    private var sensorManager: SensorManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        loadData() // <--- 1. 啟動時先讀取舊數據


        // 2. 初始化傳感器管理員，並指定要聽「加速度計 (Accelerometer)」
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accel = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // 註冊監聽：讓系統不斷把震動數據傳進來
        sensorManager?.registerListener(this, accel, SensorManager.SENSOR_DELAY_NORMAL)

        // 3. 設定對講機的「接聽器」

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {call, result ->
            when(call.method) {
                "getDailySteps" -> {
                    result.success(dailySteps)
                }
                "resetSteps" -> {
                    // 執行重置邏輯
                    dailySteps = 0
                    saveData() // 記得要存檔，不然重開 App 舊資料又會回來
                    result.success(0) // 回傳 0 給 Flutter 告知成功
                }
                "addSteps" -> {
                    val steps = call.argument<Int>("steps")
                    dailySteps += steps?:0
                    saveData()
                    result.success(dailySteps)
                }
                else -> result.notImplemented()
            }
        }
    }

    // 4. 這是核心邏輯：當手機震動時，系統會自動跑這個 function
    override fun onSensorChanged(event: SensorEvent?) {
        if(event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            // 計算向量總長（畢氏定理的 3D 版）
            val magnitude = Math.sqrt((x*x + y*y + z*z).toDouble()).toFloat()
            // 9.8 是地球引力，差值 delta 代表「晃動強度」
            val delta = Math.abs(magnitude - 9.8f)


            if(delta > 2.0f) {
                dailySteps ++
                saveData() // <--- 2. 每加一步就存一次，保證資料不丟失
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // 儲存數據：把 dailySteps 寫進名為 "FitnessData" 的文件中
    private fun saveData() {
        val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putInt("daily_steps", dailySteps)
        editor.apply()
    }

    private fun loadData() {
        val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)
        dailySteps = prefs.getInt("daily_steps", 0)
    }

}
