import {chromium} from '@playwright/test';
import fs from 'node:fs';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
let failed=0;const errors=[];
const context=await browser.newContext({viewport:{width:1280,height:800}});
const page=await context.newPage();page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.goto(process.env.BASE_URL||'http://localhost:8765/');await page.waitForFunction(()=>window.CQ?.state?.screen==='home',{},{timeout:60000});await page.waitForTimeout(500);
await page.screenshot({path:'evidence/web-home.png'});
await page.mouse.click(210,490);await page.waitForTimeout(500);
await page.mouse.click(600,520);await page.waitForTimeout(700);
await page.screenshot({path:'evidence/web-play.png'});
const coords=await page.evaluate(()=>CQ.state.squares);
const actor=await page.evaluate(()=>CQ.state.actors['5']);
await page.mouse.click(actor[0],actor[1]);
await page.waitForFunction(()=>CQ.state.selected===5);
await page.screenshot({path:'evidence/web-selected.png'});
await page.mouse.click(coords[9][0],coords[9][1]);
await page.waitForFunction(()=>CQ.state?.modal==='success');
await page.screenshot({path:'evidence/web-success.png'});
const savedCompleted=await page.evaluate(()=>CQ.state.completed);
if(savedCompleted!==1){failed++;errors.push('completion not recorded');}

const engine=await page.evaluate(()=>JSON.parse(CQ.legal('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')).length);
if(engine!==20){failed++;errors.push('browser engine failed');}
const specialMissions=JSON.parse(fs.readFileSync(new URL('../data/missions.json',import.meta.url))).filter(m=>m.chapter<=6&&m.boardSize===8);
const specialErrors=await page.evaluate(missions=>{
 const errors=[];
 for(const m of missions){
  const legal=JSON.parse(CQ.legal(m.initialPosition));
  for(const move of m.acceptedSolutions){
   if(!legal.includes(move)){errors.push(m.id+' native/web disagreement '+move);continue;}
   const result=JSON.parse(CQ.move(m.initialPosition,move));
   if(m.type==='EN_PASSANT'&&result.fen.split(' ')[0].includes('p'))errors.push('EP victim remains');
  }
  if(m.id==='1-8'&&legal.includes('e5d6'))errors.push('expired EP allowed');
  if(['6-6','6-7'].includes(m.id)&&legal.includes('e1g1'))errors.push('illegal castle '+m.id);
 }
 return errors;
},specialMissions);
errors.push(...specialErrors);
const puzzleMissions=JSON.parse(fs.readFileSync(new URL('../data/missions.json',import.meta.url))).filter(m=>m.mateLimit);
const puzzleErrors=await page.evaluate(missions=>{
 const out=[];
 for(const m of missions)for(const [key,moves] of Object.entries(m.puzzleBook)){
  const [position,budget]=key.split('|'),fen=position+' 0 1';
  const legal=JSON.parse(CQ.legal(fen)),white=position.split(' ')[1]==='w';
  if(!white&&moves.length!==legal.length)out.push(m.id+' missing defense');
  for(const move of moves){
   if(!legal.includes(move)){out.push(m.id+' illegal '+move);continue;}
   const next=JSON.parse(CQ.move(fen,move)).fen;
   const left=Number(budget)-(white?1:0),nextKey=next.split(' ').slice(0,4).join(' ')+'|'+left;
   if(JSON.parse(CQ.legal(next)).length&&!m.puzzleBook[nextKey])out.push(m.id+' missing continuation');
  }
 }
 return out;
},puzzleMissions);
errors.push(...puzzleErrors);
await page.evaluate(()=>navigator.serviceWorker.ready);await page.waitForTimeout(2000);
const cache=await page.evaluate(async()=>{const keys=await caches.keys();const c=await caches.open(keys.find(k=>k.startsWith('chess-quest-')));return (await c.keys()).length;});
if(cache<15){failed++;errors.push('cache incomplete '+cache);}
await context.setOffline(true);await page.reload();await page.waitForTimeout(5000);await page.screenshot({path:'evidence/web-offline.png'});
const restoredCompleted=await page.evaluate(()=>CQ.state?.completed);
if(restoredCompleted!==1){failed++;errors.push('offline saved progress not restored: '+restoredCompleted);}
await context.setOffline(false);
await page.setViewportSize({width:360,height:780});await page.waitForTimeout(800);await page.screenshot({path:'evidence/web-fold-home.png'});
await page.mouse.click(110,245);await page.waitForTimeout(500);await page.mouse.click(180,260);await page.waitForTimeout(500);await page.screenshot({path:'evidence/web-fold-play.png'});
await page.setViewportSize({width:1024,height:768});await page.waitForTimeout(500);await page.screenshot({path:'evidence/web-ipad.png'});
// Exercise settings and the explicit reset confirmation in this isolated test profile.
await page.setViewportSize({width:1280,height:800});await page.reload();
await page.waitForFunction(()=>CQ.state?.screen==='home');
await page.mouse.click(140,640);await page.waitForFunction(()=>CQ.state?.screen==='settings');
await page.screenshot({path:'evidence/web-fantasy-settings.png'});
await page.mouse.click(1100,653);await page.waitForFunction(()=>CQ.state?.modal==='reset');
await page.screenshot({path:'evidence/web-reset-confirm.png'});
await page.mouse.click(490,528);await page.waitForFunction(()=>CQ.state?.modal==='');
if(await page.evaluate(()=>CQ.state.completed)!==1){failed++;errors.push('reset cancellation lost progress');}
await page.mouse.click(1100,653);await page.waitForFunction(()=>CQ.state?.modal==='reset');
await page.mouse.click(790,528);await page.waitForFunction(()=>CQ.state?.screen==='home'&&CQ.state.completed===0);
await page.waitForTimeout(1500);await page.reload();await page.waitForFunction(()=>CQ.state?.screen==='home');
const resetCompleted=await page.evaluate(()=>CQ.state.completed);
if(resetCompleted!==0){failed++;errors.push('reset did not survive reload');}
await page.mouse.click(300,568);await page.waitForFunction(()=>CQ.state?.screen==='book');
await page.screenshot({path:'evidence/web-empty-book.png'});
await page.mouse.click(640,460);await page.waitForFunction(()=>CQ.state?.screen==='play');
fs.writeFileSync('evidence/browser.json',JSON.stringify({engineLegal:engine,cachedFiles:cache,savedCompleted,restoredCompleted,resetCompleted,errors,failed},null,2));
console.log({engineLegal:engine,cachedFiles:cache,savedCompleted,restoredCompleted,resetCompleted,errors,failed});await browser.close();process.exit(failed||errors.length?1:0);
