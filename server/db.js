const mongoose = require('mongoose');
const User = require('./models/user');

async function connectDb() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong server/.env');
  if (!/^mongodb(?:\+srv)?:\/\//.test(uri)) {
    throw new Error('MONGODB_URI phải bắt đầu bằng mongodb:// hoặc mongodb+srv://.');
  }
  if (/MAT_KHAU_MOI|<password>|<db_password>|YOUR_PASSWORD/.test(uri)) {
    throw new Error('Thay mật khẩu mẫu trong MONGODB_URI bằng mật khẩu database user.');
  }
  try {
    await mongoose.connect(uri, {
      dbName: process.env.MONGODB_DB || 'giuaki2',
      serverSelectionTimeoutMS: 30000,
    });
    await User.init();
    return { connection: mongoose.connection, User };
  } catch (error) {
    await mongoose.disconnect();
    throw error;
  }
}

module.exports = { connectDb, disconnectDb: () => mongoose.disconnect() };
