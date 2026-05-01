#include <HX711.h>

HX711 scale;
uint8_t dataPin = 02;
uint8_t clockPin = 04;
float_t factor = 717.056;

void setup() {
    Serial.begin(115200);
    delay(1000);  // Give time for serial and sensor to settle

    scale.begin(dataPin, clockPin);
    scale.set_scale(factor);

    // Wait until the scale is ready
    while (!scale.is_ready()) {
        Serial.println("Waiting for HX711...");
        delay(100);
    }

    Serial.println("Taring...");
    scale.tare(20);  // Automatically set the current weight to zero
    Serial.println("Tare complete.");
}

void loop() {
    delay(100);

    if (scale.is_ready()) {
        float avg_units = scale.get_units(10)-12; // Average over 10 samples
        Serial.printf("%f g.\n", avg_units);
    }
}