#include <Arduino.h>
#include <string.h>

#define serialBaudRate << SERIAL_BAUD_RATE >> // TODO: Rename, this is not a port, it's a baud rate

<< RECORDS >>

void setup() {
    Serial.begin(serialBaudRate);
}

void loop() {
    int timeStart = millis();

    int timeElapsed = millis() - timeStart;
}
