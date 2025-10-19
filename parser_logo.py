#!/usr/bin/env python3
"""
LOGO! Soft Comfort CSV/XML Parser
Konvertiert LOGO! Projekte in strukturiertes Python-Format
"""

import csv
import yaml
import sys
from pathlib import Path

def parse_logo_csv(filepath):
    """
    Parst LOGO! CSV Export
    
    Erwartetes Format:
    Block,Type,Input1,Input2,Output,Parameter
    B001,AND,I1,I2,M1,
    B002,TON,M1,,Q1,T#5s
    """
    blocks = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for row in reader:
                block = {
                    'id': row.get('Block', '').strip(),
                    'type': row.get('Type', '').strip().upper(),
                    'inputs': [],
                    'output': row.get('Output', '').strip(),
                    'param': row.get('Parameter', '').strip()
                }
                
                # Sammle alle Inputs (Input1, Input2, ...)
                for i in range(1, 10):
                    input_key = f'Input{i}'
                    if input_key in row and row[input_key].strip():
                        block['inputs'].append(row[input_key].strip())
                
                if block['id']:  # Nur valide Blöcke
                    blocks.append(block)
        
        return blocks
    
    except FileNotFoundError:
        print(f"❌ Fehler: Datei '{filepath}' nicht gefunden")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Fehler beim Parsen: {e}")
        sys.exit(1)

def get_all_variables(blocks):
    """
    Sammelt alle verwendeten Variablen
    Kategorien: I (Input), Q (Output), M (Merker), AI/AO (Analog)
    """
    variables = {
        'inputs': set(),
        'outputs': set(),
        'merkers': set(),
        'analog_in': set(),
        'analog_out': set()
    }
    
    for block in blocks:
        # Inputs sammeln
        for inp in block['inputs']:
            if inp.startswith('I') and not inp.startswith('AI'):
                variables['inputs'].add(inp)
            elif inp.startswith('AI'):
                variables['analog_in'].add(inp)
            elif inp.startswith('M'):
                variables['merkers'].add(inp)
        
        # Outputs sammeln
        out = block['output']
        if out.startswith('Q') and not out.startswith('AO'):
            variables['outputs'].add(out)
        elif out.startswith('AO'):
            variables['analog_out'].add(out)
        elif out.startswith('M'):
            variables['merkers'].add(out)
    
    # Sortieren für konsistente Reihenfolge
    return {k: sorted(v) for k, v in variables.items()}

def load_hardware_profile(yaml_path='hardware_profile.yaml'):
    """Lädt Pin-Mapping aus YAML-Konfiguration"""
    try:
        with open(yaml_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"⚠️  Warnung: '{yaml_path}' nicht gefunden, nutze Defaults")
        return {
            'pins': {
                'I1': 9, 'I2': 10, 'I3': 16, 'I4': 17,
                'Q1': 2, 'Q2': 4, 'Q3': 5, 'Q4': 7,
                'AO1_PWM': 3, 'AO2_PWM': 6,
                'AI1': 'A0', 'AI2': 'A1',
                'TEMP_DS18B20': 12, 'BUZZER': 8, 'LED_STATUS': 13
            },
            'flags': {
                'relays_active_low': True,
                'mosfet_active_low': False
            }
        }

def validate_blocks(blocks):
    """Prüft Blocks auf häufige Fehler"""
    errors = []
    
    supported_types = ['AND', 'OR', 'NOT', 'XOR', 'TON', 'TOF', 'SR', 'RS', 
                       'CTU', 'CTD', 'CTUD', 'MOVE', 'ADD', 'SUB', 'MUL', 'DIV',
                       'GT', 'LT', 'GE', 'LE', 'EQ', 'NE']
    
    for block in blocks:
        # Typ prüfen
        if block['type'] not in supported_types:
            errors.append(f"⚠️  Block {block['id']}: Typ '{block['type']}' noch nicht unterstützt")
        
        # Inputs prüfen
        if block['type'] in ['AND', 'OR', 'XOR'] and len(block['inputs']) < 2:
            errors.append(f"❌ Block {block['id']}: {block['type']} benötigt mindestens 2 Inputs")
        
        # Output prüfen
        if not block['output']:
            errors.append(f"⚠️  Block {block['id']}: Kein Output definiert")
    
    return errors

def print_summary(blocks, variables):
    """Gibt Projekt-Zusammenfassung aus"""
    print(f"\n📊 Projekt-Analyse:")
    print(f"  Blöcke gesamt: {len(blocks)}")
    print(f"\n  Block-Typen:")
    
    type_count = {}
    for block in blocks:
        btype = block['type']
        type_count[btype] = type_count.get(btype, 0) + 1
    
    for btype, count in sorted(type_count.items()):
        print(f"    {btype}: {count}×")
    
    print(f"\n  Variablen:")
    print(f"    Digital Inputs:  {len(variables['inputs'])}")
    print(f"    Digital Outputs: {len(variables['outputs'])}")
    print(f"    Merker:          {len(variables['merkers'])}")
    print(f"    Analog Inputs:   {len(variables['analog_in'])}")
    print(f"    Analog Outputs:  {len(variables['analog_out'])}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 parser_logo.py <projekt.csv>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    print(f"🔍 Parse LOGO! Projekt: {csv_file}")
    
    # Parsen
    blocks = parse_logo_csv(csv_file)
    variables = get_all_variables(blocks)
    
    # Validieren
    errors = validate_blocks(blocks)
    if errors:
        print("\n⚠️  Warnungen/Fehler:")
        for err in errors:
            print(f"  {err}")
    
    # Zusammenfassung
    print_summary(blocks, variables)
    
    # Hardware-Profil laden
    hw = load_hardware_profile()
    print(f"\n✅ Hardware-Profil geladen: {len(hw['pins'])} Pins definiert")
    
    print(f"\n✅ Parsing erfolgreich!")
