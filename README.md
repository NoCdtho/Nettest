Note:--- Everything is updated in main branch 

To check the mitm detection have to run the backend server locally
  1)go to the this folder: "\netTesting\Nettest\nettest_backend"
  2)activate venv:
  3)python -m venv venv
  4) venv\Scripts\activate
  5)python -m uvicorn main:app --host 0.0.0.0 --port 8000
  6)The most important part is:-- To check the malicious activity the laptop and the mobile have to be connected in the same network and when the backend is hosted locally a new ip is assigned to the laptop which should be 
  updated in the secure_network_page.dart and lastly the shark interface should be updated in the nettest_backend/main.py.
  7)To check the tshark interface number, type: tshark -d in terminal identify the type of network the laptop is connected and the number in the main.py
  
rest of them all are working perfectly if you just run the app.

just do:
1)flutter run(by connecting your phone and enabling usb debugging)


