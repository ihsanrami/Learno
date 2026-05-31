"""Send password-reset emails via smtplib (stdlib, no extra package)."""

import asyncio
import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.config import settings

logger = logging.getLogger(__name__)


def _build_email_html(code: str) -> str:
    return f"""
<!DOCTYPE html>
<html>
<body style="font-family:Arial,sans-serif;background:#fff8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:16px;
              padding:32px;border:1px solid #f7cda5;">
    <img src="https://i.imgur.com/placeholder.png" alt="Learno" width="80"
         style="display:block;margin:0 auto 16px;">
    <h2 style="color:#44200b;text-align:center;font-size:22px;margin-bottom:8px;">
      Password Reset Code
    </h2>
    <p style="color:#76310f;text-align:center;font-size:15px;margin-bottom:24px;">
      رمز إعادة تعيين كلمة المرور
    </p>
    <div style="background:#fff3e0;border-radius:12px;padding:24px;text-align:center;
                border:2px dashed #ff8d00;margin-bottom:24px;">
      <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#44200b;">
        {code}
      </span>
    </div>
    <p style="color:#76310f;font-size:13px;text-align:center;margin:0;">
      This code expires in 15 minutes. If you didn't request this, ignore this email.
      <br>
      هذا الرمز صالح لمدة 15 دقيقة. إذا لم تطلب إعادة التعيين، تجاهل هذا البريد.
    </p>
  </div>
</body>
</html>
"""


def _send_sync(to_email: str, code: str) -> bool:
    """Blocking SMTP send — called inside a thread executor."""
    if not settings.SMTP_HOST:
        logger.info("SMTP not configured — skipping email send")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"Learno — Password Reset Code: {code}"
        msg["From"] = settings.SMTP_FROM or settings.SMTP_USER
        msg["To"] = to_email

        msg.attach(MIMEText(_build_email_html(code), "html", "utf-8"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(msg["From"], [to_email], msg.as_string())

        logger.info("Reset email sent to %s", to_email)
        return True
    except Exception as exc:
        logger.warning("Failed to send reset email to %s: %s", to_email, exc)
        return False


async def send_reset_email(to_email: str, code: str) -> bool:
    """Non-blocking wrapper — runs smtplib in a thread pool."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _send_sync, to_email, code)
