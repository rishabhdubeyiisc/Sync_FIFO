# Synchronous FIFO (First In First Out)

A high-performance, configurable **synchronous FIFO** implementation in **VHDL** with parameterizable depth and data width.

## 🔍 Overview

This FIFO (First In First Out) buffer provides reliable data buffering between different clock domains or processing stages. It features configurable data width and depth, robust error handling, and standard FIFO control signals.

## ⚡ Key Features

- **Configurable Design**: Parameterizable data width (B) and address bits (W)
- **Synchronous Operation**: Single clock domain with proper reset handling
- **Full Control Interface**: Standard FIFO signals (read, write, empty, full, error)
- **Robust Design**: Prevents overflow/underflow with status flags
- **Simultaneous R/W**: Supports concurrent read and write operations
- **Error Detection**: Built-in error reporting for invalid operations

## 🏗️ Architecture

### Generic Parameters
```vhdl
generic(
    B : natural := 9;  -- Data width in bits (default: 9 bits)
    W : natural := 2   -- Address width in bits (default: 2 bits = 4 locations)
);
```

### Port Interface
```vhdl
Port (
    clk     : in  STD_LOGIC;                    -- Clock input
    reset   : in  STD_LOGIC;                    -- Asynchronous reset (active high)
    rd      : in  STD_LOGIC;                    -- Read enable
    wr      : in  STD_LOGIC;                    -- Write enable  
    w_data  : in  STD_LOGIC_VECTOR(B-1 downto 0);  -- Write data
    r_data  : out STD_LOGIC_VECTOR(B-1 downto 0);  -- Read data
    empty   : out STD_LOGIC;                    -- Empty flag
    full    : out STD_LOGIC;                    -- Full flag
    ERROR   : out STD_LOGIC                     -- Error flag
);
```

## 🔧 Internal Components

### 1. **Register File**
- Array-based storage: `2^W` locations × `B` bits each
- Synchronous write operation with enable control
- Asynchronous read access

### 2. **Pointer Management**
- **Write Pointer** (`w_ptr_reg`): Points to next write location
- **Read Pointer** (`r_ptr_reg`): Points to next read location
- **Successor Logic**: Pre-computed next pointer values

### 3. **Status Generation**
- **Empty**: `r_ptr == w_ptr` and no pending writes
- **Full**: `w_ptr + 1 == r_ptr` (circular buffer logic)
- **Error**: Invalid operation combinations

## 🚀 Operation Modes

The FIFO supports four operation modes based on `rd` and `wr` signals:

| wr | rd | Operation | Description |
|----|----|-----------|-----------| 
| 0  | 0  | **No-op** | No operation performed |
| 0  | 1  | **Read Only** | Data read if FIFO not empty |
| 1  | 0  | **Write Only** | Data written if FIFO not full |
| 1  | 1  | **Simultaneous R/W** | Read and write in same cycle |

### Simultaneous Read/Write Benefits
- **Throughput**: Maintains data flow without stalling
- **Efficiency**: FIFO level remains constant
- **Pipeline**: Enables continuous data streaming

## 📊 Timing Behavior

### Write Operation
```
    Clock: ___/‾‾‾\___/‾‾‾\___
    wr:    ___/‾‾‾‾‾‾‾\_______ 
    w_data: ---<VALID_DATA>---
    full:   __________________ (must be '0')
```

### Read Operation  
```
    Clock: ___/‾‾‾\___/‾‾‾\___
    rd:    ___/‾‾‾‾‾‾‾\_______
    r_data: ---<VALID_DATA>--- (available same cycle)
    empty: __________________ (must be '0')
```

## 💻 Usage Example

