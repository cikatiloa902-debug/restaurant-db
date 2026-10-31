"""Перевірка ЛР3. MYSQL_CMD задає команду доступу до справжнього сервера MySQL."""
from pathlib import Path
import json, os, shlex, subprocess
b=Path(__file__).resolve().parent
cmd=shlex.split(os.environ['MYSQL_CMD'])
out=b/'results';out.mkdir(exist_ok=True)
def run(sql, table=False, fail=None):
 p=subprocess.run(cmd+(['--table'] if table else ['--batch','--raw']),input=sql,text=True,encoding='utf-8',capture_output=True)
 if fail:
  assert p.returncode and f'ERROR {fail} ' in p.stderr,p.stderr
  return f'PASS: MySQL rejected invalid insert (ERROR {fail})\n'
 if p.returncode:raise RuntimeError(p.stderr)
 return p.stdout
version=run('SELECT VERSION() AS mysql_version;')
base_counts=run('USE restaurant_db; SELECT (SELECT COUNT(*) FROM `user`) AS users, (SELECT COUNT(*) FROM `order`) AS orders;').splitlines()[1]
assert base_counts=='3\t3','Start with the original fresh LR2 database, not an already populated database.'
run((b/'Mazeina_KI251_02_data_LR3.sql').read_text())
(out/'Mazeina_KI251_server_version.txt').write_text(version)
counts={'user':12,'food':12,'drink':10,'chef':10,'reservation':12,'order':15,'order_item':30,'chef_specialty':15,'notification':15,'transaction':10}
for t,n in counts.items():assert run(f'USE restaurant_db; SELECT COUNT(*) FROM `{t}`;').splitlines()[1]==str(n)
meta=run('''USE restaurant_db; SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL;''')
assert len(meta.splitlines()[1:])==12
for line in meta.splitlines()[1:]:
 t,c,rt,rc=line.split('\t')
 assert run(f'USE restaurant_db; SELECT COUNT(*) FROM `{t}` a LEFT JOIN `{rt}` p ON a.`{c}`=p.`{rc}` WHERE a.`{c}` IS NOT NULL AND p.`{rc}` IS NULL;').splitlines()[1]=='0'
integrity=run((b/'Mazeina_KI251_04_integrity_LR3.sql').read_text(),True)
(out/'Mazeina_KI251_integrity.txt').write_text(integrity)
# Every FK must have the same underlying type and a leading index.
assert run('''USE restaurant_db; SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.COLUMNS c ON c.TABLE_SCHEMA=k.TABLE_SCHEMA AND c.TABLE_NAME=k.TABLE_NAME AND c.COLUMN_NAME=k.COLUMN_NAME
JOIN information_schema.COLUMNS p ON p.TABLE_SCHEMA=k.REFERENCED_TABLE_SCHEMA AND p.TABLE_NAME=k.REFERENCED_TABLE_NAME AND p.COLUMN_NAME=k.REFERENCED_COLUMN_NAME
WHERE k.TABLE_SCHEMA=DATABASE() AND k.REFERENCED_TABLE_NAME IS NOT NULL
AND (c.COLUMN_TYPE<>p.COLUMN_TYPE OR NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS s WHERE s.TABLE_SCHEMA=k.TABLE_SCHEMA AND s.TABLE_NAME=k.TABLE_NAME AND s.COLUMN_NAME=k.COLUMN_NAME AND s.SEQ_IN_INDEX=1));''').splitlines()[1]=='0'
# Check business consistency in the deliberately small teaching model.
for sql in [
'SELECT COUNT(*) FROM order_item WHERE (food_id IS NULL)=(drink_id IS NULL);',
'SELECT COUNT(*) FROM order_item oi JOIN `order` o ON o.order_id=oi.order_id JOIN reservation r ON r.reservation_id=oi.reservation_id WHERE r.user_id<>o.user_id;',
'SELECT COUNT(*) FROM order_item oi WHERE oi.chef_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM chef_specialty cs WHERE cs.chef_id=oi.chef_id AND (cs.food_id=oi.food_id OR cs.drink_id=oi.drink_id));',
'SELECT COUNT(*) FROM `transaction` t JOIN (SELECT oi.order_id,SUM(COALESCE(f.price,d.price)) total FROM order_item oi LEFT JOIN food f ON f.food_id=oi.food_id LEFT JOIN drink d ON d.drink_id=oi.drink_id GROUP BY oi.order_id) x ON x.order_id=t.order_id WHERE t.amount<>x.total;']:
 assert run('USE restaurant_db; '+sql).splitlines()[1]=='0'
qs=json.loads((b/'Mazeina_KI251_queries.json').read_text());expected=[12,10,5,8,3,15,4,9,11,12,9,5];summary=[];combined=version+'\n'
for i,(title,desc,sql) in enumerate(qs,1):
 data=run('USE restaurant_db; '+sql);rows=data.splitlines()[1:]
 assert len(rows)==expected[i-1],(i,len(rows),expected[i-1])
 if i==5:assert [int(x.split('\t')[0]) for x in rows]==[11,12,7]
 if i==8:assert [int(x.split('\t')[0]) for x in rows]==[1,2,4,5,6,7,8,9,10]
 if i==12:assert [int(x.split('\t')[0]) for x in rows]==[11,12,13,14,15]
 text=f'Q{i:02}. {title}\n\n{sql}\n\n'+run('USE restaurant_db; '+sql,True)
 (out/f'Mazeina_KI251_Q{i:02}.txt').write_text(text);combined+=text+'\n'
 summary.append({'query':f'Q{i:02}','rows':len(rows)})
(out/'Mazeina_KI251_query_results.txt').write_text(combined)
negative=''
for sql,error in [
("INSERT INTO `order`(order_id,user_id,order_status) VALUES(999,999,'new');",1452),
("INSERT INTO food(food_id,name,price) VALUES(999,'Invalid',-1);",3819),
("INSERT INTO `user`(user_id,first_name,last_name,email,password) VALUES(999,'A','B','olena@example.test','demo');",1062)]:
 negative+=run('USE restaurant_db; START TRANSACTION; '+sql+' ROLLBACK;',fail=error)
(out/'Mazeina_KI251_validation.txt').write_text('MySQL version: '+version.splitlines()[1]+'\n10 tables: PASS\nAt least 10 rows per table: PASS\n12 foreign keys, compatible types and indexes: PASS\nNo orphan references: PASS\nBusiness consistency: PASS\n12 queries and expected results: PASS\n'+negative)
(out/'Mazeina_KI251_summary.json').write_text(json.dumps({'tables':counts,'queries':summary},ensure_ascii=False,indent=2))
print((out/'Mazeina_KI251_validation.txt').read_text())
