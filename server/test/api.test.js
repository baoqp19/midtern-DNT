const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const bcrypt = require('bcryptjs');
const fs = require('node:fs/promises');
const { promisify } = require('node:util');
const execFile = promisify(require('node:child_process').execFile);
const { MongoMemoryServer } = require('mongodb-memory-server-core');
const { connectDb, disconnectDb } = require('../db');
const { createApp } = require('../index');

test('Four-field database supports login, CRUD, images, and import/export', async () => {
  const mongo = await MongoMemoryServer.create({
    binary: { downloadDir: path.resolve(__dirname, '..', '.mongodb-binaries') },
    instance: { storageEngine: 'wiredTiger' },
  });
  let server;
  try {
    process.env.MONGODB_URI = mongo.getUri();
    process.env.MONGODB_DB = 'giuaki2_mongoose_test';
    const { User } = await connectDb();
    const app = createApp(User, 'test-secret-for-mongoose-api-32-characters');
    server = await new Promise(resolve => {
      const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
    });
    const base = `http://127.0.0.1:${server.address().port}/api`;
    let token;
    const request = async (route, method = 'GET', body) => fetch(`${base}${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });

    assert.equal((await request('/users')).status, 401);
    assert.equal((await request('/login', 'POST', {
      taikhoan: 'admin', matkhau: 'wrong-password',
    })).status, 401);
    const login = await request('/login', 'POST', {
      taikhoan: 'admin', matkhau: 'admin123',
    });
    assert.equal(login.status, 200);
    token = (await login.json()).token;
    assert.equal(await User.countDocuments(), 0, 'Admin login must not create a database record');
    assert.deepEqual((await (await request('/users')).json()).users, []);

    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j4p8AAAAASUVORK5CYII=', 'base64');
    const draft = {
      email: 'bao@example.com', hoten: 'Nguyễn Bảo', matkhau: 'user-password',
      hinhanh: `data:image/png;base64,${png.toString('base64')}`,
    };
    const created = await request('/users', 'POST', draft);
    assert.equal(created.status, 201);
    const id = (await created.json()).user._id;
    assert.equal((await request('/login', 'POST', {
      taikhoan: 'bao@example.com', matkhau: 'user-password',
    })).status, 401, 'Managed users cannot log in as admin');
    assert.equal((await request('/users', 'POST', draft)).status, 409);

    const listed = await (await request('/users')).json();
    const user = listed.users.find(record => record._id === id);
    assert.equal(user.hoten, 'Nguyễn Bảo');
    assert.equal(user.hinhanh, draft.hinhanh);
    assert.equal(Object.hasOwn(user, 'matkhau'), false);
    const defaultSelection = await User.findById(id);
    assert.equal(defaultSelection.matkhau, undefined);
    const stored = await User.findById(id).select('+matkhau');
    assert.ok(await bcrypt.compare('user-password', stored.matkhau));
    const raw = await User.collection.findOne({ _id: stored._id });
    assert.deepEqual(Object.keys(raw).sort(), ['_id', 'email', 'hinhanh', 'hoten', 'matkhau'].sort());
    assert.deepEqual(Buffer.from(raw.hinhanh.split(',')[1], 'base64'), png);
    assert.equal((await request('/users', 'POST', { ...draft, email: 'extra@example.com', role: 'user' })).status, 400);

    const updated = await request(`/users/${id}`, 'PUT', {
      email: 'bao.updated@example.com', hoten: 'Bảo cập nhật',
    });
    assert.equal(updated.status, 200);
    const unchangedPassword = await User.findById(id).select('+matkhau');
    assert.ok(await bcrypt.compare('user-password', unchangedPassword.matkhau));
    assert.equal(unchangedPassword.email, 'bao.updated@example.com');
    assert.equal((await request(`/users/${id}`, 'PUT', {
      email: 'bao.updated@example.com', hoten: 'Bảo cập nhật', matkhau: 'new-password',
    })).status, 200);
    const newPassword = await User.findById(id).select('+matkhau');
    assert.ok(await bcrypt.compare('new-password', newPassword.matkhau));

    assert.equal((await request('/users/not-an-id', 'DELETE')).status, 400);
    assert.equal((await request(`/users/${id}`, 'DELETE')).status, 200);
    assert.equal(await User.findById(id), null);
    assert.equal(await User.countDocuments(), 0);
    assert.equal((await request('/login', 'POST', {
      taikhoan: 'admin', matkhau: 'admin123',
    })).status, 200, 'Admin must still log in after all managed users are deleted');

    const exportedFile = path.resolve(__dirname, 'users-export.test.json');
    try {
      await execFile(process.execPath, [path.resolve(__dirname, '..', 'scripts', 'database.js'), 'import']);
      await execFile(process.execPath, [path.resolve(__dirname, '..', 'scripts', 'database.js'), 'export', exportedFile]);
      const exported = JSON.parse(await fs.readFile(exportedFile, 'utf8'));
      assert.equal(exported.length, 2);
      for (const row of exported) {
        assert.deepEqual(Object.keys(row).sort(), ['email', 'matkhau', 'hoten', 'hinhanh'].sort());
      }
      assert.ok(exported.some(row => row.hinhanh.startsWith('data:image/png;base64,')));
    } finally {
      await fs.rm(exportedFile, { force: true });
    }
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    await disconnectDb();
    await mongo.stop();
  }
});
