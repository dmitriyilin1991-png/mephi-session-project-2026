# ============================================================================
# ОПИСАНИЕ: проверка аутентификации на учебной РЕД ОС, без вывода паролей.
# ЧТО ДЕЛАЕТ: задаёт случайные пароли пяти учебным пользователям, проверяет
# passwd и настоящий /bin/login в псевдотерминале, включая запрет кураторов.
# КАК ЗАПУСТИТЬ: sudo python3 verify_auth.py setup|password|login.
# Зависимости: Python 3, pexpect, стандартные passwd/chpasswd/login/runuser.
# ВХОДНЫЕ ФАЙЛЫ: /root/mephi-backups/project-test-passwords.json (режим 0600).
# ВЫХОДНОЙ ФАЙЛ: тот же приватный JSON; stdout содержит только результаты.
# Пароли не передаются через аргументы процессов и не записываются в журнал.
# ============================================================================
import json
import os
import secrets
import string
import subprocess
import sys
from pathlib import Path

import pexpect

PRIVATE = Path('/root/mephi-backups/project-test-passwords.json')
USERS = ['user1', 'user2', 'user3', 'curator1', 'curator2']
ENV = dict(os.environ, LANG='C', LC_ALL='C', TERM='dumb')


def random_password(length=24):
    alphabet = string.ascii_letters + string.digits + '!%+-_'
    while True:
        value = ''.join(secrets.choice(alphabet) for _ in range(length))
        if all(any(c in group for c in value) for group in
               (string.ascii_lowercase, string.ascii_uppercase, string.digits)):
            return value


def save(data):
    descriptor = os.open(PRIVATE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, 'w') as stream:
        json.dump(data, stream)


def setup():
    if PRIVATE.exists():
        raise RuntimeError('private credentials already exist; refusing reset')
    data = {user: random_password() for user in USERS}
    save(data)
    for user, password in data.items():
        result = subprocess.run(['chpasswd'], input=f'{user}:{password}\n',
                                text=True, capture_output=True, env=ENV)
        if result.returncode:
            raise RuntimeError(f'chpasswd failed for {user}; no secrets logged')
        print(f'PASS initial unique password set for {user}', flush=True)


def passwd_session(old):
    child = pexpect.spawn('/usr/sbin/runuser', ['-u', 'user1', '--', '/usr/bin/passwd'],
                          encoding='utf-8', timeout=25, env=ENV, echo=False)
    child.expect(r'(?i)current.*password:')
    child.sendline(old)
    child.expect(r'(?i)new password:')
    return child


def password_test(data):
    child = passwd_session(data['user1'])
    try:
        child.sendline(random_password(11))
        child.expect(r'(?i)(shorter than 12|less than 12|too short)')
        print('PASS passwd rejects an 11-character password', flush=True)
    finally:
        child.close(force=True)
    new = random_password()
    child = passwd_session(data['user1'])
    try:
        child.sendline(new)
        child.expect(r'(?i)retype new password:')
        child.sendline(new)
        child.expect(r'(?i)(all authentication tokens updated successfully|password updated successfully)')
        child.expect(pexpect.EOF)
        child.close()
        if child.exitstatus != 0:
            raise RuntimeError('passwd did not exit successfully')
        data['user1'] = new
        save(data)
        print('PASS passwd accepts a strong 24-character password', flush=True)
    finally:
        if child.isalive():
            child.close(force=True)


def login_test(data):
    for user in (sys.argv[2:] or USERS):
        child = pexpect.spawn('/sbin/agetty', ['--noclear', '-', '38400', 'linux'], encoding='utf-8', timeout=30,
                              env=ENV, echo=False, ignore_sighup=True)
        try:
            child.expect(r'login:')
            child.sendline(user)
            child.expect(r'(?i)password:')
            child.sendline(data[user])
            if user.startswith('curator'):
                child.expect(r'(?i)(login incorrect|permission denied|access denied)')
                print(f'PASS login rejects {user} with correct password', flush=True)
            else:
                child.expect(r'\$ ')
                child.sendline("printf '__MEPHI_LOGIN_OK__%s\\n' \"$(id -un)\"")
                child.expect('__MEPHI_LOGIN_OK__' + user)
                print(f'PASS login session opened as {user}', flush=True)
                child.sendline('exit')
                child.expect(pexpect.EOF)
        except (pexpect.EOF, pexpect.TIMEOUT):
            diagnostic = child.before or ''
            for password in data.values():
                diagnostic = diagnostic.replace(password, '[REDACTED]')
            child.close(force=True)
            print(f'Login diagnostic for {user}: exit={child.exitstatus}, signal={child.signalstatus}, output={diagnostic[-1800:]}', flush=True)
            raise
        finally:
            child.close(force=True)
    print('Tests used real /bin/login + PAM in PTYs; VirtualBox tty1 was not operated.', flush=True)


def main():
    if os.geteuid() != 0:
        raise RuntimeError('run as root')
    mode = sys.argv[1]
    if mode == 'setup':
        setup()
    elif mode == 'password':
        password_test(json.loads(PRIVATE.read_text()))
    elif mode == 'login':
        login_test(json.loads(PRIVATE.read_text()))
    else:
        raise RuntimeError('expected setup, password or login')


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        # pexpect exceptions may include the last sent password: never print exc.
        print(f'FAIL authentication test ({type(exc).__name__}); no secrets logged.', flush=True)
        sys.exit(1)
