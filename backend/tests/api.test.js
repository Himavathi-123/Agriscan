const assert = require('assert');
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';
const sampleImagePath = path.join(__dirname, '../test_samples/rice_brown_plant_hopper_sample.jpg');

async function runTests() {
  console.log('\n==================================================');
  console.log('      AGRISCAN INTEGRATION TEST SUITE            ');
  console.log('==================================================\n');

  let passed = 0;
  let failed = 0;

  async function testCase(name, testFn) {
    try {
      console.log(`[TEST] ${name}...`);
      await testFn();
      console.log(`  ✓ PASSED: ${name}\n`);
      passed++;
    } catch (err) {
      console.error(`  ✗ FAILED: ${name}`);
      console.error(`    Error: ${err.message}\n`);
      failed++;
    }
  }

  // Test 1: Node & Python Health Check
  await testCase('1. GET /api/v1/health', async () => {
    const res = await axios.get(`${BACKEND_URL}/api/v1/health`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.status, 'ok');
    assert.ok(res.data.aiService);
  });

  // Test 2: Invalid File Format Rejection
  await testCase('2. POST /api/v1/detect with text file (400 Bad Request)', async () => {
    const formData = new FormData();
    formData.append('image', Buffer.from('this is not an image'), {
      filename: 'test.txt',
      contentType: 'text/plain'
    });

    try {
      await axios.post(`${BACKEND_URL}/api/v1/detect`, formData, {
        headers: formData.getHeaders()
      });
      assert.fail('Should have failed with 400 Bad Request');
    } catch (err) {
      assert.strictEqual(err.response?.status, 400);
      assert.strictEqual(err.response?.data?.success, false);
    }
  });

  // Test 3: Valid Crop Image Detection Pipeline
  await testCase('3. POST /api/v1/detect with crop image sample', async () => {
    if (!fs.existsSync(sampleImagePath)) {
      console.log('  Skipping sample image test (file not found)');
      return;
    }

    const formData = new FormData();
    formData.append('image', fs.createReadStream(sampleImagePath));

    const res = await axios.post(`${BACKEND_URL}/api/v1/detect`, formData, {
      headers: formData.getHeaders()
    });

    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.success, true);
    assert.ok(res.data.data);
    assert.ok(Array.isArray(res.data.data.pests));
    assert.ok(Array.isArray(res.data.data.diseases));
    assert.ok(res.data.data.status);
    assert.ok(res.data.data.summary);
  });

  // Test 4: Gemini Explanation Fallback
  await testCase('4. POST /api/v1/explain LLM Endpoint', async () => {
    const res = await axios.post(`${BACKEND_URL}/api/v1/explain`, {
      crop: 'rice',
      detections: {
        pests: [{ name: 'brown plant hopper', confidence: 0.91 }],
        diseases: []
      }
    });

    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.success, true);
    assert.ok(res.data.data);
  });

  console.log('==================================================');
  console.log(` SUMMARY: ${passed} passed, ${failed} failed`);
  console.log('==================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runTests();
}
