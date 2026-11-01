# ============================================================================
# ОПИСАНИЕ: настоящий снимок Linux framebuffer без дорисовки содержимого.
# ЧТО ДЕЛАЕТ: читает пиксели /dev/fb0 и сохраняет их в PNG без изменения размера.
# КАК ЗАПУСТИТЬ: sudo python3 capture_console.py output.png; Python 3 stdlib.
# ВХОДНЫЕ ФАЙЛЫ: /dev/fb0 (32-bit RGB framebuffer данной VM).
# ВЫХОДНОЙ ФАЙЛ: PNG, путь передаётся первым аргументом.
# ABI: https://github.com/torvalds/linux/blob/master/include/uapi/linux/fb.h
# ============================================================================
import fcntl
import struct
import sys
import zlib
from pathlib import Path

with open('/dev/fb0', 'rb', buffering=0) as framebuffer:
    variable = bytearray(160)
    fixed = bytearray(80)
    fcntl.ioctl(framebuffer, 0x4600, variable)
    fcntl.ioctl(framebuffer, 0x4602, fixed)
    values = struct.unpack('40I', variable)
    width, height, _, _, xoffset, yoffset, depth = values[:7]
    assert depth == 32 and values[8:17] == (16, 8, 0, 8, 8, 0, 0, 8, 0)
    stride = struct.unpack_from('I', fixed, 48)[0]
    rows = bytearray()
    for y in range(height):
        framebuffer.seek((y + yoffset) * stride + xoffset * 4)
        pixels = framebuffer.read(width * 4)
        assert len(pixels) == width * 4
        rgb = bytearray(width * 3)
        rgb[0::3], rgb[1::3], rgb[2::3] = pixels[2::4], pixels[1::4], pixels[0::4]
        rows.extend(b'\0' + rgb)

def chunk(kind, data):
    return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))

png = b'\x89PNG\r\n\x1a\n'
png += chunk(b'IHDR', struct.pack('!2I5B', width, height, 8, 2, 0, 0, 0))
png += chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')
Path(sys.argv[1]).write_bytes(png)
print(f'Captured /dev/fb0: {width}x{height}, {len(png)} bytes')
