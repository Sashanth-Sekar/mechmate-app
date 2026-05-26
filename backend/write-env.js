const fs = require('fs');

// Read the service account JSON
const json = JSON.parse(fs.readFileSync('firebase-service-account.json', 'utf8'));
const rawKey = json.private_key;
const clientEmail = json.client_email;

// Replace actual newlines with literal \n (backslash + n) for .env format
const escapedKey = rawKey.replace(/\n/g, '\\n');

console.log('Raw key length:', rawKey.length);
console.log('Has actual newlines:', rawKey.includes('\n'));
console.log('Escaped key length:', escapedKey.length);
console.log('Escaped key starts with:', escapedKey.substring(0, 50));

// Read existing .env
let env = fs.readFileSync('.env', 'utf8');

// Helper to replace a line
function replaceLine(content, prefix, newValue) {
  const lines = content.split('\n');
  let found = false;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith(prefix + '=')) {
      lines[i] = prefix + '=' + newValue;
      found = true;
      break;
    }
  }
  if (!found) {
    lines.push(prefix + '=' + newValue);
  }
  return lines.join('\n');
}

// Update each setting
env = replaceLine(env, 'NODE_ENV', 'production');
env = replaceLine(env, 'FIREBASE_CLIENT_EMAIL', clientEmail);
env = replaceLine(env, 'FIREBASE_PRIVATE_KEY', escapedKey);
env = replaceLine(env, 'FIREBASE_AUTH_DEV_MODE', 'false');
env = replaceLine(env, 'PORT', '4001');

// Write back
fs.writeFileSync('.env', env, 'utf8');
console.log('\n✅ .env updated successfully');
console.log('NODE_ENV=production');
console.log('FIREBASE_CLIENT_EMAIL=' + clientEmail);
console.log('FIREBASE_PRIVATE_KEY length in .env:', escapedKey.length);
console.log('PORT=4001');
