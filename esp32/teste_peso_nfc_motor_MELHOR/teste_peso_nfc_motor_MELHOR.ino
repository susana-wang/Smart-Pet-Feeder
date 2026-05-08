#include <Wire.h>
#include <WiFi.h>
#include <Adafruit_PN532.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>
#include <HX711.h>

// -------------------- CONFIGURAÇÕES --------------------
#define WIFI_SSID "Linda"
#define WIFI_PASSWORD "linda7166"

#define API_KEY "AIzaSyDjgrPcPVZgANfTrjXYZIfZh6Uj_rxixyg"
#define DATABASE_URL "https://ondeestaoscar-default-rtdb.europe-west1.firebasedatabase.app/"

// Pins PN532 (I2C)
#define SDA_PIN 21
#define SCL_PIN 22
Adafruit_PN532 nfc(SDA_PIN, SCL_PIN);

// Pins HX711 (Balança)
const uint8_t DOUT_PIN = 16;
const uint8_t SCK_PIN = 4;
HX711 scale;
float calibration_factor = 717.056;

// Pin Servo
#define SERVO_PIN 18
Servo servoMotor;

// Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);

  // 1. WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("A ligar ao WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWiFi ligado!");

  // 2. Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // 3. PN532
  nfc.begin();
  uint32_t version = nfc.getFirmwareVersion();
  if (!version) {
    Serial.println("PN532 não encontrado!");
    while (1);
  }
  nfc.SAMConfig();

  // 4. HX711
  scale.begin(DOUT_PIN, SCK_PIN);
  scale.set_scale(calibration_factor);
  Serial.println("A calibrar balança (Tare)...");
  scale.tare(20); 

  // 5. Servo
  servoMotor.attach(SERVO_PIN);
  servoMotor.write(0);

  Serial.println("Sistema pronto! À espera de NFC...");
}

void loop() {
  uint8_t uid[] = { 0, 0, 0, 0, 0, 0, 0 };
  uint8_t uidLength;

  // O código para aqui até detetar uma tag
  bool success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength, 500);

  if (success) {
    Serial.println("Tag detetada!");
    
    // --- 1. Formatar UID ---
    String uidString = "";
    for (uint8_t i = 0; i < uidLength; i++) {
      if (uid[i] < 0x10) uidString += "0";
      uidString += String(uid[i], HEX);
      if (i < uidLength - 1) uidString += ":";
    }
    uidString.toUpperCase();

    // --- 2. Movimentar Servo ---
    Serial.println("Movendo servo...");
    servoMotor.write(90);
    delay(1000); // Tempo para o motor abrir
    servoMotor.write(0);

    // --- 3. Esperar 2 segundos e Ler Peso ---
    Serial.println("A aguardar 2 segundos para pesagem...");
    delay(2000);
    
    float peso = 0;
    if (scale.is_ready()) {
      // Faz a média de 10 leituras e subtrai os 12g de offset como tinhas no código
      peso = scale.get_units(10) - 12; 
      Serial.printf("Peso lido: %.2f g\n", peso);
    }

    // --- 4. Enviar para Firebase ---
    // Criamos um nó único com o timestamp para não apagar os anteriores
    String timestamp = String(millis());
    String path = "/registos/" + timestamp;

    FirebaseJson json;
    json.add("uid", uidString);
    json.add("peso_g", peso);
    json.add("timestamp", timestamp);

    if (Firebase.RTDB.setJSON(&fbdo, path, &json)) {
      Serial.println("Dados enviados com sucesso!");
    } else {
      Serial.println("Erro ao enviar: " + fbdo.errorReason());
    }

    Serial.println("\nPronto para nova leitura...");
    delay(1000); // Pequena pausa de segurança
  }
}