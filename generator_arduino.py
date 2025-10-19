#!/usr/bin/env python3
from parser_logo import parse_logo_csv, get_all_variables, load_hardware_profile
from datetime import datetime

class ArduinoGenerator:
    def __init__(self, hardware_profile):
        self.hw = hardware_profile
        self.timers = []
        self.counters = []
    
    def generate_variables(self, variables):
        """Generiert Variable-Deklarationen"""
        code = "// Variables\n"
        
        for var in variables:
            if var.startswith('M'):
                code += f"bool {var} = false;\n"
            elif var.startswith('AI'):
                code += f"int {var} = 0;\n"
            elif var.startswith('AO'):
                code += f"int {var} = 0;\n"
        
        return code
    
    def generate_timer_struct(self, timer_id, delay_ms):
        """Erzeugt Timer-Struktur"""
        self.timers.append(timer_id)
        return f"""
struct Timer_{timer_id} {{
    unsigned long start_time = 0;
    bool running = false;
    bool output = false;
    const unsigned long delay = {delay_ms};
}};
Timer_{timer_id} {timer_id};
"""
    
    def parse_time_param(self, param):
        """T#5s → 5000 ms"""
        if not param or not param.startswith('T#'):
            return 1000
        
        param = param.replace('T#', '').upper()
        
        if 'MS' in param:
            return int(param.replace('MS', ''))
        elif 'S' in param:
            return int(param.replace('S', '')) * 1000
        elif 'M' in param:
            return int(param.replace('M', '')) * 60000
        
        return 1000
    
    def generate_logic(self, blocks):
        """Übersetzt LOGO! Blocks in C++"""
        code = "  // === LOGO! Logic ===\n"
        
        for block in blocks:
            btype = block['type']
            bid = block['id']
            inputs = block['inputs']
            output = block['output']
            param = block['param']
            
            if btype == 'AND':
                in1, in2 = inputs[0], inputs[1]
                code += f"  {output} = {in1} && {in2};\n"
            
            elif btype == 'OR':
                in1, in2 = inputs[0], inputs[1]
                code += f"  {output} = {in1} || {in2};\n"
            
            elif btype == 'NOT':
                in1 = inputs[0]
                code += f"  {output} = !{in1};\n"
            
            elif btype == 'TON':  # Timer On-Delay
                in1 = inputs[0]
                delay_ms = self.parse_time_param(param)
                
                code += f"""
  // TON {bid}: {param}
  if ({in1} && !{bid}.running) {{
    {bid}.start_time = millis();
    {bid}.running = true;
  }}
  if ({bid}.running && (millis() - {bid}.start_time >= {bid}.delay)) {{
    {bid}.output = true;
  }}
  if (!{in1}) {{
    {bid}.running = false;
    {bid}.output = false;
  }}
  {output} = {bid}.output;
"""
            
            elif btype == 'SR':  # Set-Reset Flipflop
                set_input = inputs[0]
                reset_input = inputs[1] if len(inputs) > 1 else 'false'
                code += f"""
  if ({set_input}) {output} = true;
  if ({reset_input}) {output} = false;
"""
            
            else:
                code += f"  // TODO: {btype} nicht implementiert\n"
        
        return code
    
    def generate_read_inputs(self):
        """Liest digitale/analoge Eingänge"""
        pins = self.hw['pins']
        code = "  // Read Inputs\n"
        
        for name, pin in pins.items():
            if name.startswith('I'):
                code += f"  bool {name} = !digitalRead({pin});  // Active LOW\n"
            elif name.startswith('AI'):
                code += f"  int {name} = analogRead({pin});\n"
        
        # Temperatur
        code += """
  // Temperature Sensor
  sensors.requestTemperatures();
  float TEMP = sensors.getTempCByIndex(0);
"""
        return code
    
    def generate_write_outputs(self):
        """Schreibt Relais/PWM"""
        pins = self.hw['pins']
        flags = self.hw['flags']
        code = "  // Write Outputs\n"
        
        # Relais (Active LOW!)
        for name, pin in pins.items():
            if name.startswith('Q'):
                if flags['relays_active_low']:
                    code += f"  digitalWrite({pin}, !{name});  // Active LOW\n"
                else:
                    code += f"  digitalWrite({pin}, {name});\n"
        
        # PWM (Active HIGH!)
        for name, pin in pins.items():
            if 'PWM' in name:
                code += f"  analogWrite({pin}, {name});  // 0-255\n"
        
        return code
    
    def generate_sketch(self, blocks, project_name='Generated'):
        """Kompletter Sketch"""
        variables = get_all_variables(blocks)
        
        # Timer-Strukturen sammeln
        timer_code = ""
        for block in blocks:
            if block['type'] == 'TON':
                delay_ms = self.parse_time_param(block['param'])
                timer_code += self.generate_timer_struct(block['id'], delay_ms)
        
        # Template laden
        with open('template.ino', 'r') as f:
            template = f.read()
        
        # Platzhalter ersetzen
        sketch = template.replace('{PROJECT_NAME}', project_name)
        sketch = sketch.replace('{TIMESTAMP}', datetime.now().isoformat())
        sketch = sketch.replace('{GENERATED_VARIABLES}', self.generate_variables(variables))
        sketch = sketch.replace('{GENERATED_TIMERS}', timer_code)
        sketch = sketch.replace('{GENERATED_INIT}', '  // Init relays OFF\n  digitalWrite(Q1, HIGH);  // Active LOW\n')
        sketch = sketch.replace('{GENERATED_READ_INPUTS}', self.generate_read_inputs())
        sketch = sketch.replace('{GENERATED_LOGIC}', self.generate_logic(blocks))
        sketch = sketch.replace('{GENERATED_WRITE_OUTPUTS}', self.generate_write_outputs())
        sketch = sketch.replace('{GENERATED_FUNCTIONS}', '// None yet')
        
        return sketch

if __name__ == '__main__':
    # Test
    hw = load_hardware_profile()
    blocks = parse_logo_csv('examples/test_blink.csv')
    
    gen = ArduinoGenerator(hw)
    sketch = gen.generate_sketch(blocks, 'Test Blink')
    
    print(sketch)
