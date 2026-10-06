// Explicitly authorized character reset. The permanent receipt makes this operation
// idempotent across retries and concurrent requests; it never runs during normal play.
export const CHARACTER_RESET_ID='residency-fresh-start-2026-10-05';
export async function resetCharacters(db,now=Date.now()){
  const receipt=()=>db.prepare('SELECT * FROM maintenance_runs WHERE id=?').bind(CHARACTER_RESET_ID).first();
  const existing=await receipt();if(existing)return {...existing,applied:false};
  try{
    await db.batch([
      db.prepare('INSERT INTO maintenance_runs (id,completed,citizens) SELECT ?,?,count(*) FROM citizens').bind(CHARACTER_RESET_ID,now),
      db.prepare('DELETE FROM listings'),
      db.prepare('DELETE FROM device_offers'),
      db.prepare('DELETE FROM camp_production WHERE completes>?').bind(now),
      db.prepare('DELETE FROM posts'),
      db.prepare('DELETE FROM journal'),
      // Completed contributions belong to city history; unfinished work must not
      // survive a character reset and generate benefits for a deleted citizen.
      db.prepare('DELETE FROM city_activity WHERE completes>?').bind(now),
      db.prepare('DELETE FROM citizens'),
    ]);
    return {...await receipt(),applied:true};
  }catch(error){
    // A concurrent winner inserts the same primary-key receipt in its transaction.
    // Any other failure must surface, with the whole reset rolled back.
    if(/UNIQUE constraint failed: maintenance_runs\.id/.test(String(error))){
      const winner=await receipt();if(winner)return {...winner,applied:false};
    }
    throw error;
  }
}
