const fs = require('node:fs');
const path = require('node:path');
const { MongoMemoryServer } = require('mongodb-memory-server-core');

async function main() {
  const root = path.resolve(__dirname, '..');
  const dbPath = path.join(root, '.mongodb-data');
  const downloadDir = path.join(root, '.mongodb-binaries');
  fs.mkdirSync(dbPath, { recursive: true });
  fs.mkdirSync(downloadDir, { recursive: true });
  const mongo = await MongoMemoryServer.create({
    instance: {
      port: 27017,
      dbPath,
      storageEngine: 'wiredTiger',
      ip: '127.0.0.1',
    },
    binary: { downloadDir },
  });
  console.log(`MongoDB cục bộ đang chạy: ${mongo.getUri()}`);
  const stop = async () => {
    await mongo.stop();
    process.exit(0);
  };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
