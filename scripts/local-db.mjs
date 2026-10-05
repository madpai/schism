import { DatabaseSync } from 'node:sqlite';
import { readFileSync, readdirSync } from 'node:fs';
export function localDB(filename=':memory:'){
  const sqlite=new DatabaseSync(filename);
  const migrations=new URL('../drizzle/',import.meta.url);
  for(const filename of readdirSync(migrations).filter(f=>f.endsWith('.sql')).sort())sqlite.exec(readFileSync(new URL(filename,migrations),'utf8'));
  const prepare=(sql,args=[])=>({
    bind(...values){return prepare(sql,values);},
    async first(){return sqlite.prepare(sql).get(...args)||null;},
    async all(){return {results:sqlite.prepare(sql).all(...args)};},
    async run(){const result=sqlite.prepare(sql).run(...args);return {success:true,meta:{changes:Number(result.changes)}};},
    execute(){return sqlite.prepare(sql).run(...args);},
  });
  return {prepare,sqlite,async batch(statements){sqlite.exec('BEGIN');try{const result=statements.map(s=>({success:true,meta:{changes:Number(s.execute().changes)}}));sqlite.exec('COMMIT');return result;}catch(e){sqlite.exec('ROLLBACK');throw e;}}};
}
