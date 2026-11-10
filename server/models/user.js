const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
    maxlength: 254,
    match: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    unique: true,
  },
  matkhau: { type: String, required: true, select: false },
  hoten: { type: String, required: true, trim: true, maxlength: 120 },
  hinhanh: { type: String, default: '', maxlength: 7 * 1024 * 1024 },
}, {
  collection: 'users',
  versionKey: false,
  strict: 'throw',
  bufferCommands: false,
});

module.exports = mongoose.model('User', userSchema);
