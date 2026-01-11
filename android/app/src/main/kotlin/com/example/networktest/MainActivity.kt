package com.example.networktest

import android.util.Log
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "network_tools"
    private val EVENT_CHANNEL = "network_tools/stream"
    
    private var wifiManager: WifiManager? = null
    private var wifiReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        // Method Channel for one-time calls
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
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
                }

                /* ---------------- Wi-Fi RSSI ---------------- */
                "getWifiRssi" -> {
                    val rssi = wifiManager?.connectionInfo?.rssi ?: -100
                    result.success(rssi)
                }

                /* ---------------- Get Current WiFi Info ---------------- */
                "getCurrentWifiInfo" -> {
                    val wifiInfo = wifiManager?.connectionInfo
                    if (wifiInfo != null) {
                        val ssid = wifiInfo.ssid.replace("\"", "")
                        val bssid = wifiInfo.bssid ?: "Unknown"
                        val rssi = wifiInfo.rssi
                        val linkSpeed = wifiInfo.linkSpeed
                        val frequency = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                            wifiInfo.frequency
                        } else {
                            0
                        }
                        val ipAddress = wifiInfo.ipAddress
                        val ipString = String.format(
                            "%d.%d.%d.%d",
                            ipAddress and 0xff,
                            ipAddress shr 8 and 0xff,
                            ipAddress shr 16 and 0xff,
                            ipAddress shr 24 and 0xff
                        )

                        val data = mapOf(
                            "ssid" to ssid,
                            "bssid" to bssid,
                            "rssi" to rssi,
                            "linkSpeed" to linkSpeed,
                            "frequency" to frequency,
                            "ipAddress" to ipString
                        )
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }

                /* ---------------- Scan WiFi Networks ---------------- */
                "scanWifiNetworks" -> {
                    val success = wifiManager?.startScan() ?: false
                    if (success) {
                        // Wait a bit for scan to complete
                        Thread {
                            Thread.sleep(2000)
                            val scanResults = wifiManager?.scanResults ?: emptyList()
                            val networks = scanResults.map { scanResult ->
                                mapOf(
                                    "ssid" to scanResult.SSID,
                                    "bssid" to scanResult.BSSID,
                                    "level" to scanResult.level,
                                    "frequency" to scanResult.frequency,
                                    "capabilities" to scanResult.capabilities
                                )
                            }
                            runOnUiThread {
                                result.success(networks)
                            }
                        }.start()
                    } else {
                        result.success(emptyList<Map<String, Any>>())
                    }
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

        // Event Channel for continuous WiFi strength streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("NET_TEST", "Started WiFi monitoring stream")
                    
                    wifiReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val rssi = wifiManager?.connectionInfo?.rssi ?: -100
                            events?.success(rssi)
                            Log.d("NET_TEST", "RSSI update: $rssi")
                        }
                    }
                    
                    val filter = IntentFilter().apply {
                        addAction(WifiManager.RSSI_CHANGED_ACTION)
                        addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION)
                    }
                    
                    registerReceiver(wifiReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("NET_TEST", "Stopped WiFi monitoring stream")
                    wifiReceiver?.let {
                        unregisterReceiver(it)
                    }
                    wifiReceiver = null
                }
            })
    }

    override fun onDestroy() {
        wifiReceiver?.let {
            unregisterReceiver(it)
        }
        super.onDestroy()
    }
}