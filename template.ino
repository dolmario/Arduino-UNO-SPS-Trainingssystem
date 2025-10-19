// Auto-generiert aus LOGO! Projekt: {PROJECT_NAME}
// Datum: {TIMESTAMP}
// Hardware-Profil: Standard UNO + 4-Relais + MOSFET

#include <OneWire.h>
#include <DallasTemperature.h>

// ============================================
// PIN DEFINITIONS (aus hardware_profile.yaml)
// ============================================
#define I1 9
#define I2 10
#define I3 16  // A2
#define I4 17  // A3

#define Q1 2
#define Q2 4
#define Q3 5
#define Q4 7

#define AO1_PWM 3
#define AO2_PWM 6

#define AI1 A0
#define AI2 A1

#define TEMP_PIN 12
#define BUZZER 8
#define LED_STATUS 13

// Flags
#define RELAYS_ACTIVE_LOW true
#define MOSFET_ACTIVE_LOW false

// ============================================
// SENSOR SETUP
// ============================================
OneWire oneWire(TEMP_PIN);
DallasTemperature sensors(&oneWire);

// ============================================
// LOGO! VARIABLES (generiert)
// ============================================
{GENERATED_VARIABLES}

// ============================================
// TIMER STRUCTURES
// ============================================
{GENERATED_TIMERS}

// ============================================
// SETUP
// ============================================
void setup() {
  // Digital Inputs
  pinMode(I1, INPUT_PULLUP);
  pinMode(I2, INPUT_PULLUP);
  pinMode(I3, INPUT);
  pinMode(I4, INPUT);
  
  // Relais Outputs
  pinMode(Q1, OUTPUT);
  pinMode(Q2, OUTPUT);
  pinMode(Q3, OUTPUT);
  pinMode(Q4, OUTPUT);
  
  // PWM Outputs
  pinMode(AO1_PWM, OUTPUT);
  pinMode(AO2_PWM, OUTPUT);
  
  // Status
  pinMode(BUZZER, OUTPUT);
  pinMode(LED_STATUS, OUTPUT);
  
  // Init States
  {GENERATED_INIT}
  
  // Temperature Sensor
  sensors.begin();
  
  // Optional: Serial für Debug
  // Serial.begin(9600);
}

// ============================================
// MAIN LOOP
// ============================================
void loop() {
  // Read Inputs
  {GENERATED_READ_INPUTS}
  
  // LOGO! Logic (übersetzt aus FUP)
  {GENERATED_LOGIC}
  
  // Write Outputs
  {GENERATED_WRITE_OUTPUTS}
  
  // Cycle Time
  delay(50);  // 20 Hz = typisch für LOGO!
}

// ============================================
// HELPER FUNCTIONS
// ============================================
{GENERATED_FUNCTIONS}
