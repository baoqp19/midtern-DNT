require('dotenv').config();
const path = require('node:path');
const fs = require('node:fs');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { rateLimit } = require('express-rate-limit');
const mongoose = require('mongoose');
const { connectDb, disconnectDb } = require('./db');
const adminAccount = require('./admin-account');

function validateSecret(secret) {
  if (!secret || secret.length < 32) {
    throw new Error('JWT_SECRET phải có ít nhất 32 ký tự trong server/.env');
  }
  return secret;
}

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
function validateBody(body, creating) {
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  if (Object.keys(body).some(key => !['email', 'matkhau', 'hoten', 'hinhanh'].includes(key))) {
    throw httpError(400, 'Chỉ nhận email, matkhau, hoten, hinhanh.');
  }
  const hoten = typeof body.hoten === 'string' ? body.hoten.trim() : '';
  const matkhau = body.matkhau;
  if (!emailPattern.test(email) || email.length > 254) throw httpError(400, 'Email không hợp lệ.');
  if (!hoten || hoten.length > 120) throw httpError(400, 'Họ tên không hợp lệ.');
  if (creating || matkhau !== undefined) {
    if (typeof matkhau !== 'string' || matkhau.length < 6) {
      throw httpError(400, 'Mật khẩu cần ít nhất 6 ký tự.');
    }
  }
  return { email, hoten, matkhau };
}

function httpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function idFrom(request) {
  if (!mongoose.isObjectIdOrHexString(request.params.id)) {
    throw httpError(400, 'ID người dùng không hợp lệ.');
  }
  return request.params.id;
}

function serialize(user) {
  return {
    _id: user._id.toString(),
    email: user.email,
    hoten: user.hoten,
    hinhanh: user.hinhanh || '',
  };
}

function imageMatches(contentType, bytes) {
  if (contentType === 'image/png') return bytes.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex'));
  if (contentType === 'image/jpeg') return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  if (contentType === 'image/gif') return bytes.subarray(0, 6).toString() === 'GIF87a' || bytes.subarray(0, 6).toString() === 'GIF89a';
  if (contentType === 'image/webp') return bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP';
  return false;
}

function validatedImage(body) {
  if (body.hinhanh === undefined) return {};
  if (body.hinhanh === '') return { hinhanh: '' };
  const match = typeof body.hinhanh === 'string'
    && /^data:(image\/(?:png|jpeg|gif|webp));base64,([A-Za-z0-9+/]+={0,2})$/.exec(body.hinhanh);
  if (!match) {
    throw httpError(400, 'Dữ liệu ảnh không hợp lệ.');
  }
  const [, contentType, encoded] = match;
  const avatar = Buffer.from(encoded, 'base64');
  if (!avatar.length || avatar.length > 5 * 1024 * 1024 || !imageMatches(contentType, avatar)) {
    throw httpError(400, 'Ảnh phải là JPEG, PNG, GIF hoặc WebP hợp lệ và không quá 5 MB.');
  }
  return { hinhanh: body.hinhanh };
}

