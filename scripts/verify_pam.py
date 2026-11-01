# ============================================================================
# ОПИСАНИЕ: проверка правил PAM службы login с настоящими паролями.
# ЧТО ДЕЛАЕТ: проверяет аутентификацию и разрешение входа пяти пользователей.
# КАК ЗАПУСТИТЬ: sudo python3 verify_pam.py; зависимости: Python 3, libpam.
# ВХОДНЫЕ ФАЙЛЫ: /root/mephi-backups/project-test-passwords.json, PAM login.
# ВЫХОДНОЙ ФАЙЛ: stdout; пароли и хеши не выводятся.
# ============================================================================
import ctypes as C
import json
from pathlib import Path


class Message(C.Structure):
    _fields_ = [('style', C.c_int), ('text', C.c_char_p)]


class Response(C.Structure):
    _fields_ = [('text', C.c_void_p), ('code', C.c_int)]


Callback = C.CFUNCTYPE(C.c_int, C.c_int, C.POINTER(C.POINTER(Message)),
                     C.POINTER(C.POINTER(Response)), C.c_void_p)


class Conversation(C.Structure):
    _fields_ = [('callback', Callback), ('data', C.c_void_p)]


pam = C.CDLL('libpam.so.0')
libc = C.CDLL('libc.so.6')
libc.calloc.argtypes = [C.c_size_t, C.c_size_t]
libc.calloc.restype = C.c_void_p
libc.strdup.argtypes = [C.c_char_p]
libc.strdup.restype = C.c_void_p
pam.pam_start.argtypes = [C.c_char_p, C.c_char_p, C.POINTER(Conversation), C.POINTER(C.c_void_p)]
pam.pam_set_item.argtypes = [C.c_void_p, C.c_int, C.c_void_p]
for name in ('pam_authenticate', 'pam_acct_mgmt', 'pam_end'):
    getattr(pam, name).argtypes = [C.c_void_p, C.c_int]

credentials = json.loads(Path('/root/mephi-backups/project-test-passwords.json').read_text())
for user, password in credentials.items():
    @Callback
    def converse(count, messages, result, data):
        responses = C.cast(libc.calloc(count, C.sizeof(Response)), C.POINTER(Response))
        for i in range(count):
            style = messages[i].contents.style
            if style in (1, 2):
                value = password if style == 1 else user
                responses[i].text = libc.strdup(value.encode())
        result[0] = responses
        return 0

    conversation = Conversation(converse, None)
    handle = C.c_void_p()
    assert pam.pam_start(b'login', user.encode(), C.byref(conversation), C.byref(handle)) == 0
    try:
        assert pam.pam_set_item(handle, 3, C.cast(C.c_char_p(b'tty8'), C.c_void_p)) == 0
        authentication = pam.pam_authenticate(handle, 0)
        assert authentication == 0, f'{user}: authentication failed, code {authentication}'
        account = pam.pam_acct_mgmt(handle, 0)
        expected = 6 if user.startswith('curator') else 0
        assert account == expected, f'{user}: unexpected account result {account}'
        print(f'PASS {user}: correct password accepted; login account result={account} '
              f'({"permission denied" if expected else "allowed"})', flush=True)
    finally:
        pam.pam_end(handle, 0)
print('All login PAM checks passed. PAM_TTY=tty8; this test does not open a shell.')
