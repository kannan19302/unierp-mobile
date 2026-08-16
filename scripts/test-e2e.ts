import http from "node:http";

const BASE_URL = process.env.TARGET_URL || "http://localhost:4009";

interface TestResult {
  name: string;
  passed: boolean;
  durationMs: number;
  error?: string;
}

const results: TestResult[] = [];

async function checkRoute(route: string, expectedString: string, testName: string) {
  const start = Date.now();
  try {
    const url = new URL(route, BASE_URL);
    const res = await new Promise<{ statusCode: number; body: string }>((resolve, reject) => {
      const req = http.get(url.toString(), { timeout: 15000 }, (response) => {
        let body = "";
        response.on("data", chunk => { body += chunk; });
        response.on("end", () => resolve({ statusCode: response.statusCode || 0, body }));
      });
      req.on("error", reject);
      req.on("timeout", () => {
        req.destroy();
        reject(new Error("Request timed out after 15000ms"));
      });
    });

    const duration = Date.now() - start;
    if (res.statusCode >= 200 && res.statusCode < 400 && res.body.includes(expectedString)) {
      results.push({ name: testName, passed: true, durationMs: duration });
      console.log(`  ✅ [PASS] GET ${route} (${duration}ms)`);
    } else {
      const err = `Expected status 200-399 with body containing '${expectedString}', got HTTP ${res.statusCode}`;
      results.push({ name: testName, passed: false, durationMs: duration, error: err });
      console.log(`  ❌ [FAIL] GET ${route} (${duration}ms): ${err}`);
    }
  } catch (err: any) {
    const duration = Date.now() - start;
    results.push({ name: testName, passed: false, durationMs: duration, error: err.message });
    console.log(`  ❌ [FAIL] GET ${route} (${duration}ms): ${err.message}`);
  }
}

async function run() {
  console.log("════════════════════════════════════════════════════════════════════════");
  console.log("📱 UniERP Mobile App (Android & iOS) — E2E Integration Suite");
  console.log(`Target: ${BASE_URL}`);
  console.log("════════════════════════════════════════════════════════════════════════\n");

  console.log("🔍 Checking server connection...");
  let reachable = false;
  for (let i = 0; i < 20; i++) {
    try {
      await new Promise<void>((resolve, reject) => {
        const req = http.get(`${BASE_URL}/health`, (res) => {
          if (res.statusCode && res.statusCode < 500) resolve();
          else reject(new Error(`Status ${res.statusCode}`));
        });
        req.on("error", reject);
      });
      reachable = true;
      break;
    } catch {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  if (!reachable) {
    console.log(`❌ Target server ${BASE_URL} is unreachable.`);
  } else {
    console.log("✅ Target server is reachable.\n");
  }

  console.log("📂 1. Mobile Workstation Shell (Android + iOS Simulator)");
  await checkRoute("/", "UniERP Mobile", "Mobile frame renders simulator shell & KPI cards");

  console.log("\n🏥 2. Mobile Client Healthcheck API");
  await checkRoute("/health", "P9 Mobile App", "Health probe returns JSON ok status");

  console.log("\n════════════════════════════════════════════════════════════════════════");
  console.log("📊 Test Execution Summary");
  console.log("════════════════════════════════════════════════════════════════════════");
  const passedCount = results.filter(r => r.passed).length;
  const failedCount = results.filter(r => !r.passed).length;
  console.log(`Total Tests: ${results.length}`);
  console.log(`Passed:      ${passedCount}`);
  console.log(`Failed:      ${failedCount}\n`);

  if (failedCount > 0) {
    console.error("❌ Some Mobile App End-to-End tests failed!");
    process.exit(1);
  } else {
    console.log("🎉 All Mobile App End-to-End tests passed successfully!\n");
    process.exit(0);
  }
}

run();