function createApp(User, secret) {
  validateSecret(secret);
  const app = express();
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '7mb' }));

  async function adminOnly(req, res, next) {
    try {
      const match = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (!match) throw httpError(401, 'Vui lòng đăng nhập.');
      const payload = jwt.verify(match[1], secret, {
        algorithms: ['HS256'], issuer: 'giuaki2-admin', audience: 'giuaki2-api',
      });
      if (payload.sub !== 'fixed-admin' || payload.scope !== 'admin') {
        throw httpError(403, 'Cần tài khoản admin.');
      }
      next();
    } catch (error) {
      next(error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError'
        ? httpError(401, 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.') : error);
    }
  }

  app.post('/api/login', rateLimit({ windowMs: 15 * 60 * 1000, limit: 10 }), async (req, res, next) => {
    try {
      const username = typeof req.body.taikhoan === 'string' ? req.body.taikhoan.trim() : '';
      const matkhau = req.body.matkhau;
      if (username !== adminAccount.username || typeof matkhau !== 'string'
          || !await bcrypt.compare(matkhau, adminAccount.passwordHash)) {
        throw httpError(401, 'Tài khoản hoặc mật khẩu không đúng.');
      }
      const token = jwt.sign({ scope: 'admin' }, secret, {
        subject: 'fixed-admin', expiresIn: '8h', algorithm: 'HS256',
        issuer: 'giuaki2-admin', audience: 'giuaki2-api',
      });
      res.json({ token });
    } catch (error) { next(error); }
  });

  app.get('/api/users', adminOnly, async (req, res, next) => {
    try {
      const records = await User.find().sort({ hoten: 1 }).lean();
      res.json({ users: records.map(serialize) });
    } catch (error) { next(error); }
  });

  app.post('/api/users', adminOnly, async (req, res, next) => {
    try {
      const { email, hoten, matkhau } = validateBody(req.body, true);
      const user = await User.create({
        email, hoten, matkhau: await bcrypt.hash(matkhau, 12), ...validatedImage(req.body),
      });
      res.status(201).json({ user: serialize(user) });
    } catch (error) { next(error); }
  });

  app.put('/api/users/:id', adminOnly, async (req, res, next) => {
    try {
      const id = idFrom(req);
      const { email, hoten, matkhau } = validateBody(req.body, false);
      const update = { email, hoten, ...validatedImage(req.body) };
      if (matkhau !== undefined) update.matkhau = await bcrypt.hash(matkhau, 12);
      const result = await User.updateOne({ _id: id }, { $set: update }, { runValidators: true });
      if (!result.matchedCount) throw httpError(404, 'Không tìm thấy người dùng có thể sửa.');
      res.json({ ok: true });
    } catch (error) { next(error); }
  });

  app.delete('/api/users/:id', adminOnly, async (req, res, next) => {
    try {
      const id = idFrom(req);
      const result = await User.deleteOne({ _id: id });
      if (!result.deletedCount) throw httpError(404, 'Không tìm thấy người dùng có thể xóa.');
      res.json({ ok: true });
    } catch (error) { next(error); }
  });

  app.use('/api', (req, res) => res.status(404).json({ error: 'API không tồn tại.' }));

  const webRoot = path.resolve(__dirname, '..', 'build', 'web');
  if (fs.existsSync(path.join(webRoot, 'index.html'))) {
    app.use(express.static(webRoot));
    app.get('/{*splat}', (req, res) => res.sendFile(path.join(webRoot, 'index.html')));
  }

  app.use((error, req, res, next) => {
    if (error.code === 11000) return res.status(409).json({ error: 'Email đã được sử dụng.' });
    if (error.name === 'ValidationError' || error.name === 'CastError') {
      return res.status(400).json({ error: 'Dữ liệu người dùng không hợp lệ.' });
    }
    if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Phiên đăng nhập không hợp lệ.' });
    }
    if (error.type === 'entity.too.large') return res.status(413).json({ error: 'Ảnh vượt quá 5 MB.' });
    if (!error.status || error.status >= 500) console.error(error);
    res.status(error.status || 500).json({ error: error.status ? error.message : 'Lỗi máy chủ.' });
  });

  return app;
}

async function start() {
  const secret = validateSecret(process.env.JWT_SECRET);
  const { connection, User } = await connectDb();
  console.log(`Mongoose đã kết nối ${connection.host}, database: ${connection.name}`);
  const app = createApp(User, secret);
  const port = Number(process.env.PORT || 3000);
  const server = app.listen(port, () => console.log(`API MongoDB đang chạy tại http://localhost:${port}`));
  const shutdown = async () => {
    server.close();
    await disconnectDb();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

if (require.main === module) {
  start().catch((error) => { console.error(error.message); process.exitCode = 1; });
}

module.exports = { createApp, start };
