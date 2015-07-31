BITS 32

KERNEL32_HASH                       equ 0x000d4e88
KERNEL32_LOADLIBRARYA               equ 0x000d5786
SHELL32_HASH                        equ 0x0006db88
SHELL32_SHELLEXECUTEA               equ 0x001b63e6

    call geteip
geteip:
    pop ebx
   
    push    ebp                     ; wouldn't normally bother with a stack frame, but
    mov     ebp, esp                ; we need ebp to mean something since we're
   
    push    KERNEL32_LOADLIBRARYA
    push    KERNEL32_HASH
    call    GetFunction
   
    lea     esi, [SHELL32 - geteip + ebx]
    push    esi                 ; LPCTSTR lpFileName
    call    eax

    push    SHELL32_SHELLEXECUTEA
    push    SHELL32_HASH
    call    GetFunction
   
    push    dword 0             ; INT nShowCmd
    push    dword 0             ; LPCTSTR lpDirectory
    push    dword 0             ; LPCTSTR lpParameters
    lea     esi, [URL - geteip + ebx]
    push    esi                 ; LPCTSTR lpFile
    lea     esi, [OPEN - geteip + ebx]
    push    esi                 ; LPCTSTR lpOperation
    push    dword 0             ; HWND hwnd     
    call    eax
   
    mov     esp, ebp
    pop     ebp
    ret
   
SHELL32:    db 'shell32.dll', 0
OPEN:       db 'open', 0   
URL:        db 'https://www.youtube.com/watch?v=oHg5SJYRHA0', 0

%include 'load_win32.asm'
