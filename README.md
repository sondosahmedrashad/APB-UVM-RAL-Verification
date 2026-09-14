# APB Verification Using UVM RAL

A SystemVerilog/UVM verification project implementing and integrating a complete **UVM Register Abstraction Layer (RAL)** for an APB-based peripheral.

The project focuses on register modeling, APB-to-RAL integration, frontdoor and backdoor register access, explicit prediction, functional coverage, reporting, and debugging of the APB/UVM interaction.

> **Project Scope:**  
> The base APB UVM environment was provided as starter code.  
> The main work in this project includes the RAL model, adapter, predictor integration, modular register sequences, functional coverage, reporting, and the timing/debugging changes required to achieve a stable zero-error verification run.

---

## DUT Register Map

The APB peripheral contains five software-visible registers:

| Address | Register | Access | Reset |
| --- | --- | --- | --- |
| `0x00` | `CNTRL` | RW lower 4 bits | `0x00000000` |
| `0x04` | `REG1` | RW | `0x00000000` |
| `0x08` | `REG2` | RW | `0x00000000` |
| `0x0C` | `REG3` | RW | `0x00000000` |
| `0x10` | `REG4` | RW | `0x00000000` |

`CNTRL` is accessed as a 32-bit APB register, while only bits `[3:0]` are implemented as writable control fields.

Bits `[31:4]` are modeled as a read-only reserved field.

---

## Verification Architecture

The final environment combines the existing APB UVM testbench with a complete RAL layer.

```text
                        UVM Test
                           │
                    RAL Sequences
                           │
                       RAL Model
                           │
                ┌──────────┴──────────┐
                │                     │
           Frontdoor Path        Backdoor Path
                │                     │
            RAL Adapter           HDL Access
                │
            Sequencer
                │
              Driver
                │
              APB DUT
                │
              Monitor
             /       \
            /         \
      Scoreboard    Predictor
                       │
                   RAL Mirror
```

The monitor observes completed APB transactions and distributes them to both the scoreboard and the explicit RAL predictor.

---

## UVM RAL Model

The register model includes:

- Field-level modeling
- Register classes
- Register block
- APB address map
- HDL backdoor paths
- Register reset values
- Per-register functional coverage

### CNTRL Register

The `CNTRL` register contains:

```text
[3] CTRL3      RW
[2] CTRL2      RW
[1] CTRL1      RW
[0] CTRL0      RW
[31:4] RESERVED RO
```

The upper reserved bits always read as zero.

### Data Registers

`REG1` through `REG4` use a reusable 32-bit RW register class.

This avoids duplicated register-model code while keeping independent register instances and coverage state.

---

## Register Map

The RAL address map matches the APB DUT register decode:

```systemverilog
default_map.add_reg(cntrl, 32'h00, "RW");
default_map.add_reg(reg1,  32'h04, "RW");
default_map.add_reg(reg2,  32'h08, "RW");
default_map.add_reg(reg3,  32'h0C, "RW");
default_map.add_reg(reg4,  32'h10, "RW");
```

The APB data bus is 32 bits wide, so the map uses a 4-byte bus width.

---

## APB RAL Adapter

The adapter translates between generic UVM register operations and the existing APB sequence item.

It implements:

- `reg2bus()` for frontdoor register operations
- `bus2reg()` for converting monitored APB transactions back into RAL operations

This allows high-level register APIs to reuse the existing APB sequencer and driver.

---

## Explicit Predictor

The environment uses an explicit:

```text
uvm_reg_predictor
```

The predictor receives transactions from the APB monitor and updates the RAL mirrored values based on **observed bus activity**.

Automatic prediction is disabled:

```systemverilog
regmodel.default_map.set_auto_predict(0);
```

This prevents double prediction and ensures that the RAL mirror reflects actual observed APB transactions.

---

## Frontdoor and Backdoor Access

The project demonstrates both RAL access mechanisms.

### Frontdoor Access

Frontdoor operations are converted into normal APB transactions:

```text
RAL Operation
     ↓
Register Map
     ↓
Adapter
     ↓
APB Sequencer
     ↓
Driver
     ↓
DUT
```

Frontdoor traffic is therefore visible on the APB interface and waveform.

### Backdoor Access

Backdoor access reads the physical RTL register directly through configured HDL paths.

This allows register contents to be checked independently of the APB bus.

---

## Desired, Mirrored, and Design Values

The project explicitly reports the three important RAL states:

- **DESIRED** — what the register model wants the register to contain
- **MIRRORED** — what the model currently believes is stored in the hardware
- **DESIGN** — the actual RTL register value

For example:

```text
set()
↓
DESIRED changes

update()
↓
Frontdoor APB write

Monitor + Predictor
↓
MIRRORED updated

Backdoor check
↓
DESIGN value confirmed
```

This reporting helps visualize and debug RAL behavior.

---

## Modular RAL Sequences

Five independent register sequences were implemented:

