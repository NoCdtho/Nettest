# analyzer.py

alerts = {
    "status": "OK",
    "reasons": []
}

def reset():
    alerts["status"] = "OK"
    alerts["reasons"] = []

def set_alert(level, reason):
    if level == "DANGER":
        alerts["status"] = "DANGER"
    elif level == "WARNING" and alerts["status"] != "DANGER":
        alerts["status"] = "WARNING"

    alerts["reasons"].append(reason)

def analyze_packets(packets, gateway_ip):
    """
    packets: list of dicts from tshark
    """
    arp_map = {}

    for p in packets:
        if p["type"] == "ARP":
            ip = p["src_ip"]
            mac = p["src_mac"]

            if ip in arp_map and arp_map[ip] != mac:
                set_alert(
                    "DANGER",
                    f"ARP spoofing detected for {ip} ({arp_map[ip]} → {mac})"
                )
            arp_map[ip] = mac

    if gateway_ip in arp_map:
        pass
    else:
        set_alert("WARNING", "Gateway ARP responses not observed")

    if not alerts["reasons"]:
        alerts["status"] = "OK"
        alerts["reasons"] = ["No MITM indicators detected"]
