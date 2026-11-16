import {Chess} from 'chess.js';import fs from 'node:fs';
const fixtures=[];
let seed=20261116;function rand(n){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;}
for(let g=0;g<10;g++){
 const c=new Chess();
 for(let ply=0;ply<120&&!c.isGameOver();ply++){
  const moves=c.moves({verbose:true});
  if(ply%4===0)fixtures.push({fen:c.fen(),moves:moves.map(m=>m.from+m.to+(m.promotion||'')).sort()});
  c.move(moves[rand(moves.length)]);
 }
}
for(const fen of ['r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1','4k3/P7/8/8/8/8/8/4K3 w - - 0 1','k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1']){const c=new Chess(fen);fixtures.push({fen,moves:c.moves({verbose:true}).map(m=>m.from+m.to+(m.promotion||'')).sort()});}
fs.writeFileSync(new URL('./oracle.json',import.meta.url),JSON.stringify(fixtures));console.log(fixtures.length+' independent chess.js positions');
