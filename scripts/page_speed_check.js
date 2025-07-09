const puppeteer = require('puppeteer');

async function checkPageSpeed(url) {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    // Enable performance monitoring
    await page.setCacheEnabled(false);
    
    // Listen for performance metrics
    const metrics = {};
    
    page.on('metrics', data => {
      metrics.loadTime = data.metrics.LoadDuration;
    });
    
    // Measure First Contentful Paint
    await page.evaluateOnNewDocument(() => {
      window.fcp = null;
      new PerformanceObserver((list) => {
        const entries = list.getEntries();
        if (entries.length > 0) {
          window.fcp = entries[0].startTime;
        }
      }).observe({ entryTypes: ['paint'] });
    });
    
    // Measure Largest Contentful Paint
    await page.evaluateOnNewDocument(() => {
      window.lcp = null;
      new PerformanceObserver((list) => {
        const entries = list.getEntries();
        if (entries.length > 0) {
          window.lcp = entries[entries.length - 1].startTime;
        }
      }).observe({ entryTypes: ['largest-contentful-paint'] });
    });
    
    // Navigate to the page
    const startTime = Date.now();
    await page.goto(url, { 
      waitUntil: 'networkidle2',
      timeout: 30000 
    });
    const loadTime = Date.now() - startTime;
    
    // Get the metrics
    const fcp = await page.evaluate(() => window.fcp);
    const lcp = await page.evaluate(() => window.lcp);
    
    const result = {
      loadTime: loadTime,
      firstContentfulPaint: fcp || 0,
      largestContentfulPaint: lcp || 0
    };
    
    console.log(JSON.stringify(result));
    
  } catch (error) {
    console.error(JSON.stringify({ error: error.message }));
    process.exit(1);
  } finally {
    await browser.close();
  }
}

// Get URL from command line arguments
const url = process.argv[2];
if (!url) {
  console.error(JSON.stringify({ error: 'URL is required' }));
  process.exit(1);
}

checkPageSpeed(url);

process.on('unhandledRejection', (reason) => {
  console.error(JSON.stringify({ error: reason instanceof Error ? reason.message : reason }));
  process.exit(1);
}); 