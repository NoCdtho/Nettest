package com.example.networktest

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "network_tools"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "pingTest") {
                val host = call.argument<String>("host") ?: "8.8.8.8"
                val count = call.argument<Int>("count") ?: 10

                try {
                    val process = Runtime.getRuntime().exec(
                        arrayOf("ping", "-c", count.toString(), host)
                    )

                    val output = process.inputStream.bufferedReader().readText()
                    process.waitFor()

                    val regex = Regex("(\\d+)% packet loss")
                    val match = regex.find(output)

                    val packetLoss =
                        match?.groupValues?.get(1)?.toInt() ?: -1

                    result.success(packetLoss)

                } catch (e: Exception) {
                    result.error("PING_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