### VHDL Instantiation
```vhdl
-- 16-bit wide, 256-deep FIFO
fifo_inst : entity work.FIFO
    generic map (
        B => 16,    -- 16-bit data width
        W => 8      -- 8-bit address = 256 locations
    )
    port map (
        clk     => system_clk,
        reset   => system_reset,
        rd      => fifo_read_en,
        wr      => fifo_write_en,
        w_data  => data_to_fifo,
        r_data  => data_from_fifo,
        empty   => fifo_empty_flag,
        full    => fifo_full_flag,
        ERROR   => fifo_error_flag
    );
```

### Producer-Consumer Example
```vhdl
-- Producer Process
producer: process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            fifo_write_en <= '0';
            data_to_fifo <= (others => '0');
        elsif fifo_full_flag = '0' and data_available = '1' then
            fifo_write_en <= '1';
            data_to_fifo <= next_data;
        else
            fifo_write_en <= '0';
        end if;
    end if;
end process;

-- Consumer Process  
consumer: process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            fifo_read_en <= '0';
        elsif fifo_empty_flag = '0' and ready_for_data = '1' then
            fifo_read_en <= '1';
            -- r_data will be valid on next clock edge
        else
            fifo_read_en <= '0';
        end if;
    end if;
end process;
```

## 📈 Performance Characteristics

### Capacity Configuration
| W (Address Bits) | FIFO Depth | Memory Usage |
|------------------|------------|--------------|
| 2 | 4 locations | 4 × B bits |
| 4 | 16 locations | 16 × B bits |
| 8 | 256 locations | 256 × B bits |
| 10 | 1024 locations | 1024 × B bits |

### Timing Specifications
- **Write Latency**: 1 clock cycle
- **Read Latency**: 0 clock cycles (combinational read)
- **Throughput**: Up to 1 read + 1 write per clock cycle
- **Flag Updates**: 1 clock cycle delay

## ⚠️ Design Considerations

### Important Notes
- **Reset Behavior**: Asynchronous reset clears all pointers and flags
- **Empty Read**: Reading from empty FIFO has no effect, data unchanged
- **Full Write**: Writing to full FIFO has no effect, data ignored  
- **Flag Timing**: Status flags update on next clock edge
- **Data Persistence**: Written data remains until overwritten

### Best Practices
1. **Always check flags** before read/write operations
2. **Use proper reset** to initialize FIFO state
3. **Size appropriately** for your data buffering needs
4. **Monitor ERROR flag** for debugging invalid operations

## 🔬 Verification Features

- **Overflow Protection**: Write blocked when FIFO full
- **Underflow Protection**: Read blocked when FIFO empty  
- **Error Reporting**: Invalid operation detection
- **Pointer Wraparound**: Automatic circular buffer management

## 🏗️ Project Structure

```
Sync_FIFO/
├── fifo.vhd          # Main FIFO implementation
├── README.md         # This documentation
└── testbench/        # Verification files (if available)
```

## 🎯 Applications

- **Data Buffering**: Between different processing stages
- **Clock Domain Crossing**: With additional synchronization
- **Rate Matching**: Different producer/consumer speeds
- **Pipeline Stages**: Decoupling combinational logic
- **Communication**: Inter-module data exchange

## 📄 Academic Use Notice

> **⚠️ ACADEMIC INTEGRITY**: This code is provided for educational reference only. 
> Direct copying for academic submissions is prohibited. 
> Please contact the author for permission if you wish to use this in your projects.

## 🤝 Usage and Licensing

This Synchronous FIFO implementation is an educational/research project developed at IISC (Indian Institute of Science).

**Important**: Please contact the author (Rishabh Dubey) before using this code in any commercial or academic projects to ensure proper attribution and licensing compliance.

## 📧 Contact

**Researcher**: Rishabh Dubey  
**Institution**: Indian Institute of Science (IISC)  
**Project**: Synchronous FIFO - High-Performance VHDL Implementation  
**Domain**: Digital Design & FPGA Development  

For technical questions, collaboration requests, or licensing inquiries, please reach out to discuss proper usage and attribution.

---

**Built with precision for reliable data flow 🚀**
