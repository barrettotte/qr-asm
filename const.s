            // OS
            .equ STDOUT, 0

            // Syscall
            .equ EXIT,   1
            .equ READ,   3
            .equ WRITE,  4
            .equ OPEN,   5
            .equ CLOSE,  6
            .equ CREATE, 8

            // QR Code Specs
            .equ MODE, 0b0100           // byte encoding mode
            .equ MAX_VERSION, 3         // max version supported (1-4); zero indexed
            .equ MAX_DATA_CAP, 80       // max data capacity (message) (v4-L)
            .equ MAX_G1B, 4             // max blocks in group 1 (v4-H)
            .equ MAX_DWB, 80            // max data words per block (v4-L)
            .equ MAX_ECWB, 28           // max error correction words per block (v2-H)
            .equ MAX_PAYLOAD, 255       // max size of payload to transform into QR code
