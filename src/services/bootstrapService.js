const bcrypt = require('bcrypt');

const prisma = require('../config/prisma');
const env = require('../config/env');
const appError = require('../utils/appError');

/**
 * Bootstrap admin account creation
 * Safe, idempotent operation with comprehensive fallbacks
 * @returns {Object} { userCreated: bool, user?: User, skipped?: bool }
 * @throws {AppError} On misconfiguration or email conflict
 */
const bootstrapAdmin = async (overrides = {}) => {
  const isManualBootstrap = Boolean(overrides.confirmCreate);

  // If bootstrap is disabled and this is not a manual setup request, return silently.
  if (env.BOOTSTRAP_ADMIN !== 'true' && !isManualBootstrap) {
    return { skipped: true };
  }

  const name = (overrides.name || env.BOOTSTRAP_ADMIN_NAME || '').trim();
  const email = (overrides.email || env.BOOTSTRAP_ADMIN_EMAIL || '').toLowerCase();
  const password = overrides.password || env.BOOTSTRAP_ADMIN_PASSWORD;

  if (isManualBootstrap && overrides.confirmCreate !== true) {
    throw new appError('Manual bootstrap requires confirmCreate: true', 400, 'CONFIRMATION_REQUIRED');
  }

  // Validate all required env vars present
  if (!name || !email || !password) {
    throw new appError(
      'BOOTSTRAP_ADMIN_NAME, BOOTSTRAP_ADMIN_EMAIL, and BOOTSTRAP_ADMIN_PASSWORD are required.',
      400,
      'BOOTSTRAP_CONFIG_ERROR'
    );
  }

  // Validate password strength
  if (password.length < 8) {
    throw new appError(
      'Bootstrap admin password must be at least 8 characters',
      400,
      'INVALID_PASSWORD'
    );
  }

  // Check if admin already exists (idempotent)
  const existingAdmin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });

  if (existingAdmin) {
    return { skipped: true, message: 'Admin already exists' };
  }

  if (env.BOOTSTRAP_ADMIN !== 'true' && !isManualBootstrap) {
    return { skipped: true };
  }

  // Check if email conflicts with existing non-admin user (safety check)
  const existingUserWithEmail = await prisma.user.findUnique({
    where: { email }
  });

  if (existingUserWithEmail) {
    throw new appError(
      'Bootstrap admin email already exists with a non-admin account. Resolve manually to prevent unsafe privilege changes.',
      409,
      'EMAIL_CONFLICT'
    );
  }

  // Hash password and create admin
  const passwordHash = await bcrypt.hash(password, 12);

  const user = await prisma.user.create({
    data: {
      name,
      email,
      passwordHash,
      role: 'ADMIN',
      isActive: true
    }
  });

  console.log('Bootstrap admin account created.');

  return {
    userCreated: true,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    }
  };
};

module.exports = {
  bootstrapAdmin
};
