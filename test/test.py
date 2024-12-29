# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

##import cocotb
##from cocotb.clock import Clock
##from cocotb.triggers import ClockCycles


##@cocotb.test()
##async def test_project(dut):
 ##   dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    ##clock = Clock(dut.clk, 10, units="us")
    # cocotb.start_soon(clock.start())

    # Reset
    ##dut._log.info("Reset")
    ##dut.ena.value = 1
    ##dut.ui_in.value = 0
    ##dut.uio_in.value = 0
    ##dut.rst_n.value = 0
    ##await ClockCycles(dut.clk, 10)
    ##dut.rst_n.value = 1

    ##dut._log.info("Test project behavior")

    # Set the input values you want to test
    ##dut.ui_in.value = 15
    ## dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    ##await ClockCycles(dut.clk, 10)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    ##assert dut.uo_out.value != 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.


# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_reset(dut):
    
    ##Test that the DUT properly resets and stays in a known state.
    
    dut._log.info("=== test_reset START ===")

    # Use a faster clock: let's do 1 MHz for example (period = 1us)
    # For a true VGA simulation, consider ~25 MHz.
    # 25 MHz clock => 40 ns period
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Initially drive signals
    dut.ena.value = 1
    dut.ui_in.value = 0     # No movement, no fire
    dut.uio_in.value = 0
    dut.rst_n.value = 0     # Assert reset

    dut._log.info("Applying reset for 20 cycles")
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1     # Deassert reset

    # Wait some cycles to allow any registers to come out of reset
    await ClockCycles(dut.clk, 50)

    # Check if output is at some expected default (often it might still be 0, especially if VGA not active yet)
    # The main purpose is to ensure no X or Z are on outputs
    uo_out_val = int(dut.uo_out.value)
    dut._log.info(f"uo_out after reset = 0x{uo_out_val:02X}")

    # Example assertion: just check that nothing is 'X' or 'Z'
    # 'uo_out.value.is_resolvable' ensures no unknown (X) or high-impedance (Z) bits
    assert dut.uo_out.value.is_resolvable, "uo_out has X or Z after reset!"

    dut._log.info("=== test_reset DONE ===\n")


@cocotb.test()
async def test_vga_sync(dut):
    
    ##Let the simulation run for a while to see if HSYNC/VSYNC bits in uo_out ever toggle.
    
    dut._log.info("=== test_vga_sync START ===")

    clock = Clock(dut.clk, 1, units="us")  
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1

    # Let the design run for a while
    TOTAL_CYCLES = 200_000  # Adjust up if needed
    dut._log.info(f"Running for {TOTAL_CYCLES} cycles at 1 MHz ...")
    await ClockCycles(dut.clk, TOTAL_CYCLES)

    # uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}
    # Extract bits
    uo_out_val = int(dut.uo_out.value)
    hsync_bit  = (uo_out_val >> 7) & 0x1
    vsync_bit  = (uo_out_val >> 3) & 0x1

    dut._log.info(f"uo_out final = {uo_out_val:08b} (HSYNC={hsync_bit}, VSYNC={vsync_bit})")

    # Ideally, we expect HSYNC or VSYNC to have toggled if enough cycles have passed.
    # We can’t easily confirm *during* the run unless we sample repeatedly.
    # For demonstration, we do a final check if they’re not both 0. (Very rough check!)
    # For a robust test, log transitions or sample multiple times in a loop.
    assert (hsync_bit == 1 or vsync_bit == 1), (
        "HSYNC and VSYNC never toggled from 0 within the time tested. "
        "Try increasing the clock frequency or the simulation cycles."
    )

    dut._log.info("=== test_vga_sync DONE ===\n")


@cocotb.test()
async def test_shooter_movement(dut):
    
    ##Test that pressing left/right changes the shooter's position eventually.
    ##We cannot directly read the shooter's X position from outside the DUT,
    ##but we might observe changes in color bits (R, G, B) at certain times
    ##or rely on internal signals if you bring them out for debug.
    
    dut._log.info("=== test_shooter_movement START ===")

    clock = Clock(dut.clk, 1, units="us")  
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0b0000  # [3:0] => [reset, fire, left, right] (depending on how you mapped them)
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1

    # Let module stabilize
    await ClockCycles(dut.clk, 1000)

    # Press right for 1k cycles
    dut._log.info("Pressing RIGHT button")
    dut.ui_in.value = 0b0001  # Suppose ui_in[0] = Move right
    await ClockCycles(dut.clk, 1000)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 500)

    # Press left for 1k cycles
    dut._log.info("Pressing LEFT button")
    dut.ui_in.value = 0b0010  # Suppose ui_in[1] = Move left
    await ClockCycles(dut.clk, 1000)
    dut.ui_in.value = 0

    # Let the design run a bit to see the final effect
    await ClockCycles(dut.clk, 2000)

    # We can’t truly “assert” the shooter moved without hooking up debugging signals.
    # But we can at least check that hsync/vsync or other bits changed.
    # If you want to do deeper checks, consider exposing the shooter's X position on an internal debug signal.
    dut._log.info("Checking final output bits (uo_out)")
    final_uo = int(dut.uo_out.value)
    dut._log.info(f"uo_out = {final_uo:08b}")

    # Minimal assertion: ensure no unknown bits
    assert dut.uo_out.value.is_resolvable, "uo_out has X or Z after movement test!"

    dut._log.info("=== test_shooter_movement DONE ===\n")


@cocotb.test()
async def test_fire_button(dut):
    
    ##Test pressing the fire button. We expect eventually the bullet signals might
    ##show up on the VGA. In a short test, it might still be tough to see unless you
    ##run enough cycles or bring out internal signals (bullet_x, bullet_y).
    
    dut._log.info("=== test_fire_button START ===")

    clock = Clock(dut.clk, 1, units="us")  
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1

    # Let module stabilize for a bit
    await ClockCycles(dut.clk, 2000)

    # Press the fire button (assuming ui_in[2] = Fire)
    dut._log.info("Pressing FIRE button")
    dut.ui_in.value = 0b0100
    await ClockCycles(dut.clk, 20)
    dut.ui_in.value = 0

    # Let bullet “move” for some time
    await ClockCycles(dut.clk, 10000)

    # Check final output
    final_uo = int(dut.uo_out.value)
    dut._log.info(f"uo_out after firing = {final_uo:08b}")
    # No definitive assertion here unless you expose an internal bullet_active or bullet_y to check
    assert dut.uo_out.value.is_resolvable, "uo_out has X or Z after firing test!"

    dut._log.info("=== test_fire_button DONE ===\n")
