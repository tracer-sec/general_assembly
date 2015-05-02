BITS 32

USER32_HASH                         equ 0x00038f88
USER32_MESSAGEBOXA                  equ 0x0006b81a

    call geteip
geteip:
    pop ebx

    push    USER32_MESSAGEBOXA
    push    USER32_HASH
    call    GetFunction
    
    push    dword 0             ; UINT uType = MB_OK
    lea     esi, [CAPTION - geteip + ebx]
    push    esi                 ; LPCSTR lpCaption
    lea     esi, [MESSAGE - geteip + ebx]
    push    esi                 ; LPCSTR lpText
    push    dword 0             ; HWND hWnd = NULL
    call    eax
    
    ret
    
CAPTION:    db 'Hello world caption', 0
MESSAGE:    db 'Hello world message', 0

%include 'load_win32.asm'
