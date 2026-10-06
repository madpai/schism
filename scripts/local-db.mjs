import { DatabaseSync } from 'node:sqlite';
import { readFileSync, readdirSync } from 'node:fs';
export function localDB(filename=':memory:'){
  const sqlite=new DatabaseSync(filename);
  sqlite.exec('PRAGMA busy_timeout=5000; PRAGMA journal_mode=WAL; CREATE TABLE IF NOT EXISTS _local_migrations (name TEXT PRIMARY KEY)');
  const migrations=new URL('../drizzle/',import.meta.url);
  for(const name of readdirSync(migrations).filter(f=>f.endsWith('.sql')).sort()){
    if(sqlite.prepare('SELECT 1 FROM _local_migrations WHERE name=?').get(name))continue;
    sqlite.exec('BEGIN');
    try{sqlite.exec(readFileSync(new URL(name,migrations),'utf8'));sqlite.prepare('INSERT INTO _local_migrations (name) VALUES (?)').run(name);sqlite.exec('COMMIT');}
    catch(error){sqlite.exec('ROLLBACK');throw error;}
  }
  const prepare=(sql,args=[])=>({
    bind(...values){return prepare(sql,values);},
    async first(){return sqlite.prepare(sql).get(...args)||null;},
    async all(){return {results:sqlite.prepare(sql).all(...args)};},
    async run(){const result=sqlite.prepare(sql).run(...args);return {success:true,meta:{changes:Number(result.changes)}};},
    execute(){const s=sqlite.prepare(sql);if(s.columns().length)return {success:true,results:s.all(...args),meta:{changes:0}};const r=s.run(...args);return {success:true,meta:{changes:Number(r.changes)}};},
  });
  return {prepare,sqlite,async batch(statements){sqlite.exec('BEGIN');try{const result=statements.map(s=>s.execute());sqlite.exec('COMMIT');return result;}catch(e){sqlite.exec('ROLLBACK');throw e;}}};
}
