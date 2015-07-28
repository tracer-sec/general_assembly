BITS 32

; arg0 - address of first item
; arg1 - address of output array
; arg2 - item count
LoadAll:
    push    ebp
    mov     ebp, esp
    sub     esp, 0x8            ; two locals
    push    ebx
    
    mov     ecx, [ebp + 0x8]    ; address of first item
    mov     ebx, [ebp + 0xc]    ; address of output
    mov     edx, [ebp + 0x10]   ; function count
LoadAllLoop:
    mov     [ebp - 4], ecx
    mov     [ebp - 8], edx
    push    dword [ecx + 0x4]   ; push function hash
    push    dword [ecx]         ; push module hash
    call    GetFunction
    mov     ecx, [ebp - 4]
    mov     edx, [ebp - 8]
    mov     [ebx], eax    ; replace function hash with function address
    add     ecx, 0x8
    sub     ebx, 0x4
    sub     edx, 1
    test    edx, edx
    jne     LoadAllLoop
    
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret     0xc
    