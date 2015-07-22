import sys

s = sys.argv[1]
hash = reduce(lambda a, x: (a + (ord(x) | 0x60)) << 1, s, 0)
print('{0:#010x}'.format(hash))
