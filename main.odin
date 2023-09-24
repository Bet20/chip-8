package main

import "core:fmt"
import "core:os"

Chip8 :: struct {
    memory: [4096]u8,
    V: [16]u8,
    opcode: u16,
    stack: [16]u16,
    stack_p: u16,
    pc: u16,
    index: u16,
    graphics: [64*32]u8,
    key: [16]u8,
    dt: u8,
    st: u8,
}

program_memory_entry_point :: 0x200
fontmap_size :: 80

font: [fontmap_size]u8 = {
    0xF0, 0x90, 0x90, 0x90, 0xF0,		// 0
	0x20, 0x60, 0x20, 0x20, 0x70,		// 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0,		// 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0,		// 3
	0x90, 0x90, 0xF0, 0x10, 0x10,		// 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0,		// 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0,		// 6
	0xF0, 0x10, 0x20, 0x40, 0x40,		// 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0,		// 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0,		// 9
	0xF0, 0x90, 0xF0, 0x90, 0x90,		// A
	0xE0, 0x90, 0xE0, 0x90, 0xE0,		// B
	0xF0, 0x80, 0x80, 0x80, 0xF0,		// C
	0xE0, 0x90, 0x90, 0x90, 0xE0,		// D
	0xF0, 0x80, 0xF0, 0x80, 0xF0,		// E
	0xF0, 0x80, 0xF0, 0x80, 0x80        // F
}

extract_registers :: proc(opcode: u16) -> (u16, u16) {
    x := (opcode & 0x0F00) >> 8
    y := (opcode & 0x00F0) >> 4
    return x, y
}

load_opcode :: proc(chip8: ^Chip8) {
    // merges byte u8 instructions into u16
    // and then assigns them to the opcode
    // Example: 0xF2 << 8 = 0xF200
    // then bitwise or with whatever comes after
    // in the memory
    chip8.opcode = u16(chip8.memory[chip8.pc]) << 8 | u16(chip8.memory[chip8.pc + 1])
}

cycle :: proc(chip8: ^Chip8) {
    // 0NNN Call -> 0xF000 
   switch chip8.opcode & 0xF000 {
    case 0xA000: // Mem sets index to NNN
        chip8.index = chip8.opcode & 0x0FFF
        chip8.pc += 2
    case 0x5000:
        x, y := extract_registers(chip8.opcode)
        if x == y { chip8.pc += 2 }
    case 0x1000:
      location := chip8.opcode & 0x0FFF
      chip8.pc = location
    case 0x2000:
        chip8.stack_p += 1
    case 0x8000: // ASSIGN
      x, y := extract_registers(chip8.opcode)
      switch chip8.opcode & 0x000F {
        case 0x0001: chip8.V[x] |= chip8.V[y] // OP binop
        case 0x0002: chip8.V[x] &= chip8.V[y] // AND binop
        case 0x0003: chip8.V[x] ~= chip8.V[y] // XOR binop
        case 0x0004: chip8.V[x] += chip8.V[y] // ADD math
        case 0x0005: chip8.V[x] -= chip8.V[y] // SUB math
    } 
   } 
}

chip8_init :: proc() -> Chip8 {
    chip8: Chip8 
    chip8.pc = 0x200 // 0000 0010 0000 0000
    chip8.opcode = 0
    chip8.index = 0
    chip8.stack_p = 0
    
    // Initialize font map 
    for i: i32 = 0; i < fontmap_size; i += 1 {
        chip8.memory[i] = font[i]
    }

    return chip8
}

chip8_load_program :: proc(chip8: ^Chip8, program: []u8) {
    for i := 0; i < len(program); i += 1 {
        chip8.memory[program_memory_entry_point + i] = program[i]
    } 
}
        
main :: proc() {
    // TODO: Check if the file has 
    // been given and print usage
    // if that's not the case 
    filename: string = os.args[1]
    
    // read rom file as []u8
    program, ok := os.read_entire_file_from_filename(filename)
    if !ok { return }
    fmt.println(program)

    chip8: Chip8 = chip8_init()
    chip8_load_program(&chip8, program)

    chip8.memory[chip8.pc] = 0x8F
    chip8.memory[chip8.pc + 1] = 0x22
    load_opcode(&chip8)
    cycle(&chip8)

    fmt.println("Chip-8, odin+sdl2 implementation.")
}
