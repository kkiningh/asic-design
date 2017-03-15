Tutorial 1 - Verilog
===

Introduction To Verilog
---
Verilog is a widely used "Hardware Description Language" (HDL).
Verilog itself is based on the idea that instead of specifying how
to direclty construct the circuit we want, we specify how we want the circuit
to behave and the computer will generate a circuit that matches our description.
This is useful since it allows us to describe our circuit at a high level
instead of specifing the low level details of how each gate is connected.

However, this also means Verilog can produce some unintuative results if
we try to treat it like a normal programming language. Despite it's C-like
syntax, Verilog is not a proceedural language like C or Java, and can take some
getting used to if you're already familier with those languages.

### "Hello, World!" ###

Let's dive right into our first example of Verilog, a "Hello, World!" program:

```verilog
module hello_world;
    initial begin
        $display("Hello, World!");
        $finish;
    end
endmodule
```

TODO go over example

### Simple Counter ###

Our previous example didn't describe any hardware, here's a different example
with more feaures.

```verilog
module counter;
    reg clock;
    initial begin
        clock = 0;
    end

    always #5 clock = ~clock;

    reg [31:0] count;
    always @(posedge clock) begin
        count <= count + 1;
    end

    initial begin
        $monitor(clock, count);
        #100 $finish;
    end
endmodule;
```

Verilog is a "Hardware **simulation** Language"
Every block of code is either:

 - running constantly (assign, always @\*)
 - Or running on a trigger (always @posedge(clock))

Within a block, there is blocking and non-blocking assignment

 - Blocking is proceedural (A = 10; B = A; means B is 10)
 - Non-blocking happen at the same time (A <= 10; B <= A; means B gets the old value of A)
 - Don't mix the two!

### Verilog Execution Model ###

Go over how simulators actually work.

### Synthesizable Verilog ###

Only a subset of verilog can be converted into a circuit.

Let's split up our counter program into "test" and "circuit".

```verilog
module counter (
    input clock,
    input reset,
    output reg [31:0] count
);
    always @(posedge clock) begin
        if (reset) begin
            /* If the reset signal is high, reset the count to 0 */
            count <= 0;
        end else begin
            /* Otherwise, increment the count by 1 */
            count <= count + 1;
        end
    end
endmodule

module testbench;
    reg clock;
    reg reset;

    /* By default, */
    initial begin
        clock = 0;
        reset = 1;
    end



endmodule
```

#### Latches vs Registers ####

Make sure your verilog doesn't have latches.

### Finite State Machines ###

Go over how to create a finite state machine.

### Writing Testbenches ###

Split our test bench into driver, monitor, dut.

### Debugging using waveforms ###

### Generic Modules ###

#### Generate Statements ####

### Mixing Verilog with other languages ###

SystemVerilog
---

SystemVerilog is an extension to Verilog that adds more features for testing
and generic code.

### Logic ###

The `logic` keyword tells the SystemVerilog simulator to automatically infer
register or wire semantics based on usage.

Go over example:

```verilog
module counter

endmodule
```

Pitfall: unlike wire, initializing a logic declaration has register semantics,
not wire semantics!

```verilog
module test;
    logic x = 1;
endtest
```

### New Datatypes ###

#### Enums ###

### Interfaces ###


### Classes ###

### UVM and Advanced Verilog Testbenchs ###

### Assertions and Coverage ###


Lab 1
---


Apendix
---

### Language Features allowed in Synthesizable Verilog ###

Insert table

### Other Resources ###

 - Link to stuff

### References ###

