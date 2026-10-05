export function forceProfile(row){
  const balance=row?.balance||0;
  const dominance=balance>=20?'order':balance<=-20?'chaos':'contested';
  return {balance,dominance,interventions:row?.interventions||0,
    rationModifier:dominance==='order'?-1:dominance==='chaos'?1:0,
    securityModifier:dominance==='order'?.1:dominance==='chaos'?-.1:0,
    contrabandPay:dominance==='chaos'?28:24,
    title:dominance==='order'?'The Canon holds the signal.':dominance==='chaos'?'The Wound is speaking.':'Two voices. No agreement.',
    description:dominance==='order'?'Rations cost 1 credit less. Capture risk rises by 10 percentage points.':dominance==='chaos'?'Rations cost 1 credit more. Capture risk falls by 10 percentage points; package runs pay 28 credits.':'The city is contested. Ordinary prices and checkpoint risks apply.'};
}
export function citizenForces(p){p.alignment??=0;p.coherence??=68;return p;}
