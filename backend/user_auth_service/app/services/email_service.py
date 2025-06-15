import os
import logging
from datetime import datetime
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

SENDGRID_API_KEY = os.getenv("EMAIL_API_KEY")
FROM_EMAIL = os.getenv("EMAIL_FROM_EMAIL")
APP_BASE_URL = os.getenv("APP_BASE_URL", "http://localhost:8000") # CRITICAL: Base URL for constructing verification links

logger = logging.getLogger(__name__)

def send_account_verification_email(to_email: str, user_name: str, verification_token: str):
    """
    Sends an account verification email to the user.
    The verification token does not expire.
    """
    if not SENDGRID_API_KEY:
        logger.error("SendGrid API key not set - cannot send verification emails.")
        return False
    if not FROM_EMAIL:
        logger.error("From email not set - cannot send verification emails.")
        return False
    if not APP_BASE_URL: # Ensure this is configured
        logger.error("APP_BASE_URL environment variable is not set. Cannot construct verification link.")
        return False

    # Construct the verification link. Ensure your auth service is accessible at APP_BASE_URL
    # and that the endpoint /api/auth/verify-email exists.
    verification_link = f"{APP_BASE_URL}/api/auth/verify-email?token={verification_token}"

    email_content = f"""
    <html>
    <head>
        <style>
            body {{ font-family: 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }}
            .email-container {{ max-width: 600px; margin: 40px auto; padding: 30px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }}
            .header {{ text-align: center; padding-bottom: 20px; border-bottom: 1px solid #eeeeee; }}
            .header h1 {{ color: #333333; margin:0; font-size: 24px; }}
            .content p {{ font-size: 16px; color: #555555; margin-bottom: 20px; }}
            .button-container {{ text-align: center; margin: 30px 0; }}
            .button {{ display: inline-block; background-color: #5DADE2; color: white !important; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px; }}
            .link {{ color: #5DADE2; text-decoration: none; }}
            .footer {{ text-align: center; margin-top: 30px; font-size: 12px; color: #999999; }}
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <h1>Welcome to Resellio, {user_name}!</h1>
            </div>
            <div class="content">
                <p>Thank you for registering. To complete your Resellio account setup, please verify your email address by clicking the button below:</p>
                <div class="button-container">
                    <a href="{verification_link}" class="button">Verify Email Address</a>
                </div>
                <p>If you cannot click the button, please copy and paste the following link into your browser's address bar:</p>
                <p><a href="{verification_link}" class="link">{verification_link}</a></p>
                <p>If you did not create an account with Resellio, you can safely ignore this email.</p>
            </div>
            <div class="footer">
                <p>© {datetime.now().year} Resellio. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

    message = Mail(
        from_email=FROM_EMAIL,
        to_emails=to_email,
        subject="Activate Your Resellio Account",
        html_content=email_content
    )

    try:
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        logger.info(f"Account verification email sent to {to_email}, status code: {response.status_code}")
        return response.status_code >= 200 and response.status_code < 300
    except Exception as e:
        logger.error(f"Failed to send account verification email to {to_email}: {str(e)}", exc_info=True)
        return False