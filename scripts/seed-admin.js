process.env.BOOTSTRAP_ADMIN = 'true';

const { bootstrapAdmin } = require('../src/services/bootstrapService');
const prisma = require('../src/config/prisma');

const run = async () => {
  try {
    const result = await bootstrapAdmin();
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
};

run();