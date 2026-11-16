window.CQ = {
 legal(fen) { return JSON.stringify(new Chess(fen).moves({verbose:true}).map(m=>m.from+m.to+(m.promotion||''))); },
 move(fen,uci) { const c=new Chess(fen);const m=c.move({from:uci.slice(0,2),to:uci.slice(2,4),promotion:uci[4]||'q'}); return JSON.stringify({fen:c.fen(),san:m.san}); }
};
