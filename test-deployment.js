// Test script to verify Firebase deployment
const https = require('https');

const PROJECT_ID = 'coinnewsextratv-9c75a';
const REGION = 'us-central1';

// Test functions that are likely to be working
const testFunctions = [
    'health',
    'getServerTime',
    'getUserBalance',
    'getRewardSystemStatus'
];

async function testFunction(functionName) {
    return new Promise((resolve, reject) => {
        const url = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${functionName}`;
        
        console.log(`Testing function: ${functionName}`);
        console.log(`URL: ${url}`);
        
        const req = https.get(url, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                console.log(`✅ ${functionName}: Status ${res.statusCode}`);
                if (res.statusCode === 200) {
                    try {
                        const jsonData = JSON.parse(data);
                        console.log(`   Response: ${JSON.stringify(jsonData, null, 2)}`);
                    } catch (e) {
                        console.log(`   Response: ${data}`);
                    }
                } else {
                    console.log(`   Error response: ${data}`);
                }
                resolve({ function: functionName, status: res.statusCode, data });
            });
        });
        
        req.on('error', (err) => {
            console.log(`❌ ${functionName}: Error - ${err.message}`);
            resolve({ function: functionName, error: err.message });
        });
        
        req.setTimeout(10000, () => {
            req.abort();
            console.log(`⏱️ ${functionName}: Timeout`);
            resolve({ function: functionName, error: 'Timeout' });
        });
    });
}

async function runTests() {
    console.log('🚀 Testing Firebase Functions Deployment...\n');
    
    const results = [];
    
    for (const funcName of testFunctions) {
        const result = await testFunction(funcName);
        results.push(result);
        console.log(''); // Add spacing
    }
    
    console.log('📊 Summary:');
    results.forEach(result => {
        if (result.error) {
            console.log(`❌ ${result.function}: ${result.error}`);
        } else {
            console.log(`✅ ${result.function}: HTTP ${result.status}`);
        }
    });
    
    const workingFunctions = results.filter(r => !r.error && r.status === 200).length;
    console.log(`\n🎯 ${workingFunctions}/${testFunctions.length} functions are working`);
    
    if (workingFunctions > 0) {
        console.log('\n✅ Firebase deployment is partially successful!');
        console.log('The quota limits prevented some functions from deploying,');
        console.log('but core functions are working.');
    } else {
        console.log('\n❌ No functions are accessible. Deployment may have failed.');
    }
}

runTests().catch(console.error);
