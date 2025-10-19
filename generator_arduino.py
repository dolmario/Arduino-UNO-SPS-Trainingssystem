#!/usr/bin/env python3
"""
Arduino Sketch Generator
Übersetzt geparste LOGO! Blöcke in Arduino C++ Code
"""

import sys
from datetime import datetime
from pathlib import Path
from parser_logo import parse_logo_csv, get_all_variables, load_hardware_profile

class ArduinoGenerator:
    def __init__(self, hardware_profile):
        self.hw = hardware_profile
        self.timers = []
        self.counters = []
        self.flipflops = []
    
    def parse_time_param(self, param):
        """
        Konvertiert LOGO! Zeitformat in Millisekunden
        T#5s → 5000, T#500ms → 500, T#2m → 120000
        """
        if not param or not param.startswith('T#'):
            return 1000
        
        param = param.replace('T#', '').upper()
        
        if 'MS' in param:
            return int(param.replace('MS', ''))
        elif 'S' in param:
            return int(param.replace('S', '')) * 1000
        elif 'M' in param:
            return int(param.replace('M', '')) * 60000
        elif 'H' in param:
            return int(param.replace('H', '')) * 3600000
        
        return 1000
    
    def generate_variables(self, variables):
        """Generiert C++ Variable-Deklarationen"""
        code = "// ============================================\n"
        code += "// LOGO! VARIABLES\n"
        code += "// ============================================\n"
        
        # Digital Inputs (werden aus Pins gelesen)
        if variables['inputs']:
            code += "// Digital Inputs (read from pins)\n"
            for var in variables['inputs']:
                code += f"bool {var} = false;\n"
            code += "\n"
        
        # Digital Outputs (werden auf Pins geschrieben)
        if variables['outputs']:
            code += "// Digital Outputs (write to pins)\n"
            for var in variables['outputs']:
                code += f"bool {var} = false;\n"
            code += "\n"
        
        # Merker (interne Variablen)
        if variables['merkers']:
            code += "// Merkers (internal flags)\n"
            for var in variables['merkers']:
                code += f"bool {var} = false;\n"
            code += "\n"
        
        # Analog Inputs
        if variables['analog_in']:
            code += "// Analog Inputs (0-1023)\n"
            for var in variables['analog_in']:
                code += f"int {var} = 0;\n"
            code += "\n"
        
        # Analog/PWM Outputs
        if variables['analog_out']:
            code += "// Analog/PWM Outputs (0-255)\n"
            for var in variables['analog_out']:
                code += f"int {var} = 0;\n"
            code += "\n"
        
        return code
    
    def generate_timer_struct(self, timer_id, delay_ms, timer_type='TON'):
        """Erzeugt Timer-Struktur (TON = On-Delay, TOF = Off-Delay)"""
        self.timers.append({'id': timer_id, 'type': timer_type, 'delay': delay_ms})
        
        return f"""
// Timer {timer_id} ({timer_type}): {delay_ms}ms
struct Timer_{timer_id} {{
    unsigned long start_time = 0;
    bool running = false;
    bool output = false;
    const unsigned long delay = {delay_ms};
    const char* type = "{timer_type}";
}} {timer_id};
"""
    
    def generate_counter_struct(self, counter_id, preset):
        """Erzeugt Counter-Struktur (CTU = Up, CTD = Down)"""
        self.counters.append({'id': counter_id, 'preset': preset})
        
        return f"""
// Counter {counter_id}: Preset = {preset}
struct Counter_{counter_id} {{
    int count = 0;
    int preset = {preset};
    bool output = false;
    bool last_input = false;
}} {counter_id};
"""
    
    def generate_flipflop_struct(self, ff_id):
        """Erzeugt SR/RS Flipflop-Struktur"""
        self.flipflops.append(ff_id)
        
        return f"""
// Flipflop {ff_id}
struct Flipflop_{ff_id} {{
    bool output = false;
}} {ff_id};
"""
    
    def generate_logic(self, blocks):
        """Übersetzt LOGO! Blocks in Arduino C++ Code"""
        code = "  // ============================================\n"
        code += "  // LOGO! LOGIC (generated from FUP)\n"
        code += "  // ============================================\n\n"
        
        for block in blocks:
            btype = block['type']
            bid = block['id']
            inputs = block['inputs']
            output = block['output']
            param = block['param']
            
            code += f"  // Block {bid}: {btype}\n"
            
            # === Logik-Bausteine ===
            if btype == 'AND':
                condition = ' && '.join(inputs)
                code += f"  {output} = {condition};\n\n"
            
            elif btype == 'OR':
                condition = ' || '.join(inputs)
                code += f"  {output} = {condition};\n\n"
            
            elif btype == 'NOT':
                code += f"  {output} = !{inputs[0]};\n\n"
            
            elif btype == 'XOR':
                if len(inputs) == 2:
                    code += f"  {output} = {inputs[0]} ^ {inputs[1]};\n\n"
            
            # === Timer ===
            elif btype == 'TON':  # Timer On-Delay
                in1 = inputs[0]
                delay_ms = self.parse_time_param(param)
                
                code += f"""  // TON: Einschaltverzögerung {param}
  if ({in1} && !{bid}.running) {{
    {bid}.start_time = millis();
    {bid}.running = true;
  }}
  if ({bid}.running) {{
    if (millis() - {bid}.start_time >= {bid}.delay) {{
      {bid}.output = true;
    }}
  }}
  if (!{in1}) {{
    {bid}.running = false;
    {bid}.output = false;
  }}
  {output} = {bid}.output;

"""
            
            elif btype == 'TOF':  # Timer Off-Delay
                in1 = inputs[0]
                delay_ms = self.parse_time_param(param)
                
                code += f"""  // TOF: Ausschaltverzögerung {param}
  if (!{in1} && !{bid}.running) {{
    {bid}.start_time = millis();
    {bid}.running = true;
  }}
  if ({bid}.running) {{
    if (millis() - {bid}.start_time >= {bid}.delay) {{
      {bid}.output = false;
    }} else {{
      {bid}.output = true;
    }}
  }}
  if ({in1}) {{
    {bid}.running = false;
    {bid}.output = true;
  }}
  {output} = {bid}.output;

"""
            
            # === Flipflops ===
            elif btype == 'SR':  # Set-Reset (Set dominant)
                set_input = inputs[0] if len(inputs) > 0 else 'false'
                reset_input = inputs[1] if len(inputs) > 1 else 'false'
                code += f"""  if ({set_input}) {bid}.output = true;
  if ({reset_input}) {bid}.output = false;
  {output} = {bid}.output;

"""
            
            elif btype == 'RS':  # Reset-Set (Reset dominant)
                set_input = inputs[0] if len(inputs) > 0 else 'false'
                reset_input = inputs[1] if len(inputs) > 1 else 'false'
                code += f"""  if ({reset_input}) {bid}.output = false;
  if ({set_input}) {bid}.output = true;
  {output} = {bid}.output;

"""
            
            # === Counter ===
            elif btype == 'CTU':  # Count Up
                cu_input = inputs[0]
                preset = int(param) if param.isdigit() else 10
                
                code += f"""  // CTU: Vorwärtszähler bis {preset}
  if ({cu_input} && !{bid}.last_input) {{
    {bid}.count++;
  }}
  {bid}.last_input = {cu_input};
  {bid}.output = ({bid}.count >= {bid}.preset);
  {output} = {bid}.output;

"""
            
            # === Vergleicher ===
            elif btype == 'GT':  # Greater Than
                code += f"  {output} = ({inputs[0]} > {inputs[1]});\n\n"
            
            elif btype == 'LT':  # Less Than
                code += f"  {output} = ({inputs[0]} < {inputs[1]});\n\n"
            
            elif btype == 'GE':  # Greater Equal
                code += f"  {output} = ({inputs[0]} >= {inputs[1]});\n\n"
            
            elif btype == 'LE':  # Less Equal
                code += f"  {output} = ({inputs[0]} <= {inputs[1]});\n\n"
            
            elif btype == 'EQ':  # Equal
                code += f"  {output} = ({inputs[0]} == {inputs[1]});\n\n"
            
            else:
                code += f"  // ⚠️ TODO: {btype} noch nicht implementiert\n\n"
        
        return code
    
    def generate_read_inputs(self):
        """Generiert Code zum Lesen der Inputs"""
        pins = self.hw['pins']
        code = "  // ============================================\n"
        code += "  // READ INPUTS\n"
        code += "  // ============================================\n"
        
        # Digital Inputs (Active LOW mit Pull-Up)
        for name, pin in pins.items():
            if name.startswith('I') and not name.startswith('AI'):
                code += f"  {name} = !digitalRead({pin});  // Active LOW\n"
        
        # Analog Inputs
        for name, pin in pins.items():
            if name.startswith('AI'):
                code += f"  {name} = analogRead({pin});  // 0-1023\n"
        
        # Temperatur Sensor
        code += """
  // Temperature Sensor (DS18B20)
  sensors.requestTemperatures();
  float TEMP = sensors.getTempCByIndex(0);
"""
        
        return code + "\n"
    
    def generate_write_outputs(self):
        """Generiert Code zum Schreiben der Outputs"""
        pins = self.hw['pins']
        flags = self.hw['flags']
        
        code = "  // ============================================\n"
        code += "  // WRITE OUTPUTS\n"
        code += "  // ============================================\n"
        
        # Digital Outputs (Relais)
        relays_active_low = flags.get('relays_active_low', True)
        for name, pin in pins.items():
            if name.startswith('Q'):
                if relays_active_low:
                    code += f"  digitalWrite({pin}, !{name});  // Active LOW\n"
                else:
                    code += f"  digitalWrite({pin}, {name});\n"
        
        # PWM Outputs
        mosfet_active_low = flags.get('mosfet_active_low', False)
        for name, pin in pins.items():
            if 'PWM' in name:
                if mosfet_active_low:
                    code += f"  analogWrite({pin}, 255 - {name});  // Active LOW\n"
                else:
                    code += f"  analogWrite({pin}, {name});  // 0-255\n"
        
        # Status LED (blinkt bei jedem Zyklus)
        code += """
  // Status LED (heartbeat)
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 1000) {
    digitalWrite(LED_STATUS, !digitalRead(LED_STATUS));
    lastBlink = millis();
  }
"""
        
        return code + "\n"
    
    def generate_init_code(self):
        """Generiert Initialisierungs-Code für setup()"""
        pins = self.hw['pins']
        flags = self.hw['flags']
        code = ""
        
        # Relais initial ausschalten
        if flags.get('relays_active_low', True):
            code += "  // Init Relays OFF (Active LOW)\n"
            for name, pin in pins.items():
                if name.startswith('Q'):
                    code += f"  digitalWrite({pin}, HIGH);\n"
        
        return code
    
    def generate_sketch(self, blocks, project_name='Generated', template_path='template.ino'):
        """Generiert kompletten Arduino Sketch"""
        
        # Variablen sammeln
        variables = get_all_variables(blocks)
        
        # Spezial-Strukturen sammeln
        timer_code = ""
        counter_code = ""
        ff_code = ""
        
        for block in blocks:
            if block['type'] in ['TON', 'TOF']:
                delay_ms = self.parse_time_param(block['param'])
                timer_code += self.generate_timer_struct(block['id'], delay_ms, block['type'])
            
            elif block['type'] in ['CTU', 'CTD']:
                preset = int(block['param']) if block['param'].isdigit() else 10
                counter_code += self.generate_counter_struct(block['id'], preset)
            
            elif block['type'] in ['SR', 'RS']:
                ff_code += self.generate_flipflop_struct(block['id'])
        
        structures_code = timer_code + counter_code + ff_code
        
        # Template laden
        try:
            with open(template_path, 'r') as f:
                template = f.read()
        except FileNotFoundError:
            print(f"⚠️  Template '{template_path}' nicht gefunden, nutze Minimal-Template")
            template = self._get_minimal_template()
        
        # Platzhalter ersetzen
        sketch = template.replace('{PROJECT_NAME}', project_name)
        sketch = sketch.replace('{TIMESTAMP}', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        sketch = sketch.replace('{GENERATED_VARIABLES}', self.generate_variables(variables))
        sketch = sketch.replace('{GENERATED_TIMERS}', structures_code)
        sketch = sketch.replace('{GENERATED_INIT}', self.generate_init_code())
        sketch = sketch.replace('{GENERATED_READ_INPUTS}', self.generate_read_inputs())
        sketch = sketch.replace('{GENERATED_LOGIC}', self.generate_logic(blocks))
        sketch = sketch.replace('{GENERATED_WRITE_OUTPUTS}', self.generate_write_outputs())
        sketch = sketch.replace('{GENERATED_FUNCTIONS}', '// No custom functions yet')
        
        return sketch
    
    def _get_minimal_template(self):
        """Fallback: Minimales Template wenn Datei fehlt"""
        return """// Generated Arduino Sketch
// Project: {PROJECT_NAME}
// Generated: {TIMESTAMP}

#include <OneWire.h>
#include <DallasTemperature.h>

// Pin Definitions (Standard)
#define I1 9
#define I2 10
#define Q1 2
#define Q2 4
#define TEMP_PIN 12
#define LED_STATUS 13

OneWire oneWire(TEMP_PIN);
DallasTemperature sensors(&oneWire);

{GENERATED_VARIABLES}

{GENERATED_TIMERS}

void setup() {
  pinMode(I1, INPUT_PULLUP);
  pinMode(I2, INPUT_PULLUP);
  pinMode(Q1, OUTPUT);
  pinMode(Q2, OUTPUT);
  pinMode(LED_STATUS, OUTPUT);
  
  {GENERATED_INIT}
  
  sensors.begin();
}

void loop() {
{GENERATED_READ_INPUTS}

{GENERATED_LOGIC}

{GENERATED_WRITE_OUTPUTS}
  
  delay(50); // 20 Hz cycle
}

{GENERATED_FUNCTIONS}
"""

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generator_arduino.py <projekt.csv> [output_dir]")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('generated')
    
    print(f"🔧 Generiere Arduino Sketch aus: {csv_file}")
    
    # Parsen
    blocks = parse_logo_csv(csv_file)
    hw = load_hardware_profile()
    
    # Generieren
    gen = ArduinoGenerator(hw)
    project_name = Path(csv_file).stem
    sketch = gen.generate_sketch(blocks, project_name)
    
    # Speichern
    sketch_dir = output_dir / f"sketch_{project_name}"
    sketch_dir.mkdir(parents=True, exist_ok=True)
    
    sketch_file = sketch_dir / f"{project_name}.ino"
    with open(sketch_file, 'w') as f:
        f.write(sketch)
    
    print(f"✅ Sketch gespeichert: {sketch_file}")
    print(f"\n📊 Statistik:")
    print(f"  Timer:     {len(gen.timers)}")
    print(f"  Counter:   {len(gen.counters)}")
    print(f"  Flipflops: {len(gen.flipflops)}")
    print(f"\n🔨 Nächster Schritt:")
    print(f"  arduino-cli compile --fqbn arduino:avr:uno {sketch_dir}")

if __name__ == '__main__':
    main()
