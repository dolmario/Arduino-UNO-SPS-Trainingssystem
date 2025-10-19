#!/usr/bin/env python3
"""
LOGO! Soft Comfort CSV/XML Parser
Konvertiert LOGO! Projekte in strukturierte Python-Blöcke
"""

import csv
import yaml
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

SUPPORTED_TYPES = {
    # Logik
    "AND", "OR", "NOT", "XOR", "NAND", "NOR",
    # Speicher/Flanken
    "SR", "RS", "R_TRIG", "F_TRIG",
    # Timer
    "TON", "TOF",
    # Zähler
    "CTU", "CTD", "CTUD",
    # Vergleich/Mathe
    "GT", "LT", "GE", "LE", "EQ", "NE", "ADD", "SUB", "MUL", "DIV",
    # MOVE/ASSIGN
    "MOVE"
}

def parse_logo_csv(filepath):
    blocks = []
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            block = {
                'id': row.get('Block', '').strip(),
                'type': row.get('Type', '').strip().upper(),
                'inputs': [],
                'output': (row.get('Output') or '').strip(),
                'param': (row.get('Parameter') or '').strip()
            }
            for i in range(1, 16):
                key = f'Input{i}'
                if key in row and row[key] and row[key].strip():
                    block['inputs'].append(row[key].strip())
            if block['id']:
                blocks.append(block)
    return blocks

def parse_logo_xml(filepath):
    """
    Erwartete, einfache Struktur (angepasst an typische LOGO! XML Exporte):
    <Project>
      <Block id="B001" type="AND">
        <Input name="Input1" ref="I1"/>
        <Input name="Input2" ref="I2"/>
        <Output ref="Q1"/>
        <Param>T#5s</Param>
      </Block>
      ...
    </Project>
    """
    blocks = []
    tree = ET.parse(filepath)
    root = tree.getroot()

    # Versuche generisch Blöcke zu finden
    for b in root.findall(".//Block"):
        btype = (b.get("type") or "").strip().upper()
        bid = (b.get("id") or "").strip()
        inputs = []
        output = ""
        param = ""

        # Inputs
        for inp in b.findall(".//Input"):
            ref = (inp.get("ref") or "").strip()
            if ref:
                inputs.append(ref)

        # Output
        out_elt = b.find(".//Output")
        if out_elt is not None:
            output = (out_elt.get("ref") or (out_elt.text or "")).strip()

        # Param
        p = b.find(".//Param")
        if p is not None:
            param = (p.text or "").strip()

        if bid:
            blocks.append({
                "id": bid,
                "type": btype,
                "inputs": inputs,
                "output": output,
                "param": param
            })
    return blocks

def get_all_variables(blocks):
    variables = {
        'inputs': set(),
        'outputs': set(),
        'merkers': set(),
        'analog_in': set(),
        'analog_out': set()
    }
    for block in blocks:
        for inp in block['inputs']:
            if inp.startswith('AI'):
                variables['analog_in'].add(inp)
            elif inp.startswith('I'):
                variables['inputs'].add(inp)
            elif inp.startswith('M'):
                variables['merkers'].add(inp)
        out = block['output'] or ""
        if out.startswith('AO'):
            variables['analog_out'].add(out)
        elif out.startswith('Q'):
            variables['outputs'].add(out)
        elif out.startswith('M'):
            variables['merkers'].add(out)
    return {k: sorted(v) for k, v in variables.items()}

def load_hardware_profile(yaml_path='hardware_profile.yaml'):
    try:
        with open(yaml_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        # sinnvolle Defaults für UNO-Trainingsplatz
        return {
            'pins': {
                # Digitale I/Os
                'I1': 8, 'I2': 9, 'I3': 10, 'I4': 11,
                'Q1': 2, 'Q2': 3, 'Q3': 4, 'Q4': 5, 'Q5': 6, 'Q6': 7, 'Q7': 12, 'Q8': 13,
                # PWM/MOSFET
                'AO1_PWM': 6, 'AO2_PWM': 5,
                # Analog
                'AI1': 'A0', 'AI2': 'A1', 'AI3': 'A2', 'AI4': 'A3',
                # Sensoren/Special
                'TEMP_DS18B20': 2,     # OneWire pin (anpassbar)
                'BUZZER': 8,
                # 7-Segment BCD (A,B,C,D)
                'BCD_A': 14, 'BCD_B': 15, 'BCD_C': 16, 'BCD_D': 17,
                # KY-040
                'ENC_A': 18, 'ENC_B': 19, 'ENC_SW': 7
            },
            'flags': {
                'relays_active_low': True,
                'mosfet_active_low': False
            }
        }

def validate_blocks(blocks):
    errors = []
    for b in blocks:
        t = b['type']
        if t not in SUPPORTED_TYPES:
            errors.append(f"⚠️  Block {b['id']}: Typ '{t}' (noch) nicht unterstützt")
        if t in {"AND","OR","XOR","NAND","NOR"} and len(b['inputs']) < 2:
            errors.append(f"❌ Block {b['id']}: {t} benötigt mindestens 2 Inputs")
        if not b.get('output'):
            errors.append(f"⚠️  Block {b['id']}: Kein Output definiert")
    return errors

def print_summary(blocks, variables):
    print(f"\n📊 Projekt-Analyse:")
    print(f"  Blöcke gesamt: {len(blocks)}")
    print("\n  Block-Typen:")
    type_count = {}
    for b in blocks:
        type_count[b['type']] = type_count.get(b['type'], 0) + 1
    for k in sorted(type_count):
        print(f"    {k}: {type_count[k]}×")
    print("\n  Variablen:")
    print(f"    Digital Inputs:  {len(variables['inputs'])}")
    print(f"    Digital Outputs: {len(variables['outputs'])}")
    print(f"    Merker:          {len(variables['merkers'])}")
    print(f"    Analog Inputs:   {len(variables['analog_in'])}")
    print(f"    Analog Outputs:  {len(variables['analog_out'])}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 parser_logo.py <projekt.csv|projekt.xml>")
        sys.exit(1)
    in_file = sys.argv[1]
    print(f"🔍 Parse LOGO! Projekt: {in_file}")

    suffix = Path(in_file).suffix.lower()
    if suffix == ".xml":
        blocks = parse_logo_xml(in_file)
    else:
        blocks = parse_logo_csv(in_file)

    variables = get_all_variables(blocks)
    errors = validate_blocks(blocks)
    if errors:
        print("\n⚠️  Warnungen/Fehler:")
        for e in errors:
            print("  " + e)
    print_summary(blocks, variables)

    hw = load_hardware_profile()
    print(f"\n✅ Hardware-Profil geladen (Pins: {len(hw.get('pins',{}))})")
    print("\n✅ Parsing erfolgreich!")
