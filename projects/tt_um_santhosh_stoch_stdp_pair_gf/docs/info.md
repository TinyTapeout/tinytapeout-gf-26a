# tt_um_santhosh_stoch_stdp_pair_gf

TTGF26a Scenario B tile 1 — merged stochastic/LIF neuron + STDP learning
controller on GF180mcuD.

## How it works

The tile combines an 8-bit saturating leaky-integrate-and-fire (LIF) neuron
with a stochastic mode (fire when `lfsr < sig_lut[v_mem[7:5]]`), homeostatic
theta adaptation over a 256-clock window, and a 16-clock Bayesian confidence
counter. A second block is an STDP controller with 8-bit pre/post traces,
per-clock exponential-shift decay, an anti-Hebbian polarity bit, and optional
reward-gated learning. On every LTP or LTD event the controller emits a
1-cycle `weight_update` pulse together with `learn_dir` and latches the
magnitude in `R_LAST_MAG` for host readback.

All registers are programmable via a shared 8-bit SPI mode-0 slave (same
module used by the other TTGF26a tiles).

## How to test

1. Program the neuron (`R_STIM`, `R_THETA`, `R_LEAK`, `R_SIG_LUT[0..7]`,
   `R_POLY`, `R_TARGET`, `R_THETA_MIN`, `R_THETA_MAX`) and the STDP
   controller (`R_TAU_PLUS`, `R_TAU_MINUS`, `R_LTP_LUT[0..7]`,
   `R_LTD_LUT[0..3]`, `R_STDP_CTRL`) via SPI.
2. Drive `ui_in[0]` to pick LIF or stochastic mode.
3. Assert `ui_in[4]` (or set CTRL[3]) to enable homeostatic adaptation.
4. Assert `ui_in[5]` (or set CTRL[4]) to enable Bayesian confidence counting.
5. Drive `ui_in[2]` high and write `R_STDP_CTRL[0]=1` to enable learning.
6. Pulse `ui_in[1]` (`ext_input`) once per presynaptic spike; observe
   `uo_out[0]` = post-synaptic spike and `uo_out[1]` = 1-cycle weight-update
   pulse.
7. Read `R_VMEM`, `R_TRACE_PRE`, `R_TRACE_POST`, `R_LAST_MAG`, `R_BAYES_CONF`,
   `R_THETA_LIVE`, `R_STATUS` via SPI to observe state.

## External hardware

Only a microcontroller (or FPGA) driving the SPI slave is required. Any
spike-train source can be wired to `ui_in[1]`.
