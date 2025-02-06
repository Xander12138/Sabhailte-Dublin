import logging as basic_log
import os

import uvicorn
from absl import app, logging


class CustomFormatter(basic_log.Formatter):
    LEVEL_COLORS = [
        (basic_log.DEBUG, '\x1b[40;1m'),
        (basic_log.INFO, '\x1b[34;1m'),
        (basic_log.WARNING, '\x1b[33;1m'),
        (basic_log.ERROR, '\x1b[31m'),
        (basic_log.FATAL, '\x1b[41m'),
    ]
    FORMATS = {
        level:
            basic_log.Formatter(
                f'\x1b[30;1m%(asctime)s\x1b[0m {color}%(levelname)-8s\x1b[0m \
\x1b[35m%(filename)s:%(lineno)s\x1b[0m %(message)s', '%Y-%m-%d %H:%M:%S') for level, color in LEVEL_COLORS
    }

    def format(self, record):
        formatter = self.FORMATS.get(record.levelno)
        if formatter is None:
            formatter = self.FORMATS[basic_log.DEBUG]

        # Override the traceback to always print in red
        if record.exc_info:
            text = formatter.formatException(record.exc_info)
            record.exc_text = f'\x1b[31m{text}\x1b[0m'

        output = formatter.format(record)
        # Remove the cache layer
        record.exc_text = None
        return output


def main(argv):
    del argv  # Unused.
    enable_formatter = os.environ.get('ENABLE_FORMATTER', 'False')
    logging.info(f'Enable formatter: {enable_formatter}')
    if enable_formatter and enable_formatter == 'True':
        logging.get_absl_handler().setFormatter(CustomFormatter())

    uvicorn.run(
        'api_router:app',
        host='0.0.0.0',
        port=8001,
        log_level='debug',
        reload=True,
        # To pass client real ip through proxies (AWS app runner and/or nginx)
        proxy_headers=True,
        forwarded_allow_ips='*',
    )


if __name__ == '__main__':
    app.run(main)
