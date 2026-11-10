require('dotenv').config();
const bcrypt = require('bcryptjs');
const fs = require('node:fs');
const path = require('node:path');
const { connectDb, disconnectDb } = require('../db');

async function main() {
  const [emailInput, password, ...nameParts] = process.argv.slice(2);
  const email = emailInput?.trim().toLowerCase();
  const fullName = nameParts.join(' ').trim();
  if (!email || !password || password.length < 6 || !fullName) {
    console.error('Cách dùng: node scripts/create-admin.js admin@example.com matkhau "Họ tên"');
    process.exitCode = 1;
    return;
  }
  const { User } = await connectDb();
  try {
    const result = await User.updateOne({ email }, {
      $set: { hoten: fullName, matkhau: await bcrypt.hash(password, 12) },
      $setOnInsert: { email },
    }, { upsert: true, runValidators: true, setDefaultsOnInsert: true });
    const envPath = path.resolve(__dirname, '..', '.env');
    const content = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
    const lines = content.split(/\r?\n/).filter(line => !line.startsWith('ADMIN_EMAIL=') && line.trim());
    fs.writeFileSync(envPath, `${lines.join('\n')}\nADMIN_EMAIL=${email}\n`);
    console.log(result.upsertedCount ? 'Đã tạo admin.' : 'Đã cập nhật admin.');
  } finally {
    await disconnectDb();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
