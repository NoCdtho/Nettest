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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method != "pingTest") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                Thread {
                    try {
                        val host = call.argument<String>("host") ?: "8.8.8.8"
                        val count = call.argument<Int>("count") ?: 10
                        var lost = 0

                        repeat(count) {
                            val process = Runtime.getRuntime().exec(
                                arrayOf("/system/bin/ping", "-c", "1", "-W", "1", host)
                            )
                            if (process.waitFor() != 0) lost++
                        }

                        val loss = (lost * 100) / count

                        runOnUiThread {
                            result.success(loss)
                        }

                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("PING_ERROR", e.message, null)
                        }
                    }
                }.start()
            }
    }
}
