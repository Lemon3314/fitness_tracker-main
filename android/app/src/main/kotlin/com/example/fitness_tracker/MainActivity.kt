package com.example.fitness_tracker

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// 1. 繼承 SensorEventListener 才能讓這個類別具有「聽力」
class MainActivity : FlutterActivity(), SensorEventListener {

    private val CHANNEL = "com.example.fitness/steps"
    private var dailySteps = 0
    private var sensorManager: SensorManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        loadData() // <--- 1. 啟動時先讀取舊數據
        checkNewDay() // <--- 啟動時檢查是否跨日


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
                // MainActivity.kt 內的 getHistory 區塊
                "getHistory" -> {
                    val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)
                    val historyString = prefs.getString("history_list", "[]") ?: "[]"

                    try {
                        val jsonArray = JSONArray(historyString)
                        val today = getCurrentDate() // 取得今天日期 yyyy-MM-dd

                        // 檢查歷史紀錄中是否已經有今天的資料（避免重複顯示）
                        var todayFound = false
                        for (i in 0 until jsonArray.length()) {
                            val item = jsonArray.getJSONObject(i)
                            if (item.getString("date") == today) {
                                // 如果今天已經有紀錄（可能是剛結算），就更新它為最新即時步數
                                item.put("steps", dailySteps)
                                todayFound = true
                                break
                            }
                        }

                        // 如果歷史紀錄沒找到今天，就手動新增一個進去回傳給 Flutter
                        if (!todayFound) {
                            val todayRecord = JSONObject()
                            todayRecord.put("date", today)
                            todayRecord.put("steps", dailySteps)
                            jsonArray.put(todayRecord)
                        }

                        result.success(jsonArray.toString()) // 回傳包含「今天即時步數」的完整清單
                    } catch (e: Exception) {
                        result.success(historyString) // 出錯時回傳原始字串作為保險
                    }
                }
                "setSteps" -> {
                    // 取得 Flutter 傳來的指定步數
                    val steps = call.argument<Int>("steps") ?: 0
                    dailySteps = steps
                    saveData() // 覆寫原本的進度
                    result.success(dailySteps)
                }
                "simulateNextDay" -> {
                    // 抓取 Flutter 傳來的日期
                    val targetDate = call.argument<String>("date") ?: "1999-01-01"

                    // --- 關鍵修改點 ---
                    // 直接呼叫我們剛寫好的存檔方法，把「當前步數」存入「指定日期」
                    saveHistoryEntry(targetDate, dailySteps)

                    // 存完後將當前步數歸零
                    dailySteps = 0

                    // 同步更新當前步數到 Prefs，並更新最後存檔日期為「今天」
                    // 這樣可以防止 checkNewDay 在重啟 App 時又執行一次自動存檔
                    val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

                    prefs.edit()
                        .putInt("daily_steps", 0)
                        .putString("last_date", today)
                        .commit() // 使用 commit 確保資料立即寫入

                    result.success(0) // 回傳 0 給 Flutter 告知畫面該歸零了
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
                checkNewDay() // <--- 增加步數前先確認今天還是今天
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

    private fun getCurrentDate(): String {
        //格式化日期
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    private fun checkNewDay() {
        val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)
        val lastDate = prefs.getString("last_date", "") // 讀取上次存檔的日期
        val today = getCurrentDate()

        // 如果上次日期不是空的，且跟今天不一樣 -> 代表「換天了」
        if (lastDate != "" && lastDate != today) {

            saveToHistory(lastDate,dailySteps)
            // 【核心動作 A】結算昨天：將昨天的步數存入歷史 (第三階段會實作具體存檔)
            // 這裡我們暫時先印出 Log 方便測試
            println("偵測到換天！昨天的日期是 $lastDate，步數是 $dailySteps")

            // 【核心動作 B】重置今天：步數歸零
            dailySteps = 0
            saveData()
        }

        // 不管有沒有換天，都要更新「最後開啟日期」為今天
        prefs.edit().putString("last_date", today).apply()
    }

    private fun saveToHistory(date: String?, steps: Int) {
        val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)

        val historyString  = prefs.getString("history_list", "[]") ?: "[]"

        try {
            val jsonArray = JSONArray(historyString)

            val newRecord = JSONObject()
            newRecord.put("date", date)
            newRecord.put("steps", steps)

            jsonArray.put(newRecord)

            prefs.edit().putString("history_list", jsonArray.toString()).apply()

            Log.d("StepTracker", "歷史資料更新成功，目前有 ${jsonArray.length()}筆資料")
        } catch (e: Exception) {
            Log.e("StepTracker", "JSON 處理出錯: ${e.message}")
        }
    }

    private fun saveHistoryEntry(date: String, steps: Int) {
        val prefs = getSharedPreferences("FitnessData", Context.MODE_PRIVATE)

        // 1. 取得目前的歷史紀錄字串，若無則預設為空陣列 "[]"
        val historyString = prefs.getString("history_list", "[]") ?: "[]"

        try {
            val historyArray = JSONArray(historyString)

            // 2. 檢查是否已經有同日期的紀錄，如果有就覆蓋，沒有就新增
            var found = false
            for (i in 0 until historyArray.length()) {
                val item = historyArray.getJSONObject(i)
                if (item.getString("date") == date) {
                    item.put("steps", steps) // 找到同日期的，更新步數
                    found = true
                    break
                }
            }

            if (!found) {
                // 3. 建立新的紀錄物件並放入陣列
                val newEntry = JSONObject()
                newEntry.put("date", date)
                newEntry.put("steps", steps)
                historyArray.put(newEntry)
            }

            // 4. 將更新後的陣列轉回字串並存檔
            prefs.edit().putString("history_list", historyArray.toString()).apply()

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
