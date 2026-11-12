const router = require('express').Router();
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const BUCKET = 'avatars';

const EXT = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' };

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, cb) =>
    EXT[file.mimetype] ? cb(null, true) : cb(new Error('INVALID_IMAGE')),
});

function handleUpload(req, res, next) {
  upload.single('profile_picture')(req, res, (err) => {
    if (!err) return next();
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'Image must be 2MB or smaller' });
    }
    if (err.message === 'INVALID_IMAGE') {
      return res.status(400).json({ message: 'Only JPG, PNG or WebP images are allowed' });
    }
    console.error(err);
    res.status(400).json({ message: 'Upload failed' });
  });
}

router.get('/', requireAuth, requireRole('student'), async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, name, email, role, phone, profile_picture FROM users WHERE id = $1',
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ message: 'User not found' });
    res.json({ user: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.patch('/', requireAuth, requireRole('student'), handleUpload, async (req, res) => {
  const fail = (status, message) => res.status(status).json({ message });

  try {
    const { name, email, phone, current_password, new_password } = req.body;

    const { rows } = await db.query(
      'SELECT id, email, password_hash, profile_picture FROM users WHERE id = $1',
      [req.user.id]
    );
    const user = rows[0];
    if (!user) return fail(404, 'User not found');

    const sets = [];
    const values = [];
    const add = (col, val) => {
      values.push(val);
      sets.push(`${col} = $${values.length}`);
    };

    // name (username)
    if (name !== undefined) {
      if (typeof name !== 'string' || !name.trim()) return fail(400, 'Name cannot be empty');
      add('name', name.trim());
    }

    // email
    let newEmail;
    if (email !== undefined) {
      newEmail = typeof email === 'string' ? email.toLowerCase().trim() : '';
      if (!/^\S+@\S+\.\S+$/.test(newEmail)) return fail(400, 'Invalid email address');
      if (newEmail !== user.email) add('email', newEmail);
    }

    // phone 
    if (phone !== undefined) {
      const p = typeof phone === 'string' ? phone.trim() : '';
      if (p && !/^\+?[0-9\s-]{7,15}$/.test(p)) return fail(400, 'Invalid mobile number');
      add('phone', p || null);
    }

    // password
    if (new_password !== undefined) {
      if (typeof new_password !== 'string' || new_password.length < 6) {
        return fail(400, 'New password must be at least 6 characters');
      }
    }

    
    const emailChanging = newEmail !== undefined && newEmail !== user.email;
    if (emailChanging || new_password !== undefined) {
      if (typeof current_password !== 'string' || !current_password) {
        return fail(400, 'Current password is required to change email or password');
      }
      const ok = await bcrypt.compare(current_password, user.password_hash);
      if (!ok) return fail(401, 'Current password is incorrect');
    }
    if (new_password !== undefined) {
      add('password_hash', await bcrypt.hash(new_password, 10));
    }

    // profile picture
    let uploadedPath;
    if (req.file) {
      uploadedPath = `${req.user.id}/${Date.now()}${EXT[req.file.mimetype]}`;
      const { error } = await supabase.storage
        .from(BUCKET)
        .upload(uploadedPath, req.file.buffer, { contentType: req.file.mimetype });
      if (error) {
        console.error(error);
        return fail(500, 'Could not upload image');
      }
      add('profile_picture', supabase.storage.from(BUCKET).getPublicUrl(uploadedPath).data.publicUrl);
    }

    if (sets.length === 0) return fail(400, 'Nothing to update');

    values.push(req.user.id);
    let result;
    try {
      result = await db.query(
        `UPDATE users SET ${sets.join(', ')} WHERE id = $${values.length}
        RETURNING id, name, email, role, phone, profile_picture`,
        values
      );
    } catch (e) {
      if (uploadedPath) await supabase.storage.from(BUCKET).remove([uploadedPath]);
      throw e; 
    }

    // delete the previous picture
    if (uploadedPath && user.profile_picture) {
      const old = user.profile_picture.split(`/${BUCKET}/`)[1];
      if (old) supabase.storage.from(BUCKET).remove([old]).catch(() => {});
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') return fail(409, 'Email already registered');
    console.error(err);
    fail(500, 'Server error');
  }
});

module.exports = router;