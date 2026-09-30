/****************************************************
 * MAX30105 + ESP8266 + OLED
 * Continuous HR + SpO2 Display
 * WiFi + Firebase Realtime Database Upload
 *
 * Scanning/algorithm logic is UNCHANGED from the
 * original SparkFun/MySQL version. Only sendData()
 * and its supporting setup (WiFiClientSecure, NTP,
 * Firebase constants) were swapped in, following the
 * same pattern as the MAX30100 Firebase sketch.
 ****************************************************/

#include <Wire.h>

#include "MAX30105.h"
#include "spo2_algorithm.h"

#include <SSD1306Ascii.h>
#include <SSD1306AsciiWire.h>

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <time.h>

// =====================================================
// WiFi SETTINGS
// =====================================================

const char* ssid = "PLDTHOMEFIBR2e4a8";
const char* password = "PLDTWIFIqhaj9";

// =====================================================
// FIREBASE SETTINGS
// =====================================================
// REST write target: https://<HOST>/<PATH>.json
// If your database rules are not public/test mode, append
// "?auth=<DATABASE_SECRET_OR_ID_TOKEN>" to FIREBASE_PATH below.
const char* FIREBASE_HOST = "vitalert-app-default-rtdb.asia-southeast1.firebasedatabase.app";
const char* FIREBASE_PATH = "/devices/device3.json?auth=EYsZ9e454gtJ5QF4wPROvAmCEKzSANGNiryI05zT";
const char* DEVICE_ID     = "device3";

// TLS handshake alone can cost 1-3s on an ESP8266, so this is sized
// up from the old plain-HTTP timeout (was 2000ms for MySQL GET).
#define HTTP_TIMEOUT_MS 5000

const unsigned long UPLOAD_INTERVAL = 2000;   // 2 seconds (unchanged)

unsigned long lastUpload = 0;
unsigned long lastWaitingUpload = 0;        // Throttle for no-pulse Waiting pings
const unsigned long WAITING_UPLOAD_INTERVAL = 5000; // 5s cadence when no finger present

// =====================================================
// SENSOR + OLED
// =====================================================

MAX30105 particleSensor;
SSD1306AsciiWire oled;

// Maxim Algorithm Buffers
uint32_t irBuffer[100];
uint32_t redBuffer[100];

// Algorithm Outputs
int32_t spo2;
int8_t validSPO2;

int32_t heartRate;
int8_t validHeartRate;

bool fingerPresent = false;

// =====================================================
// OLED FUNCTIONS
// =====================================================

void showPlaceFinger()
{
  oled.clear();
  oled.setCursor(0, 2);
  oled.println("Place Finger");
  oled.setCursor(0, 4);
  oled.println("on Sensor");
}

void showVitals(int hr, int oxygen)
{
  oled.clear();

  oled.setCursor(0,0);
  oled.println("Heart Rate");

  oled.setCursor(0,2);
  if(hr > 0){
    oled.print(hr);
    oled.println(" BPM");
  } else {
    oled.println("-- BPM");
  }

  oled.setCursor(0,5);
  oled.println("SpO2");

  oled.setCursor(0,7);
  if(oxygen > 0){
    oled.print(oxygen);
    oled.println(" %");
  } else {
    oled.println("-- %");
  }
}

// =====================================================
// TIMESTAMP (NTP)
// =====================================================
// Firebase's last_updated field expects a human-readable timestamp.
// Reads back whatever configTime() in setup() synced from NTP.
// Returns "unsynced" if that sync hasn't completed yet.
String getTimestamp() {
  time_t now = time(nullptr);
  if (now < 100000) {
    return "unsynced";
  }
  struct tm timeinfo;
  localtime_r(&now, &timeinfo);
  char buf[20];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buf);
}

// =====================================================
// FIREBASE SEND FUNCTION
// =====================================================
// Static client/http so the TLS connection is reused across uploads
// instead of paying the 1-3s handshake every time.
void sendData(int hr, int oxygen, String status)
{
  if(WiFi.status() != WL_CONNECTED)
  {
    Serial.println("WiFi disconnected.");
    return;
  }

  static WiFiClientSecure client;
  static bool clientConfigured = false;
  if (!clientConfigured) {
    // NOTE: skips certificate validation. Fine for a prototype -
    // revisit before this carries real patient data.
    client.setInsecure();
    clientConfigured = true;
  }

  static HTTPClient http;

  client.setTimeout(HTTP_TIMEOUT_MS);

  String url = "https://" + String(FIREBASE_HOST) + String(FIREBASE_PATH);

  String payload = "{";
  payload += "\"bpm\":" + String(hr) + ",";
  payload += "\"spo2\":" + String(oxygen) + ",";
  payload += "\"device_id\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"status\":\"" + status + "\",";
  payload += "\"last_updated\":\"" + getTimestamp() + "\"";
  payload += "}";

  Serial.println();
  Serial.println("===== FIREBASE UPLOAD =====");
  Serial.println(url);
  Serial.println(payload);

  if (!http.begin(client, url)) {
    Serial.println("http.begin() failed");
    return;
  }

  http.setTimeout(HTTP_TIMEOUT_MS);
  http.addHeader("Content-Type", "application/json");

  int httpCode = http.sendRequest("PATCH", payload);

  // Retry once on failure. A reused connection can be closed by the
  // server between uploads; an immediate second attempt on a fresh
  // connection normally succeeds.
  if (httpCode <= 0) {
    Serial.print("First attempt failed (");
    Serial.print(http.errorToString(httpCode));
    Serial.println("), retrying once...");

    http.end();

    if (http.begin(client, url)) {
      http.setTimeout(HTTP_TIMEOUT_MS);
      http.addHeader("Content-Type", "application/json");
      httpCode = http.sendRequest("PATCH", payload);
    }
  }

  Serial.print("HTTP Code: ");
  Serial.println(httpCode);

  if(httpCode > 0)
  {
    Serial.print("Server Response: ");
    Serial.println(http.getString());
  }
  else
  {
    Serial.print("HTTP Error: ");
    Serial.println(http.errorToString(httpCode));
  }

  http.end();

  Serial.print("Free heap: ");
  Serial.println(ESP.getFreeHeap());

  Serial.println("============================");
}

