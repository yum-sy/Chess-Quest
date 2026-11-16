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
await page.mouse.click(341,381);await page.mouse.click(432,334);
await page.waitForFunction(()=>CQ.state?.modal==='success');
await page.screenshot({path:'evidence/web-success.png'});
const savedCompleted=await page.evaluate(()=>CQ.state.completed);
if(savedCompleted!==1){failed++;errors.push('completion not recorded');}

const engine=await page.evaluate(()=>JSON.parse(CQ.legal('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')).length);
if(engine!==20){failed++;errors.push('browser engine failed');}
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
