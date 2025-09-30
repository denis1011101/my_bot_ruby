[![CI](https://github.com/denis1011101/my_bot_ruby/actions/workflows/CI.yml/badge.svg)](https://github.com/denis1011101/my_bot_ruby/actions/workflows/CI.yml)

This is my pets project for make life little bit easy!

## Run

```bash
make start
```

## Debug mode

```bash
FORCE_SEND=1 make start
```
or repo settings:
```
Name: FORCE_SEND
Value: true
```

## Old information for deploy:

crontab -e:

*/10 * * * * /bin/bash -l -c 'cd /home/my_bot_ruby && '\''./start.sh'\'''


fix: The file uses Windows line endings (\r\n). Run dos2unix or similar to fix it.

sed -i 's/\r//g' start.sh