// =====================================================
// SETUP
// =====================================================

void setup()
{
  Serial.begin(115200);
  delay(1000);

  // ESP8266 I2C
  Wire.begin(4,5);

  // OLED
  oled.begin(&Adafruit128x64,0x3C);
  oled.setFont(System5x7);

  oled.clear();
  oled.println("Initializing...");

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  Serial.print("Connecting to WiFi");

  while(WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi Connected!");
  Serial.print("ESP8266 IP: ");
  Serial.println(WiFi.localIP());

  // Sync time for the last_updated field. Philippines = UTC+8, no DST.
  configTime(8 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Syncing time");
  time_t now = time(nullptr);
  uint32_t ntpStart = millis();
  while (now < 100000 && millis() - ntpStart < 10000) {
    delay(300);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println();

  // MAX30102
  Serial.println("Initializing MAX30102...");

  if(!particleSensor.begin(Wire, I2C_SPEED_STANDARD))
  {
    Serial.println("MAX30102 NOT FOUND!");

    oled.clear();
    oled.println("MAX30102");
    oled.println("NOT FOUND!");

    while(true);
  }

  Serial.println("MAX30102 Ready.");

  particleSensor.setup();
  particleSensor.setPulseAmplitudeGreen(0);

  showPlaceFinger();
}

// =====================================================
// LOOP
// =====================================================

void loop()
{
  long irValue = particleSensor.getIR();

  // -------------------------
  // No Finger
  // -------------------------
  if(irValue < 50000)
  {
    if(fingerPresent)
    {
      fingerPresent = false;
      showPlaceFinger();
    }

    // No finger - throttled Waiting ping every 5s so Firebase stays current
    if(millis() - lastWaitingUpload >= WAITING_UPLOAD_INTERVAL)
    {
      sendData(0, 0, "Waiting");
      lastWaitingUpload = millis();
    }

    delay(50);
    return;
  }

  // -------------------------
  // Finger Detected
  // -------------------------
  if(!fingerPresent)
  {
    fingerPresent = true;
    showVitals(0,0);
  }

  // -------------------------
  // Collect Samples
  // -------------------------
  for(byte i = 0; i < 100; i++)
  {
    while(!particleSensor.available())
    {
      particleSensor.check();
    }

    redBuffer[i] = particleSensor.getRed();
    irBuffer[i] = particleSensor.getIR();

    particleSensor.nextSample();
  }

  // -------------------------
  // Calculate HR & SpO2
  // -------------------------
  maxim_heart_rate_and_oxygen_saturation(
      irBuffer,
      100,
      redBuffer,
      &spo2,
      &validSPO2,
      &heartRate,
      &validHeartRate
  );

  // -------------------------
  // Validation
  // -------------------------
  int displayHR = 0;
  int displaySpO2 = 0;

  if(validHeartRate && heartRate >= 40 && heartRate <= 120)
    displayHR = heartRate;

  if(validSPO2 && spo2 >= 70 && spo2 <= 100)
    displaySpO2 = spo2;

  // -------------------------
  // Serial Monitor
  // -------------------------
  Serial.print("IR: ");
  Serial.print(irValue);

  Serial.print(" | HR: ");
  Serial.print(displayHR);

  Serial.print(" | SpO2: ");
  Serial.println(displaySpO2);

  // -------------------------
  // OLED
  // -------------------------
  showVitals(displayHR, displaySpO2);

  // -------------------------
  // Upload to Firebase every 2 sec
  // -------------------------
  if(millis() - lastUpload >= UPLOAD_INTERVAL)
  {
    if(displayHR > 0 && displaySpO2 > 0)
    {
      // Valid pulse locked - upload live vitals
      sendData(displayHR, displaySpO2, "Ongoing");
    }
    else
    {
      // Finger on sensor but algorithm hasn't locked a valid pulse yet
      sendData(0, 0, "Waiting");
    }
    lastUpload = millis();
  }

  delay(200);
}
