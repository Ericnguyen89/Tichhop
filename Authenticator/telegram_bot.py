import logging
from telegram import Update
from telegram.ext import Updater, CommandHandler, CallbackContext
import pyotp

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Replace 'YOUR_TELEGRAM_BOT_TOKEN' with your actual Telegram bot token
TELEGRAM_BOT_TOKEN = 'YOUR_TELEGRAM_BOT_TOKEN'

# Replace 'YOUR_SECRET_KEY' with your Google Authenticator secret key
# This should be the same key that you used to set up Google Authenticator
SECRET_KEY = 'YOUR_SECRET_KEY'

def start(update: Update, context: CallbackContext) -> None:
    update.message.reply_text('Hello! Use /code to get your Google Authenticator code.')

def get_code(update: Update, context: CallbackContext) -> None:
    # Generate the current Google Authenticator code
    totp = pyotp.TOTP(SECRET_KEY)
    current_code = totp.now()
    update.message.reply_text(f'Your Google Authenticator code is: {current_code}')

def main() -> None:
    updater = Updater(TELEGRAM_BOT_TOKEN)

    dispatcher = updater.dispatcher

    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CommandHandler("code", get_code))

    updater.start_polling()

    updater.idle()

if __name__ == '__main__':
    main()
