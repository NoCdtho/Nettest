package com.example.networktest

import android.util.Log
import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "network_tools"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "network_tools"
        ).setMethodCallHandler { call, result ->

            when (call.method) {

               /* ---------------- Wi-Fi Connected ---------------- */
            "isWifiConnected" -> {
                Log.d("NET_TEST", "isWifiConnected called")

                val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

                val network = cm.activeNetwork
                if (network == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }

                val caps = cm.getNetworkCapabilities(network)
                val isWifi = caps != null &&
                    caps.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI)

                result.success(isWifi)

                // val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                // val network = cm.activeNetwork

                // // if (network == null) {
                // //     result.success(false)
                // //     return@setMethodCallHandler
                // // }

                // val capabilities = cm.getNetworkCapabilities(network)
                // val isWifi = capabilities?.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) == true

                // result.success(isWifi)
            }


                /* ---------------- Wi-Fi RSSI ---------------- */
                "getWifiRssi" -> {
                    val wifiManager =
                        applicationContext.getSystemService(Context.WIFI_SERVICE)
                                as WifiManager

                    result.success(wifiManager.connectionInfo.rssi)
                }

                /* ---------------- Ping Test ---------------- */
                "pingTest" -> {
                    Thread {
                        try {
                            val host = call.argument<String>("host") ?: "8.8.8.8"
                            val count = call.argument<Int>("count") ?: 10
                            var lost = 0

                            repeat(count) {
                                val process = Runtime.getRuntime().exec(
                                    arrayOf(
                                        "/system/bin/ping",
                                        "-c", "1",
                                        "-W", "1",
                                        host
                                    )
                                )
                                if (process.waitFor() != 0) lost++
                            }

                            val lossPercentage = (lost * 100) / count

                            runOnUiThread {
                                result.success(lossPercentage)
                            }

                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "PING_ERROR",
                                    e.message,
                                    null
                                )
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }
}
