import sys

name = sys.argv[2]

f = open(sys.argv[1], 'rb')
print(name + ':')
length = 0
data = f.read(10)
while data:
    length += len(data)
    print('db\t`{0}`'.format(''.join(reduce(lambda a, x: a + '\\x' + (hex(ord(x))[2:].rjust(2, '0')), data, ''))))
    data = f.read(10)
    
f.close()
print('{0}_LENGTH equ {1}'.format(name, length))
