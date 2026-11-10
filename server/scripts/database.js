require('dotenv').config();
const fs = require('node:fs/promises');
const path = require('node:path');
const { connectDb, disconnectDb } = require('../db');

async function main() {
  const mode = process.argv[2];
  if (!['import', 'export'].includes(mode)) throw new Error('Dùng: node scripts/database.js import|export [file.json]');
  const file = path.resolve(process.argv[3] || path.join(__dirname, '..', '..', 'database', 'users.json'));
  const { User } = await connectDb();
  try {
    if (mode === 'export') {
      const users = await User.find().select('+matkhau').lean();
      const rows = users.map(({ email, matkhau, hoten, hinhanh }) => ({ email, matkhau, hoten, hinhanh: hinhanh || '' }));
      await fs.mkdir(path.dirname(file), { recursive: true });
      await fs.writeFile(file, `${JSON.stringify(rows, null, 2)}\n`);
      console.log(`Đã xuất ${rows.length} người dùng: ${file}`);
    } else {
      const rows = JSON.parse(await fs.readFile(file, 'utf8'));
      if (!Array.isArray(rows)) throw new Error('File CSDL phải là một mảng JSON.');
      for (const row of rows) {
        if (Object.keys(row).sort().join(',') !== 'email,hinhanh,hoten,matkhau') {
          throw new Error('Mỗi người dùng phải có đúng email, matkhau, hoten, hinhanh.');
        }
        await new User(row).validate();
        if (!/^\$2[aby]\$/.test(row.matkhau)) throw new Error('matkhau trong file nhập phải là mật khẩu đã băm.');
      }
      for (const row of rows) {
        await User.updateOne({ email: row.email.trim().toLowerCase() }, { $set: row }, { upsert: true, runValidators: true });
      }
      console.log(`Đã nhập ${rows.length} người dùng.`);
    }
  } finally {
    await disconnectDb();
  }
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
