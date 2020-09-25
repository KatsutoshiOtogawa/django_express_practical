const playwright = require('playwright');

const urllist = ['http://localhost/site/','http://localhost/site/recommend'];
(async () => {
  for (const browserType of ['chromium', 'firefox', 'webkit']) {
    const browser = await playwright[browserType].launch();
    const context = await browser.newContext();
    const page = await context.newPage();
    for (let i=0;i<urllist.length;i++){
      await page.goto(url[i]);
      await page.screenshot({ path: `example-${browserType}-${urllist[i]}.png` });
    }
    
    await browser.close();
  }
})();