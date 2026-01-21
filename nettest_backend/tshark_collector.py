# tshark_collector.py
import subprocess
import json
import tempfile

def capture_packets(interface_index, duration=20):
    """
    Captures ARP packets for `duration` seconds
    """
    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as f:
        output = f.name

    cmd = [
        "tshark",
        "-i", str(interface_index),
        "-a", f"duration:{duration}",
        "-T", "json",
        "arp"
    ]

    subprocess.run(cmd, stdout=open(output, "w"), stderr=subprocess.DEVNULL)

    packets = []
    with open(output, "r", encoding="utf-8") as fh:
        data = json.load(fh)

        for pkt in data:
            layers = pkt["_source"]["layers"]
            if "arp" in layers:
                arp = layers["arp"]
                packets.append({
                    "type": "ARP",
                    "src_ip": arp.get("arp.src.proto_ipv4"),
                    "src_mac": arp.get("arp.src.hw_mac")
                })

    return packets
