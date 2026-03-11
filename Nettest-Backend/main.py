from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import netifaces
import analyzer
import tshark_collector

app = FastAPI(title="NetTest MITM Scanner")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

TSHARK_INTERFACE = 4  # auto-detected inside collector

def get_default_gateway():
    """Helper to find the gateway IP automatically."""
    try:
        gws = netifaces.gateways()
        # Returns the IP of the default gateway for IPv4
        return gws['default'][netifaces.AF_INET][0]
    except Exception:
        return None

@app.get("/")
def health():
    return {"status": "online"}


@app.get("/alerts/scan-network")
def scan_network(
    device_ip: str = Query(...),
    ssid: str | None = None,
    bssid: str | None = None,
):
    gateway_ip = get_default_gateway()
    if not gateway_ip:
        raise HTTPException(status_code=400, detail="Gateway IP required")

    analyzer.reset()

    try:
        packets = tshark_collector.capture_packets(
            interface_index=TSHARK_INTERFACE,
            duration=10
        )
    except Exception as e:
        return {
            "status": "ERROR",
            "reasons": ["Packet capture failed"],
        }

    analyzer.analyze_packets(packets, gateway_ip)

    return {
        "status": analyzer.alerts["status"],
        "reasons": analyzer.alerts["reasons"],
        "device_ip": device_ip,
       "detector_gateway_ip": gateway_ip,
        "ssid": ssid,
        "bssid": bssid,
    }
