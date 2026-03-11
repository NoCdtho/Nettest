package com.example.networktest

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "network_tools"
    private val EVENT_CHANNEL = "network_tools/stream"
    private val LOCATION_PERMISSION_REQUEST = 100
    
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
                        val frequency = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
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

                /* ---------------- Scan WiFi Networks (COMPREHENSIVE FIX) ---------------- */
                "scanWifiNetworks" -> {
                    Log.d("NET_TEST", "=== SCAN WIFI NETWORKS CALLED ===")

                    // Step 1: Check if WiFi is enabled
                    if (wifiManager?.isWifiEnabled == false) {
                        Log.e("NET_TEST", "WiFi is disabled")
                        result.error("WIFI_DISABLED", "WiFi is turned off", null)
                        return@setMethodCallHandler
                    }
                    Log.d("NET_TEST", "WiFi is enabled")

                    // Step 2: Check location permission
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val hasPermission = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACCESS_FINE_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED

                        Log.d("NET_TEST", "Location permission: $hasPermission")

                        if (!hasPermission) {
                            Log.e("NET_TEST", "Location permission not granted")
                            result.error(
                                "PERMISSION_DENIED",
                                "Location permission is required for WiFi scanning",
                                null
                            )
                            return@setMethodCallHandler
                        }
                    }

                    // Step 3: Get cached scan results first
                    Log.d("NET_TEST", "Getting cached scan results...")
                    try {
                        val cachedResults = wifiManager?.scanResults
                        Log.d("NET_TEST", "Cached results count: ${cachedResults?.size ?: 0}")
                        
                        if (cachedResults != null) {
                            cachedResults.forEach { scanResult ->
                                Log.d("NET_TEST", "Cached: ${scanResult.SSID} - ${scanResult.level} dBm")
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("NET_TEST", "Error reading cached results: ${e.message}")
                    }

                    // Step 4: Trigger new scan and wait
                    Log.d("NET_TEST", "Starting new scan...")
                    try {
                        val scanStarted = wifiManager?.startScan() ?: false
                        Log.d("NET_TEST", "Scan triggered: $scanStarted")

                        // Wait for scan to complete
                        Thread {
                            try {
                                Log.d("NET_TEST", "Waiting 4 seconds for scan completion...")
                                Thread.sleep(4000)
                                
                                runOnUiThread {
                                    try {
                                        val scanResults = wifiManager?.scanResults
                                        Log.d("NET_TEST", "Final scan results count: ${scanResults?.size ?: 0}")

                                        if (scanResults == null || scanResults.isEmpty()) {
                                            Log.w("NET_TEST", "No networks found after scan")
                                            result.success(emptyList<Map<String, Any>>())
                                            return@runOnUiThread
                                        }

                                        val networks = scanResults.map { scanResult ->
                                            val ssid = if (scanResult.SSID.isNullOrEmpty()) "Hidden Network" else scanResult.SSID
                                            Log.d("NET_TEST", "Network: $ssid, Level: ${scanResult.level}, Freq: ${scanResult.frequency}")
                                            
                                            mapOf(
                                                "ssid" to ssid,
                                                "bssid" to scanResult.BSSID,
                                                "level" to scanResult.level,
                                                "frequency" to scanResult.frequency,
                                                "capabilities" to scanResult.capabilities
                                            )
                                        }
                                        
                                        Log.d("NET_TEST", "Returning ${networks.size} networks to Flutter")
                                        result.success(networks)
                                        
                                    } catch (e: SecurityException) {
                                        Log.e("NET_TEST", "SecurityException getting scan results: ${e.message}")
                                        result.error("PERMISSION_ERROR", "Permission denied: ${e.message}", null)
                                    } catch (e: Exception) {
                                        Log.e("NET_TEST", "Error getting scan results: ${e.message}")
                                        e.printStackTrace()
                                        result.error("SCAN_ERROR", e.message, null)
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e("NET_TEST", "Thread error: ${e.message}")
                                runOnUiThread {
                                    result.error("SCAN_ERROR", e.message, null)
                                }
                            }
                        }.start()

                    } catch (e: Exception) {
                        Log.e("NET_TEST", "Scan exception: ${e.message}")
                        e.printStackTrace()
                        result.error("SCAN_ERROR", e.message, null)
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