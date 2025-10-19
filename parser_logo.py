#!/usr/bin/env python3
import csv
import yaml

def parse_logo_csv(filepath):
    """
    Liest LOGO! CSV und gibt strukturierte Blocks zurück
    
    CSV-Format:
    Block,Type,Input1,Input2,Output,Parameter
    B001,AND,I1,I2,M1,
    B002,TON,M1,,Q1,T#5s
    """
    blocks = []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            block = {
                'id': row['Block'],
                'type': row['Type'].upper(),
                'inputs': [
                    row.get('Input1', '').strip(),
                    row.get('Input2', '').strip()
                ],
                'output': row.get('Output', '').strip(),
                'param': row.get('Parameter', '').strip()
            }
            # Filter leere Inputs
            block['inputs'] = [i for i in block['inputs'] if i]
            blocks.append(block)
    
    return blocks

def get_all_variables(blocks):
    """Sammelt alle verwendeten Variablen (I, Q, M, AI, AO)"""
    variables = set()
    
    for block in blocks:
        for inp in block['inputs']:
            if inp:
                variables.add(inp)
        if block['output']:
            variables.add(block['output'])
    
    return sorted(variables)

def load_hardware_profile(yaml_path='hardware_profile.yaml'):
    """Lädt Pin-Mapping aus YAML"""
    with open(yaml_path, 'r') as f:
        return yaml.safe_load(f)

if __name__ == '__main__':
    # Test
    blocks = parse_logo_csv('examples/test_blink.csv')
    print(f"Gefunden: {len(blocks)} Blöcke")
    for b in blocks:
        print(f"  {b['id']}: {b['type']} → {b['output']}")
