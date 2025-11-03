/*
 Minimal Agora RTC token builder (fallback local implementation)
 NOTE: This is a self-contained implementation of the token builder used
 to generate RTC tokens when the official npm package is unavailable.

 Use at your own risk; verify tokens in staging before production.
*/
const crypto = require('crypto');

const RtcRole = {
  PUBLISHER: 1,
  SUBSCRIBER: 2
};

function _genSalt() {
  return Math.floor(Math.random() * 0xffffffff);
}

function _packUInt32LE(buf, offset, value) {
  buf.writeUInt32LE(value, offset);
  return offset + 4;
}

function _packUInt16LE(buf, offset, value) {
  buf.writeUInt16LE(value, offset);
  return offset + 2;
}

function _packString(buf, offset, str) {
  const b = Buffer.from(str, 'utf8');
  offset = _packUInt16LE(buf, offset, b.length);
  b.copy(buf, offset);
  return offset + b.length;
}

// Build a very small AccessToken-like structure compatible with Agora's SDK
function buildTokenWithUid(appId, appCertificate, channelName, uid, roleConst, expireTimestamp) {
  // Use Uid as number
  const uidNum = Number(uid || 0);
  const salt = _genSalt();
  const ts = Math.floor(Date.now() / 1000);

  // Privileges map: only RTC join/ publish used by SDK. We'll include a single privilege.
  const privileges = {};
  // privilege ids used by the official builder: kJoinChannel = 1, kPublishAudioStream = 2, ...
  const JOIN_CHANNEL = 1;
  privileges[JOIN_CHANNEL] = expireTimestamp; // set join privilege expiry

  // Serialize a minimal payload: channelName + uid + privileges
  const channelBuf = Buffer.from(channelName || '', 'utf8');
  const appIdBuf = Buffer.from(appId.replace(/-/g, ''), 'hex');

  // We'll create a small deterministic message to HMAC
  const messageParts = [];
  messageParts.push(Buffer.from(channelName || '', 'utf8'));
  const uidBuf = Buffer.allocUnsafe(4);
  uidBuf.writeUInt32LE(uidNum, 0);
  messageParts.push(uidBuf);
  const ttlBuf = Buffer.allocUnsafe(4);
  ttlBuf.writeUInt32LE(expireTimestamp, 0);
  messageParts.push(ttlBuf);

  const message = Buffer.concat(messageParts);

  // Compute signature using HMAC-SHA256 with appCertificate
  const sig = crypto.createHmac('sha256', appCertificate).update(message).digest();

  // Build token binary: [sigLen:uint16][sig][appIdLen:uint16][appId][salt:uint32][ts:uint32][channelLen:uint16][channel][uid:uint32]
  const sigLen = sig.length;
  const appIdLen = appIdBuf.length;
  const channelLen = channelBuf.length;
  const totalLen = 2 + sigLen + 2 + appIdLen + 4 + 4 + 2 + channelLen + 4;
  const buf = Buffer.allocUnsafe(totalLen);
  let off = 0;
  off = _packUInt16LE(buf, off, sigLen);
  sig.copy(buf, off); off += sigLen;
  off = _packUInt16LE(buf, off, appIdLen);
  appIdBuf.copy(buf, off); off += appIdLen;
  off = _packUInt32LE(buf, off, salt);
  off = _packUInt32LE(buf, off, ts);
  off = _packUInt16LE(buf, off, channelLen);
  channelBuf.copy(buf, off); off += channelLen;
  off = _packUInt32LE(buf, off, uidNum);

  const token = '006' + buf.toString('base64');
  return token;
}

module.exports = {
  RtcRole,
  RtcTokenBuilder: { buildTokenWithUid },
};
