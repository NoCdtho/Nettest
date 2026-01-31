# Nettest

Nettest is a mobile + backend tool for detecting MITM (man-in-the-middle) or other suspicious network activity between a mobile device and a monitored network. The repo contains a Flutter front-end (mobile app) and a Python backend that analyzes traffic via tshark/tcpdump interfaces.

Note: everything is updated on the main branch.

## Features
- Local backend server (FastAPI/uvicorn) for traffic analysis
- Mobile Flutter app to display network/security status
- Uses tshark interface for packet capture/analysis
- Detects potential MITM or malicious network behavior

## Requirements
- Python 3.8+ (for backend)
- tshark (Wireshark/TShark) installed on the host machine
- Flutter SDK (for the mobile app)
- A device (mobile) connected via USB with developer/debugging enabled, or use an emulator
- Laptop and mobile must be on the same network when testing local backend

## Backend Setup (nettest_backend)
1. Open a terminal and go to the backend folder:
   - Path: netTesting/Nettest/nettest_backend
2. Create and activate a virtual environment:
   - Windows:
     - python -m venv venv
     - venv\Scripts\activate
   - macOS / Linux:
     - python3 -m venv venv
     - source venv/bin/activate
3. Install dependencies (if requirements.txt exists):
   - pip install -r requirements.txt
4. Run the backend with uvicorn:
   - python -m uvicorn main:app --host 0.0.0.0 --port 8000

The backend will be available at http://0.0.0.0:8000 (or http://<your-laptop-ip>:8000 on the LAN).

## Important Configuration Steps
- When running the backend locally, your laptop will have a local IP on the LAN. Update that IP in the Flutter app so the mobile can reach the backend:
  - File: secure_network_page.dart
  - Update the backend/base URL or IP to your laptop's LAN IP (for example: http://192.168.1.12:8000).
- Configure the tshark/tap interface used by the backend:
  - File: nettest_backend/main.py
  - Update the capture interface index or name used by the tshark integration to match the interface your laptop uses to connect to the network.

To list available tshark interfaces, run:
- tshark -D
(This lists interfaces like 1: Wi‑Fi, 2: Ethernet, etc. Use the appropriate index or the interface name in main.py.)

## Frontend (Flutter) — Run on Device
1. From the Flutter project root:
   - flutter clean (optional)
   - flutter pub get
   - flutter build (optional)
2. Connect your phone via USB and enable USB debugging.
3. Run the app:
   - flutter run

Ensure the mobile device is on the same Wi‑Fi network as your laptop/backend.

## How to Test MITM Detection
1. Start the backend locally.
2. Make sure the backend IP is set in secure_network_page.dart and that the tshark interface is set in nettest_backend/main.py.
3. Connect your phone to the same network and run the Flutter app.
4. Use the app’s secure network/scan features to start traffic capture and detection. The backend will analyze captures and report suspicious activity to the app.

## Troubleshooting
- Backend unreachable from mobile:
  - Verify laptop and mobile are on the same network.
  - Confirm correct LAN IP and port (8000) are set in secure_network_page.dart.
  - Check firewall settings on the laptop allowing inbound connections to port 8000.
- tshark cannot capture:
  - Ensure tshark is installed and has permission to capture (may need admin/root).
  - Run tshark -D to find the correct interface, then update main.py accordingly.
- Virtual environment problems:
  - Make sure you used the correct Python executable for creating the venv (python vs python3).
  - Activate the venv before installing dependencies or running uvicorn.

## Contributing
- Fork the repo, create a feature branch, and open a pull request.
- Please include clear instructions for any new dependencies or configuration changes.
