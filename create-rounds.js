// Create test rounds via Firebase Functions
const https = require('https');

const data = JSON.stringify({
  roomIds: ['rookie', 'amateur', 'pro'],
  duration: 900, // 15 minutes
  offset: 30 // start in 30 seconds
});

const options = {
  hostname: 'us-central1-coinnewsextra-tv.cloudfunctions.net',
  port: 443,
  path: '/createTestRounds',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

console.log('🎮 Creating test rounds...');
console.log('Request options:', options);
console.log('Request data:', data);

const req = https.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);

  let responseData = '';
  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log('Response:', responseData);
    try {
      const result = JSON.parse(responseData);
      console.log('✅ Success:', result);
    } catch (e) {
      console.log('Response (raw):', responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
});

req.write(data);
req.end();
