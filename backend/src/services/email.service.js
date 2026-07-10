const nodemailer = require("nodemailer");
const { env } = require("../config/env");
const { logger } = require("../utils/logger");

let transporter = null;

function isSmtpConfigured() {
  return Boolean(env.smtpHost && env.smtpUser);
}

function getTransporter() {
  if (!isSmtpConfigured()) return null;
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.smtpHost,
      port: env.smtpPort,
      secure: env.smtpSecure,
      auth: {
        user: env.smtpUser,
        pass: env.smtpPass,
      },
    });
  }
  return transporter;
}

async function sendEmail({ to, subject, text, html }) {
  if (!to) return;

  const transport = getTransporter();
  if (transport) {
    const info = await transport.sendMail({
      from: env.smtpFrom,
      to,
      subject,
      text,
      html: html || `<p>${String(text).replace(/\n/g, "<br/>")}</p>`,
    });
    logger.info({ to, subject, messageId: info.messageId }, "Email sent via SMTP");
    return;
  }

  logger.info(
    { to, subject, text, hint: "Set SMTP_HOST, SMTP_USER, and SMTP_PASS to send real emails" },
    "Outbound email (not sent — SMTP not configured)"
  );

  if (env.isProduction) {
    throw new Error("Email service is not configured (missing SMTP env vars on the server)");
  }
}

function verificationHtml(code) {
  return `
    <div style="font-family: system-ui, sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1565C0;">Verify your Purchase Journal email</h2>
      <p>Your verification code is:</p>
      <p style="font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #1565C0;">${code}</p>
      <p>This code expires in 24 hours.</p>
      <p style="color: #666;">If you did not create an account, you can ignore this email.</p>
    </div>
  `;
}

function passwordResetHtml(code) {
  return `
    <div style="font-family: system-ui, sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1565C0;">Reset your Purchase Journal password</h2>
      <p>Your password reset code is:</p>
      <p style="font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #1565C0;">${code}</p>
      <p>This code expires in 1 hour.</p>
      <p style="color: #666;">If you did not request a reset, you can ignore this email.</p>
    </div>
  `;
}

async function sendVerificationEmail(to, code) {
  await sendEmail({
    to,
    subject: "Verify your Purchase Journal email",
    text: `Your verification code is ${code}. It expires in 24 hours.\n\nIf you did not create an account, ignore this email.`,
    html: verificationHtml(code),
  });
}

async function sendPasswordResetEmail(to, code) {
  await sendEmail({
    to,
    subject: "Reset your Purchase Journal password",
    text: `Your password reset code is ${code}. It expires in 1 hour.\n\nIf you did not request a reset, ignore this email.`,
    html: passwordResetHtml(code),
  });
}

module.exports = {
  isSmtpConfigured,
  sendEmail,
  sendVerificationEmail,
  sendPasswordResetEmail,
};
