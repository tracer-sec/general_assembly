; Loads win32 functions, given a module and function hash
; https://github.com/debasishm89/x86-Assembly/blob/master/speaking%20shell%20code.asm
; http://undocumented.ntinternals.net/source/usermode/undocumented%20functions/nt%20objects/process/peb.html
; http://sandsprite.com/CodeStuff/Understanding_the_Peb_Loader_Data_List.html
; http://media.paloaltonetworks.com/lp/endpoint-security/blog/how-injected-code-finds-exported-functions.html
; http://win32assembly.programminghorizon.com/pe-tut7.html

; TODO:
; - fix failed ESP check in Win32Host debug
; - can't find the module! now what?
; - LoadLibraryA on missing modules?

BITS 32

; arg0 - hash of the module name
; arg1 - hash of the function name
; returns function address
GetFunction:
    push    ebp
    mov     ebp, esp
    sub     esp, 4              ; space for one local variable
    push    ebx                 ; preserve ebx for the caller (stdcall)
    push    dword [ebp + 0x8]   ; module hash
    call    GetModule
    mov     [ebp - 4], eax      ; put the base address of our stack for RVA calculations
    mov     eax, [eax + 0x3c]   ; get the PE offset
    add     eax, [ebp - 4]      ; eax now points to our PE base
    mov     eax, [eax + 0x78]   ; eax now points to the RVA of our export table
    add     eax, [ebp - 4]      ; that's our import table
    mov     ebx, [eax + 0x20]
    add     ebx, [ebp - 4]      ; ebx contains our name address    
    mov     ecx, [eax + 0x1c]    
    add     ecx, [ebp - 4]      ; and ecx contains the function address
    mov     edx, [eax + 0x24]
    add     edx, [ebp - 4]      ; and edx contains the ordinals (seriously, WTF is this even for?)
    push    ecx                 ; we don't actually use this in our main loop, but keep a hold of it
GetFunctionLoop:
    mov     esi, [ebx]          ; RVA of name string
    add     esi, [ebp - 4]      ; actual name address
    push    edx                 ; preserve edx        
    push    0x1                 ; push args for HashCheck
    push    dword [ebp + 0xc]
    push    esi
    call    CheckHash           ; run our hash check
    pop     edx                 ; bring edx back
    test    eax, eax            ; did we match?
    jne     GetFunctionOut      ; yep, jump out
    add     ebx, 4              ; next name
    add     edx, 2
    jmp     GetFunctionLoop
GetFunctionOut:
    pop     ecx                 ; bring out function table address back into ecx
    xor     ebx, ebx
    mov     bx, [edx]           ; ebx is now our index into the function table
    imul    ebx, 4
    mov     eax, [ecx + ebx]    ; dump our function RVA into eax
    add     eax, [ebp - 4]      ; and turn the address into an absolute
    pop     ebx                 ; unwind
    mov     esp, ebp
    pop     ebp
    ret     0x8

; arg0 - hash of the module name
; returns module base address
GetModule:
    push    ebp
    mov     ebp, esp
    push    ebx                 ; preserve ebx
    mov     ebx, [fs:0x30]      ; get a pointer to the PEB
    mov     ebx, [ebx + 0x0c]   ; get a pointer to the LoaderData
    mov     ebx, [ebx + 0x0c]   ; load order module list. from here on out ebx points to MODULEs
GetModuleLoop:
    mov     esi, [ebx + 0x30]   ; base DLL name
    push    0x2
    push    dword [ebp + 0x8]   ; arg0, our hash
    push    esi
    call    CheckHash           ; run our hash check
    test    eax, eax            ; did we match?
    jne     GetModuleOut        ; yep, jump out
    mov     ebx, [ebx]          ; nope, iterate
                                ; TODO: ran out of modules?
    jmp     GetModuleLoop
GetModuleOut:
    mov     eax, [ebx + 0x18]   ; there's our module base address
    pop     ebx                 ; restore ebx
    mov     esp, ebp
    pop     ebp
    ret     0x4
    
; arg0 - string to hash
; arg1 - hash to compare
; arg2 - stride (1 for ASCII, 2 for UNICODE)
; returns 0 if different, 1 if matching
CheckHash:
    push    ebp
    mov     ebp, esp
    push    dword [ebp + 0x10]  ; push our stride
    push    dword [ebp + 0x8]   ; pass our first argument to the hash function
    call    Hash
    mov     edx, eax            ; keep a hold of the result of the hash
    xor     eax, eax            ; clear eax
    cmp     edx, [ebp + 0xc]    ; compare it against our stored value
    jne     CheckHashOut
    inc     eax                 ; set eax to 1 if the hashes match
CheckHashOut:
    mov     esp, ebp
    pop     ebp
    ret     0xc
    
; arg0 - null-terminated string
; arg1 - stride (1 for ASCII, 2 for UNICODE)
Hash:
    push    ebp
    mov     ebp, esp
    mov     ecx, [ebp + 0x8]    ; put first argument into ECX
    xor     eax, eax
    xor     edx, edx
HashLoop:
    cmp     byte [ecx], 0x00    ; checks for the null byte on the end of the string
    jz      HashOut
    mov     dl, [ecx]
    or      dl, 0x60
    add     eax, edx
    shl     eax, 1
    add     ecx, [ebp + 0xc]    ; next character . . .
    jmp     HashLoop
HashOut:
    mov     esp, ebp
    pop     ebp
    ret     0x8                 ; return and unwind the stack
    