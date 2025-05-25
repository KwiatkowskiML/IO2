# flake8: noqa
import io
import os
import base64
import logging

import qrcode
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, FileName, FileType, ContentId, Attachment, Disposition, FileContent

SENDGRID_API_KEY = os.getenv("EMAIL_API_KEY")
FROM_EMAIL = os.getenv("EMAIL_FROM_EMAIL", "tickets@resellio.com")

logger = logging.getLogger(__name__)


def generate_qr_code(data):
    """Generate a QR code as a base64 encoded PNG image"""
    try:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(data)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")

        # Save to bytes buffer
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")

        # Convert to base64
        qr_base64 = base64.b64encode(buffer.getvalue()).decode("utf-8")
        return qr_base64
    except Exception as e:
        logger.error(f"Failed to generate QR code: {str(e)}")
        return None


def send_ticket_email(
    to_email,
    user_name,
    event_name,
    ticket_id,
    event_date,
    event_time,
    venue,
    seat,
):
    """
    Send beautifully designed ticket confirmation email using SendGrid.

    Args:
        to_email: Recipient's email address
        user_name: Recipient's name
        event_name: Name of the event
        ticket_id: Ticket ID
        event_date: Event date (formatted string)
        event_time: Event time (formatted string)
        venue: Venue name
        seat: Seat number/code

    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    if not SENDGRID_API_KEY:
        logger.error("SendGrid API key not set - cannot send emails")
        return False

    # Generate QR code containing ticket info
    qr_data = f"TICKET:{ticket_id}|EVENT:{event_name}|DATE:{event_date}|TIME:{event_time}|VENUE:{venue}|SEAT:{seat}"
    qr_base64 = generate_qr_code(qr_data)

    # Create HTML email content with improved design
    email_content = f"""
    <html>
    <head>
        <style>
            body {{
                font-family: 'Helvetica Neue', Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 0;
            }}
            .header {{
                background: linear-gradient(135deg, #6e8efb, #a777e3);
                color: white;
                padding: 30px;
                text-align: center;
                border-radius: 8px 8px 0 0;
            }}
            .header h1 {{
                margin: 0;
                font-size: 28px;
                font-weight: 300;
            }}
            .content {{
                padding: 30px;
                background-color: #fff;
                border-left: 1px solid #e0e0e0;
                border-right: 1px solid #e0e0e0;
            }}
            .ticket-container {{
                border: 2px dashed #e0e0e0;
                border-radius: 8px;
                padding: 20px;
                margin: 20px 0;
                background-color: #f9f9f9;
            }}
            .ticket-header {{
                border-bottom: 1px solid #e0e0e0;
                padding-bottom: 15px;
                margin-bottom: 15px;
                font-size: 22px;
                color: #333;
                font-weight: bold;
            }}
            .ticket-row {{
                display: flex;
                margin-bottom: 10px;
            }}
            .ticket-label {{
                font-weight: bold;
                width: 100px;
                color: #666;
            }}
            .ticket-value {{
                flex-grow: 1;
            }}
            .qr-container {{
                text-align: center;
                margin: 30px 0;
            }}
            .qr-code {{
                width: 200px;
                height: 200px;
            }}
            .footer {{
                background-color: #f5f5f5;
                padding: 20px;
                text-align: center;
                font-size: 12px;
                color: #999;
                border-radius: 0 0 8px 8px;
                border: 1px solid #e0e0e0;
                border-top: none;
            }}
            .button {{
                display: inline-block;
                background-color: #6e8efb;
                color: white;
                padding: 12px 24px;
                text-decoration: none;
                border-radius: 4px;
                font-weight: bold;
                margin-top: 15px;
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Your Ticket Confirmation</h1>
        </div>

        <div class="content">
            <p>Dear {user_name},</p>

            <p>Thank you for your purchase! Your ticket for <strong>{event_name}</strong> has been confirmed.</p>

            <div class="ticket-container">
                <div class="ticket-header">{event_name}</div>

                <div class="ticket-row">
                    <div class="ticket-label">Date:</div>
                    <div class="ticket-value">{event_date}</div>
                </div>

                <div class="ticket-row">
                    <div class="ticket-label">Time:</div>
                    <div class="ticket-value">{event_time}</div>
                </div>

                <div class="ticket-row">
                    <div class="ticket-label">Venue:</div>
                    <div class="ticket-value">{venue}</div>
                </div>

                <div class="ticket-row">
                    <div class="ticket-label">Seat:</div>
                    <div class="ticket-value">{seat}</div>
                </div>

                <div class="ticket-row">
                    <div class="ticket-label">Ticket ID:</div>
                    <div class="ticket-value">{ticket_id}</div>
                </div>

                <div class="qr-container">
                    <p><strong>Show this QR code at the entrance</strong></p>
                    <img class="qr-code" src="cid:qrcode" alt="Ticket QR Code">
                </div>
            </div>

            <p>Please save this email and bring it with you to the event. You can also access your tickets anytime from your account.</p>

            <p>We hope you enjoy the event!</p>

            <div style="text-align: center;">
                <a href="https://resellio.com/my-tickets" class="button">View My Tickets</a>
            </div>
        </div>

        <div class="footer">
            <p>© 2025 Resellio. All rights reserved.</p>
            <p>This is an automated message. Please do not reply to this email.</p>
            <p>
                <a href="https://resellio.com/terms">Terms of Service</a> |
                <a href="https://resellio.com/privacy">Privacy Policy</a> |
                <a href="https://resellio.com/contact">Contact Us</a>
            </p>
        </div>
    </body>
    </html>
    """

    message = Mail(
        from_email=FROM_EMAIL, to_emails=to_email, subject=f"Your Ticket for {event_name}", html_content=email_content
    )

    if qr_base64:
        attachment = Attachment()
        attachment.file_content = FileContent(qr_base64)
        attachment.file_name = FileName("qrcode.png")
        attachment.file_type = FileType("image/png")
        attachment.disposition = Disposition("inline")
        attachment.content_id = ContentId("qrcode")
        message.add_attachment(attachment)

    try:
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        status_code = response.status_code
        logger.info(f"Email sent to {to_email}, status code: {status_code}")
        return status_code >= 200 and status_code < 300
    except Exception as e:
        logger.error(f"Failed to send email: {str(e)}")
        return False
