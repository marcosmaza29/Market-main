"""Convierte los INSERT del dump MySQL (phpMyAdmin) a PostgreSQL -> db/02_data.sql"""
import re, sys

src = sys.argv[1]
lines = open(src, encoding='utf-8').read().splitlines()
out = ["-- Datos migrados desde MySQL `bd_registro`", "BEGIN;"]
orden = ['admin', 'usuarios', 'productos', 'proveedores',
         'compras_proveedores', 'historial_admin', 'historial_compras']
bloques = {}
i = 0
while i < len(lines):
    m = re.match(r"INSERT INTO `(\w+)` \((.*)\) VALUES$", lines[i])
    if m:
        tabla, cols = m.group(1), m.group(2).replace('`', '')
        filas = []
        i += 1
        while True:
            fila = lines[i]
            fin = fila.endswith(';')
            fila = fila.rstrip(';,')
            if tabla == 'proveedores':  # activo tinyint(1) -> boolean
                fila = re.sub(r", (0|1)\)$", lambda x: ", " + ("TRUE" if x.group(1) == "1" else "FALSE") + ")", fila)
            filas.append(fila)
            if fin:
                break
            i += 1
        bloques[tabla] = f"INSERT INTO {tabla} ({cols}) VALUES\n" + ",\n".join(filas) + ";"
    i += 1

for t in orden:
    if t in bloques:
        out += ["", bloques[t]]
out.append("")
for t in orden:
    out.append(f"SELECT setval(pg_get_serial_sequence('{t}', 'id'), COALESCE((SELECT MAX(id) FROM {t}), 0) + 1, false);")
out.append("COMMIT;")
open('db/02_data.sql', 'w', encoding='utf-8').write("\n".join(out) + "\n")
print({t: bloques[t].count('\n') for t in bloques})
