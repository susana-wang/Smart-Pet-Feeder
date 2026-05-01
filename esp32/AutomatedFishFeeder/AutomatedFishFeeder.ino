/*
 * This ESP32 code is created by esp32io.com
 *
 * This ESP32 code is released in the public domain
 *
 * For more detail (instruction and wiring diagram), visit https://esp32io.com/tutorials/esp32-servo-motor
 */

#include <ESP32Servo.h>

#define SERVO_PIN 18 // ESP32 pin GPIO26 connected to servo motor

Servo servoMotor;

void setup() {
  servoMotor.attach(SERVO_PIN);  // attaches the servo on ESP32 pin
}

void loop() {
  for (int pos = 0; pos <= 360; pos += 60) {
    servoMotor.write(pos);
    delay(2);
  }

  for (int pos = 360; pos >= 0; pos -= 60) {
    servoMotor.write(pos);
    delay(2);
  }
}
