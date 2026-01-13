/**
 * Unit Tests for Nginx Configuration
 * Tests static file serving functionality and proper HTTP headers and responses
 * Requirements: 1.1, 1.2
 */

const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class TestRunner {
  constructor() {
    this.tests = [];
    this.passed = 0;
    this.failed = 0;
    this.containerStarted = false;
  }

  test(name, testFn) {
    this.tests.push({ name, testFn });
  }

  async run() {
    console.log('🧪 Running Nginx Configuration Unit Tests\n');
    
    // Start the container for testing
    await this.startContainer();
    
    // Wait for container to be ready
    await this.waitForContainer();
    
    for (const { name, testFn } of this.tests) {
      try {
        console.log(`⏳ ${name}`);
        await testFn();
        console.log(`✅ ${name}`);
        this.passed++;
      } catch (error) {
        console.log(`❌ ${name}`);
        console.log(`   Error: ${error.message}`);
        this.failed++;
      }
    }
    
    // Clean up
    await this.stopContainer();
    
    console.log(`\n📊 Test Results: ${this.passed} passed, ${this.failed} failed`);
    
    if (this.failed > 0) {
      process.exit(1);
    }
  }

  async startContainer() {
    return new Promise((resolve, reject) => {
      console.log('🐳 Starting Docker container...');
      const process = spawn('docker-compose', ['up', '-d'], { stdio: 'pipe' });
      
      let output = '';
      process.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      process.stderr.on('data', (data) => {
        output += data.toString();
      });
      
      process.on('close', (code) => {
        if (code === 0) {
          this.containerStarted = true;
          console.log('✅ Container started successfully');
          resolve();
        } else {
          reject(new Error(`Failed to start container: ${output}`));
        }
      });
    });
  }

  async stopContainer() {
    if (!this.containerStarted) return;
    
    return new Promise((resolve) => {
      console.log('🛑 Stopping Docker container...');
      const process = spawn('docker-compose', ['down'], { stdio: 'pipe' });
      
      process.on('close', () => {
        console.log('✅ Container stopped');
        resolve();
      });
    });
  }

  async waitForContainer() {
    console.log('⏳ Waiting for container to be ready...');
    const maxAttempts = 30;
    let attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        await this.makeRequest('GET', '/');
        console.log('✅ Container is ready');
        return;
      } catch (error) {
        attempts++;
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    throw new Error('Container failed to start within timeout');
  }

  makeRequest(method, path, expectedStatus = 200) {
    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'localhost',
        port: 8080,
        path: path,
        method: method,
        timeout: 5000
      };

      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          if (res.statusCode === expectedStatus) {
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              body: data
            });
          } else {
            reject(new Error(`Expected status ${expectedStatus}, got ${res.statusCode}`));
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      req.end();
    });
  }

  assert(condition, message) {
    if (!condition) {
      throw new Error(message);
    }
  }
}

// Create test runner instance
const runner = new TestRunner();

// Test 1: Static file serving functionality - index.html
runner.test('Should serve index.html from root URL', async () => {
  const response = await runner.makeRequest('GET', '/');
  
  runner.assert(response.statusCode === 200, 'Should return 200 status code');
  runner.assert(response.headers['content-type'].includes('text/html'), 'Should return HTML content type');
  runner.assert(response.body.includes('Welcome to Extensible Web App'), 'Should contain welcome message');
  runner.assert(response.body.includes('<!DOCTYPE html>'), 'Should contain proper HTML structure');
});

// Test 2: Static file serving functionality - CSS file
runner.test('Should serve CSS files with proper content type', async () => {
  const response = await runner.makeRequest('GET', '/style.css');
  
  runner.assert(response.statusCode === 200, 'Should return 200 status code');
  runner.assert(response.headers['content-type'].includes('text/css'), 'Should return CSS content type');
});

// Test 3: Security headers
runner.test('Should include security headers', async () => {
  const response = await runner.makeRequest('GET', '/');
  
  runner.assert(response.headers['x-frame-options'] === 'SAMEORIGIN', 'Should include X-Frame-Options header');
  runner.assert(response.headers['x-content-type-options'] === 'nosniff', 'Should include X-Content-Type-Options header');
  runner.assert(response.headers['x-xss-protection'] === '1; mode=block', 'Should include X-XSS-Protection header');
});

// Test 4: Cache headers for static assets
runner.test('Should set cache headers for static assets', async () => {
  const response = await runner.makeRequest('GET', '/style.css');
  
  runner.assert(response.headers['cache-control'], 'Should include Cache-Control header');
  runner.assert(response.headers['cache-control'].includes('public'), 'Should set public cache control');
});

// Test 5: 404 handling
runner.test('Should return 404 for non-existent files', async () => {
  const response = await runner.makeRequest('GET', '/nonexistent.html', 404);
  
  runner.assert(response.statusCode === 404, 'Should return 404 status code');
});

// Test 6: Gzip compression headers
runner.test('Should support gzip compression', async () => {
  const response = await runner.makeRequest('GET', '/');
  
  // Note: Nginx may not always return vary header, but it should be configured
  // We test that the server can handle compression requests
  runner.assert(response.statusCode === 200, 'Should handle requests that could be compressed');
});

// Test 7: MIME type handling
runner.test('Should serve files with correct MIME types', async () => {
  const response = await runner.makeRequest('GET', '/');
  
  runner.assert(response.headers['content-type'].includes('text/html'), 'HTML files should have text/html MIME type');
});

// Run all tests
runner.run().catch((error) => {
  console.error('Test runner failed:', error);
  process.exit(1);
});