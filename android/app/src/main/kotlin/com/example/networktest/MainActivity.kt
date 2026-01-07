package com.example.networktest

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {

    private val CHANNEL = "network_tools"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // "getWifiSignalStrength" -> {
                //     try {
                //         val wifiManager =
                //             applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

                //         val wifiInfo = wifiManager.connectionInfo
                //         if (wifiInfo == null || wifiInfo.ssid == "<unknown ssid>") {
                //             result.error("NO_WIFI", "Not connected to Wi-Fi", null)
                //             return@setMethodCallHandler
                //         }

                //         result.success(
                //             mapOf(
                //                 "rssi" to wifiInfo.rssi,
                //                 "ssid" to wifiInfo.ssid.replace("\"", "")
                //             )
                //         )
                //     } catch (e: Exception) {
                //         result.error("WIFI_ERROR", e.message, null)
                //     }
                // }

                "pingTest" -> {
                    val host = call.argument<String>("host") ?: "8.8.8.8"
                    val count = call.argument<Int>("count") ?: 10

                    try {
                        val process =
                            Runtime.getRuntime().exec("/system/bin/ping -c $count $host")

                        val reader =
                            BufferedReader(InputStreamReader(process.inputStream))

                        var received = 0
                        while (reader.readLine() != null) {
                            received++
                        }

                        val lossPercent =
                            ((count - received) * 100) / count

                        result.success(lossPercent)

                    } catch (e: Exception) {
                        result.error("PING_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
