const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const bcrypt = require('bcryptjs');
const { MongoMemoryServer } = require('mongodb-memory-server-core');
const { connectDb, disconnectDb } = require('../db');
const { createApp } = require('../index');

test('Mongoose API supports admin login, user CRUD, and avatar round trip', async () => {
  const mongo = await MongoMemoryServer.create({
    binary: { downloadDir: path.resolve(__dirname, '..', '.mongodb-binaries') },
    instance: { storageEngine: 'wiredTiger' },
  });
  let server;
  try {
    process.env.MONGODB_URI = mongo.getUri();
    process.env.MONGODB_DB = 'giuaki2_mongoose_test';
    const { User } = await connectDb();
    const admin = await User.create({
      email: 'admin@example.com', fullName: 'Admin', role: 'admin',
      passwordHash: await bcrypt.hash('test-password', 4),
    });
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
      email: 'admin@example.com', password: 'wrong-password',
    })).status, 401);
    const login = await request('/login', 'POST', {
      email: 'admin@example.com', password: 'test-password',
    });
    assert.equal(login.status, 200);
    token = (await login.json()).token;

    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j4p8AAAAASUVORK5CYII=', 'base64');
    const draft = {
      email: 'bao@example.com', fullName: 'Nguyễn Bảo', password: 'user-password',
      avatarBase64: png.toString('base64'), avatarContentType: 'image/png',
    };
    const created = await request('/users', 'POST', draft);
    assert.equal(created.status, 201);
    const id = (await created.json()).user.id;
    assert.equal((await request('/users', 'POST', draft)).status, 409);

    const listed = await (await request('/users')).json();
    const user = listed.users.find(record => record.id === id);
    assert.equal(user.fullName, 'Nguyễn Bảo');
    assert.equal(user.hasAvatar, true);
    assert.equal(Object.hasOwn(user, 'passwordHash'), false);
    assert.equal(Object.hasOwn(user, 'avatar'), false);
    const defaultSelection = await User.findById(id);
    assert.equal(defaultSelection.passwordHash, undefined);
    assert.equal(defaultSelection.avatar, undefined);
    const stored = await User.findById(id).select('+passwordHash');
    assert.ok(await bcrypt.compare('user-password', stored.passwordHash));

    const image = await request(`/users/${id}/avatar`);
    assert.equal(image.headers.get('content-type'), 'image/png');
    assert.deepEqual(Buffer.from(await image.arrayBuffer()), png);

    const updated = await request(`/users/${id}`, 'PUT', {
      email: 'bao.updated@example.com', fullName: 'Bảo cập nhật',
    });
    assert.equal(updated.status, 200);
    const unchangedPassword = await User.findById(id).select('+passwordHash');
    assert.ok(await bcrypt.compare('user-password', unchangedPassword.passwordHash));
    assert.equal(unchangedPassword.email, 'bao.updated@example.com');
    assert.equal((await request(`/users/${id}`, 'PUT', {
      email: 'bao.updated@example.com', fullName: 'Bảo cập nhật', password: 'new-password',
    })).status, 200);
    const newPassword = await User.findById(id).select('+passwordHash');
    assert.ok(await bcrypt.compare('new-password', newPassword.passwordHash));

    assert.equal((await request('/users/not-an-id', 'DELETE')).status, 400);
    assert.equal((await request(`/users/${admin._id}`, 'DELETE')).status, 404);
    assert.equal((await request(`/users/${id}`, 'DELETE')).status, 200);
    assert.equal(await User.findById(id), null);
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    await disconnectDb();
    await mongo.stop();
  }
});
