import {chromium} from '@playwright/test';
const b=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const p=await b.newPage({viewport:{width:360,height:780},hasTouch:true});
await p.goto('https://yum-sy.github.io/Chess-Quest/');await p.waitForFunction(()=>window.CQ?.state?.screen==='home');
await p.touchscreen.tap(65,280);await p.waitForFunction(()=>CQ.state.screen==='map');await p.screenshot({path:'evidence/web-fold-map.png'});
await p.touchscreen.tap(170,755);await p.waitForFunction(()=>CQ.state.screen==='settings');await p.screenshot({path:'evidence/web-fold-settings.png'});
console.log('Fold touchscreen navigation: map and settings PASS');await b.close();
