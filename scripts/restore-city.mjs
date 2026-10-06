// Restore only into a new, isolated database. Never import over a running city.
import {readFileSync,existsSync,mkdirSync,chmodSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {localDB} from './local-db.mjs';
import {backupTables} from '../worker/community.js';
export function restoreCity(backup,filename){
 if(filename===':memory:'||existsSync(filename))throw Error('Choose a new isolated database file; existing destinations are never overwritten.');
 if(backup?.format!=='schism-city-backup-v1'||!backup.tables)throw Error('Unsupported city backup.');
 for(const table of backupTables)if(!Array.isArray(backup.tables[table])||backup.tables[table].length>10000)throw Error('Invalid or missing table: '+table);
 mkdirSync(dirname(resolve(filename)),{recursive:true,mode:0o700});const db=localDB(filename);chmodSync(filename,0o600);
 db.sqlite.exec('BEGIN');
 try{for(const table of backupTables){const columns=db.sqlite.prepare('PRAGMA table_info('+table+')').all().map(c=>c.name);for(const row of backup.tables[table]){if(!row||Object.keys(row).some(key=>!columns.includes(key))||columns.some(key=>!Object.hasOwn(row,key)))throw Error('Invalid row shape: '+table);db.sqlite.prepare('INSERT INTO '+table+' ('+columns.join(',')+') VALUES ('+columns.map(()=>'?').join(',')+')').run(...columns.map(k=>row[k]));}}db.sqlite.exec('COMMIT');}
 catch(error){db.sqlite.exec('ROLLBACK');db.sqlite.close();throw error;}
 const integrity=db.sqlite.prepare('PRAGMA integrity_check').get().integrity_check;if(integrity!=='ok')throw Error('Restored database failed integrity check.');return db;
}
if(process.argv[1]===new URL(import.meta.url).pathname){const [, ,input,destination]=process.argv;if(!input||!destination)throw Error('Usage: node --experimental-sqlite scripts/restore-city.mjs backup.json NEW-isolated-city.sqlite');const db=restoreCity(JSON.parse(readFileSync(input,'utf8')),resolve(destination));console.log('Restored isolated city. Integrity: ok. Citizens: '+db.sqlite.prepare('SELECT count(*) n FROM citizens').get().n);db.sqlite.close();}