| Sequence | Register |
| --- | --- |
| `ctrl_reg_seq` | `CNTRL` |
| `reg1_reg_seq` | `REG1` |
| `reg2_reg_seq` | `REG2` |
| `reg3_reg_seq` | `REG3` |
| `reg4_reg_seq` | `REG4` |

The sequences use RAL APIs including:

```systemverilog
set()
update()
peek()
read()
write()
```

and exercise both:

```text
UVM_FRONTDOOR
UVM_BACKDOOR
```

---

## Functional Coverage

Each register instance includes functional coverage.

### CNTRL Coverage

The control register tracks all possible 4-bit implemented values.

### Data Register Coverage

The 32-bit data registers classify sampled values into categories including:

- Zero
- Low-value range
- High-value range
- All ones

The directed RAL sequences demonstrate coverage collection without claiming complete closure of every defined data bin.

---

## Debugging and Stabilization

RAL integration exposed several issues at the APB/UVM boundary.

### 1. Missing REG2 Address Constraint

The original legal address constraint omitted:

```text
0x08
```

which corresponds to `REG2`.

The address was restored to the legal constraint set.

---

### 2. Stale PRDATA Sampling

The DUT updates the internal read-data register using a nonblocking assignment.

The monitor could therefore sample `PRDATA` before the updated value became visible.

The monitor was corrected to:

```systemverilog
@(posedge APB_vif.pclk);

if (APB_vif.psel &&
    APB_vif.penable &&
    APB_vif.presetn) begin

    ...

    #1;
    seq_item.prdata = APB_vif.prdata;
end
```

This allows the DUT NBA update to settle before the read data is sampled.

---

### 3. Monitor Transaction Filtering

The monitor was updated to publish transactions only for valid completed APB transfers:

```text
PSEL && PENABLE && PRESETN
```

This prevents idle or setup cycles from being interpreted as completed register operations.

---

### 4. Scoreboard Improvements

The scoreboard was strengthened to:

- Use monitor-sampled transactions
- Initialize expected register values
- Handle the 4-bit `CNTRL` implementation correctly
- Mask reserved control bits
- Report real mismatches using `uvm_error`

These changes improved the reliability of the self-checking environment.

---

## Final Verification Results

| Metric | Final Result |
| --- | ---: |
| Mapped Registers | **5** |
| Modular RAL Sequences | **5** |
| Access Paths | **Frontdoor + Backdoor** |
| Explicit Predictor | **1** |
| Simulation Time | **900 ns** |
| UVM_INFO | **59** |
| UVM_WARNING | **0** |
| UVM_ERROR | **0** |
| UVM_FATAL | **0** |
| Sequence Completion | **All sequences completed** |

The final Questa simulation completed successfully with no warnings, errors, or fatal messages.

---

## Repository Structure

```text
APB-UVM-RAL-Verification/
│
├── rtl/
│   └── APB.sv
│
├── tb/
│   ├── APB_If.sv
│   ├── my_config.sv
│   ├── my_sequence_item.sv
│   ├── my_sequencer.sv
│   ├── my_driver.sv
│   ├── my_monitor.sv
│   ├── my_agent.sv
│   ├── my_scoreboard.sv
│   ├── apb_ral_model.sv
│   ├── apb_reg_adapter.sv
│   ├── ral_sequences.sv
│   ├── my_env.sv
│   ├── my_test.sv
│   └── top.sv
│
├── sim/
│   ├── files.txt
│   ├── run.do
│   └── wave.do
│
├── docs/
│   └── APB_UVM_RAL_Portfolio_Report.docx
│
└── README.md
```

---

## Technical Report

A detailed portfolio report is included with the project.

It documents:

- DUT register map
- RAL architecture
- Register and field modeling
- Adapter and predictor integration
- Frontdoor and backdoor operation
- Modular register sequences
- Functional coverage
- Debugging process
- Waveform evidence
- Final UVM results

[View Full Technical Report](docs/APB_UVM_RAL_Portfolio_Report.docx)

---

## Tools and Technologies

**SystemVerilog • UVM • UVM RAL • APB • QuestaSim • Functional Coverage • Register Modeling • Scoreboarding**

---

## Key Concepts Demonstrated

- UVM Register Abstraction Layer
- Register and field modeling
- Register blocks and address maps
- UVM RAL adapters
- Explicit register prediction
- Desired vs. mirrored vs. design values
- Frontdoor register access
- Backdoor register access
- HDL register paths
- Modular register sequences
- Functional coverage
- APB timing and monitoring
- Transaction-based scoreboarding
- Verification debugging

---

## Key Takeaway

The main value of this project is not only achieving a zero-error simulation.

The project demonstrates the complete verification path from:

```text
Register Specification
        ↓
RAL Model
        ↓
APB Translation
        ↓
Observed Bus Traffic
        ↓
Prediction
        ↓
Scoreboard Checking
        ↓
Waveform / Log Evidence
```

It demonstrates how a UVM RAL model can be integrated into an existing verification environment, how frontdoor and backdoor access complement each other, and how timing and observation issues at the protocol boundary can be diagnosed and corrected without modifying the DUT behavior.
