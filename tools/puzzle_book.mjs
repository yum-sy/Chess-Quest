// Exhaustive bounded mate proof using chess.js. Every legal black defense is included.
import {Chess} from 'chess.js';import fs from 'node:fs';
const path=new URL('../data/missions.json',import.meta.url);const missions=JSON.parse(fs.readFileSync(path));
const key=(c,left)=>c.fen().split(' ').slice(0,4).join(' ')+'|'+left;
const uci=m=>m.from+m.to+(m.promotion||'');
for(const m of missions.filter(m=>m.mateLimit)){
 const c=new Chess(m.initialPosition),memo=new Map();let calls=0;
 function wins(left){
  const k=key(c,left);if(memo.has(k))return memo.get(k);calls++;
  if(c.isCheckmate()){const v=c.turn()==='b';memo.set(k,v);return v;}
  if(c.isStalemate()||c.isInsufficientMaterial()||left<=0&&c.turn()==='w'){memo.set(k,false);return false;}
  const white=c.turn()==='w';const moves=c.moves({verbose:true}).sort((a,b)=>Number(b.san.includes('#'))-Number(a.san.includes('#'))||Number(b.san.includes('+'))-Number(a.san.includes('+')));
  let result=!white;
  for(const move of moves){c.move(move);const v=wins(left-(white?1:0));c.undo();if(white&&v){result=true;break;}if(!white&&!v){result=false;break;}}
  memo.set(k,result);return result;
 }
 if(!wins(m.mateLimit))throw Error('Not forced mate: '+m.id);
 if(m.mateLimit>1&&wins(m.mateLimit-1))throw Error('Too easy: '+m.id);
 const book={};
 function collect(left){
  const k=key(c,left);if(book[k]||c.isCheckmate())return;
  const white=c.turn()==='w';const moves=[];
  for(const move of c.moves({verbose:true})){c.move(move);const good=wins(left-(white?1:0));c.undo();if(!white&&!good)throw Error('Unproven defense');if(good)moves.push(uci(move));}
  if(!moves.length)throw Error('Empty winning node');book[k]=moves;
  for(const move of moves){c.move({from:move.slice(0,2),to:move.slice(2,4),promotion:move[4]});collect(left-(white?1:0));c.undo();}
 }
 collect(m.mateLimit);m.puzzleBook=book;
 console.log(m.id,'mate',m.mateLimit,'proof nodes',Object.keys(book).length,'searched',calls);
}
fs.writeFileSync(path,JSON.stringify(missions,null,2));
