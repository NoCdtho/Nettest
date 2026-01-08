# ns2

features
This code creates one Flutter screen called NetworkStrengthPage that:
Checks whether Wi-Fi is connected
If connected:
Reads real Wi-Fi RSSI (signal strength in dBm) from Android
Converts RSSI → percentage (0–100%)
Measures real internet latency (ping) using an HTTP request
Classifies network quality as Excellent / Good / Fair / Poor
If NOT connected:
Clearly tells the user “You are not connected to Wi-Fi”
Does NOT show fake values
