"""Deterministically port the vendored MySQL schema and INSERTs; never invent records."""
from pathlib import Path
import re, sqlite3, json
root = Path(__file__).resolve().parents[1]
source = root / 'original-database'
def clean(s):
    return re.sub(r'--[^\n]*', '', s).replace("\\'", "''")
statements = []
for f in sorted((source/'schema').glob('*.sql'))[1:]:
    s = clean(f.read_text())
    table = re.search(r'CREATE TABLE (\w+) \((.*?)\) ENGINE', s, re.S)
    name, body = table.groups()
    enums = []
    def enum(m):
        col, values = m.groups(); enums.append(f'CHECK ({col} IN ({values}))')
        return col + ' TEXT'
    body = re.sub(r'(\w+)\s+ENUM\((.*?)\)', enum, body, flags=re.S)
    body = re.sub(r'\b(BIGINT|SMALLINT|TINYINT|INT)(\(\d+\))?\s*(UNSIGNED)?', 'INTEGER ', body)
    body = re.sub(r'\b(VARCHAR|CHAR)\(\d+\)', 'TEXT', body)
    body = re.sub(r'\b(DATETIME|DATE|JSON)\b', 'TEXT', body)
    body = re.sub(r'DECIMAL\(\d+,\s*\d+\)', 'NUMERIC', body)
    auto = re.search(r'(\w+)\s+INTEGER\s+NOT NULL AUTO_INCREMENT', body).group(1)
    body = re.sub(r'INTEGER\s+NOT NULL AUTO_INCREMENT', 'INTEGER PRIMARY KEY AUTOINCREMENT', body)
    body = re.sub(r'CONSTRAINT pk_\w+ PRIMARY KEY \(\w+\),?', '', body)
    body = re.sub(r'ON UPDATE CURRENT_TIMESTAMP', '', body).strip().rstrip(',')
    if name == 'users': body = body.replace('email           TEXT', 'email           TEXT COLLATE NOCASE')
    # Decimal arithmetic is exact in MySQL, but SQLite uses binary floats.
    body = body.replace('total_price = quantity * unit_price', 'ABS(total_price - quantity * unit_price) < 0.005')
    if enums: body += ',\n    ' + ',\n    '.join(enums)
    statements.append(f'CREATE TABLE {name} (\n{body}\n);')
    statements += re.findall(r'CREATE INDEX .*?;', s, re.S)
    if 'updated_at' in body:
        statements.append(f'CREATE TRIGGER touch_{name} AFTER UPDATE ON {name} WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE {name} SET updated_at = CURRENT_TIMESTAMP WHERE {auto} = NEW.{auto}; END;')
# Coupons must precede orders because seed orders reference them.
for n in [1,2,3,4,5,8,6,7]:
    f = next((source/'seeds').glob(f'{n:02d}_*.sql'))
    statements += re.findall(r'INSERT INTO .*?;', clean(f.read_text()), re.S)
sql = '-- Source commit: ab93963abf1d912dbc2ee424b22d639546f3f3c7\n' + '\n\n'.join(statements) + '\n'
(root/'migrations/0001_original_dataset.sql').write_text(sql)
db = sqlite3.connect(':memory:'); db.execute('PRAGMA foreign_keys=ON'); db.executescript(sql)
assert not db.execute('PRAGMA foreign_key_check').fetchall()
counts = {r[0]:db.execute('SELECT COUNT(*) FROM '+r[0]).fetchone()[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")}
print(json.dumps(counts, indent=2))
