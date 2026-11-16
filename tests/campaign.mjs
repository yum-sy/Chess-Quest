// Independent legal, complete winning games: Stockfish is a test-only white player.
import {spawn} from 'node:child_process';import {Chess} from 'chess.js';import fs from 'node:fs';import readline from 'node:readline';
const dir=new URL('../node_modules/stockfish/src/',import.meta.url);const sf=fs.readdirSync(dir).find(n=>/lite-single.*\.js$/.test(n));
const proc=spawn(process.execPath,[decodeURIComponent(new URL(sf,dir).pathname)],{stdio:['pipe','pipe','inherit']});
const lines=readline.createInterface({input:proc.stdout});let pending;
lines.on('line',line=>{if(line.startsWith('bestmove ')){pending?.(line.split(' ')[1]);pending=null;}});
const best=fen=>new Promise(resolve=>{pending=resolve;proc.stdin.write('position fen '+fen+'\ngo depth 12\n');});
const missions=JSON.parse(fs.readFileSync(new URL('../data/missions.json',import.meta.url)));
const games=[];let seed=5678;const rand=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n};
for(const m of missions.filter(m=>m.type==='GAME')){
 const c=new Chess(m.initialPosition);const moves=[];
 for(let ply=0;ply<450&&!c.isGameOver();ply++){
  let uci;if(c.turn()==='w')uci=await best(c.fen());else {const all=c.moves({verbose:true});const x=all[rand(all.length)];uci=x.from+x.to+(x.promotion||'');}
  c.move({from:uci.slice(0,2),to:uci.slice(2,4),promotion:uci[4]||'q'});moves.push(uci);
 }
 const won=c.isCheckmate()&&c.turn()==='b';games.push({id:m.id,initial:m.initialPosition,moves,won,final:c.fen()});console.log(m.id,moves.length,'plies',won?'WHITE CHECKMATE':'FAIL');
}
proc.kill();fs.writeFileSync(new URL('./campaign.json',import.meta.url),JSON.stringify(games));if(games.some(g=>!g.won))process.exitCode=1;
