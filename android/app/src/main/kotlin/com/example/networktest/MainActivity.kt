class MainActivity : FlutterActivity() {

    private val CHANNEL = "wifi_signal_channel"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getWifiSignalStrength") {
                try {
                    val wifiManager =
                        applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

                    val wifiInfo = wifiManager.connectionInfo
                    if(wifiInfo == null || wifiInfo.ssid == "<unknown ssid>"){
                        result.error("NO_WIFI", "Not connected to wi-fi", null)
                        return@setMethodCallHandler
                    }
                    val rssi = wifiInfo?.rssi ?: -100
                    val ssid = wifiInfo?.ssid ?: "Unknown"

                    val response = HashMap<String, Any>()
                    response["rssi"] = rssi
                    response["ssid"] = ssid.replace("\"", "")

                    result.success(response)
                } catch (e: Exception) {
                    result.error("WIFI_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }
}
