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
fs.writeFileSync('evidence/browser.json',JSON.stringify({engineLegal:engine,cachedFiles:cache,savedCompleted,restoredCompleted,errors,failed},null,2));
console.log({engineLegal:engine,cachedFiles:cache,savedCompleted,restoredCompleted,errors,failed});await browser.close();process.exit(failed||errors.length?1:0);
