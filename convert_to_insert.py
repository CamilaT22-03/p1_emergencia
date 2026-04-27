import sys
import re

input_file = r'c:\DEV\SI2\emengencia_bd.sql'
output_file = r'c:\DEV\SI2\Parcial1_emergenciasVehiculares\inserts_supabase.sql'

with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

table_data = {}
in_copy = False
table_name = ''
columns = []

for line in lines:
    if line.startswith('COPY public.'):
        match = re.match(r'COPY public\.(\w+) \((.*?)\) FROM stdin;', line)
        if match:
            table_name = match.group(1)
            columns = match.group(2).split(', ')
            in_copy = True
            table_data[table_name] = []
            continue
    
    if in_copy:
        if line.strip() == '\\.':
            in_copy = False
            continue
        
        values = line.strip('\n').split('\t')
        formatted_values = []
        for val in values:
            if val == r'\N':
                formatted_values.append('NULL')
            else:
                val_escaped = val.replace("'", "''")
                formatted_values.append(f"'{val_escaped}'")
        
        cols_str = ', '.join(columns)
        vals_str = ', '.join(formatted_values)
        table_data[table_name].append(f"INSERT INTO public.{table_name} ({cols_str}) VALUES ({vals_str});\n")

# Definir el orden correcto según las llaves foráneas
orden = [
    'clientes',
    'talleres',
    'vehiculos',
    'tecnicos',
    'emergencias',
    'aceptaciones_taller',
    'historial_estados',
    'pagos',
    'tokens_notificacion'
]

with open(output_file, 'w', encoding='utf-8') as out:
    out.write('-- Archivo generado con INSERTS ordenados para evitar errores de llave foránea\n\n')
    for t in orden:
        if t in table_data:
            out.write(f'-- Datos para la tabla {t}\n')
            for insert_stmt in table_data[t]:
                out.write(insert_stmt)
            out.write('\n')

    out.write('''
-- Actualizar los ID autoincrementales para que sigan desde el último número insertado
SELECT setval('public.clientes_id_seq', (SELECT MAX(id) FROM public.clientes));
SELECT setval('public.talleres_id_seq', (SELECT MAX(id) FROM public.talleres));
SELECT setval('public.vehiculos_id_seq', (SELECT MAX(id) FROM public.vehiculos));
SELECT setval('public.tecnicos_id_seq', (SELECT MAX(id) FROM public.tecnicos));
SELECT setval('public.emergencias_id_seq', (SELECT MAX(id) FROM public.emergencias));
SELECT setval('public.aceptaciones_taller_id_seq', (SELECT MAX(id) FROM public.aceptaciones_taller));
SELECT setval('public.historial_estados_id_seq', (SELECT MAX(id) FROM public.historial_estados));
SELECT setval('public.pagos_id_seq', (SELECT MAX(id) FROM public.pagos));
SELECT setval('public.tokens_notificacion_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.tokens_notificacion));
''')

print('Generado correctamente')
