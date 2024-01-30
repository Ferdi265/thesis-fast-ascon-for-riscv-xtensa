# Optimizing Ascon for 32-bit Architectures, Fast Implementations for RISC-V and Xtensa

This repository contains my Bachelor's Thesis and the optimized implementations
of [Ascon](https://ascon.iaik.tugraz.at) that I created for the thesis.

## Thesis

The Bachelor's Thesis is available in [thesis.pdf](thesis.pdf).

## Implementations

<table>
  <thead>
      <tr>
        <th>Name</th><th>Architecture</th><th>Strategy</th><th>Notes</th>
      </tr>
  </thead>
  <tbody>
      <tr><th colspan=4 align=center>ESP32</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>Xtensa LX6</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>c_opt64</code></td><td>Xtensa LX6</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>asm_xtensa_bi32_ror</code>*</td><td>Xtensa LX6</td><td>bit-interleaved, <code>ror</code></td><td></td></tr>
      <tr><td><code>asm_xtensa_fsr</code>*</td><td>Xtensa LX6</td><td><code>fsr</code></td><td></td></tr>
      <tr><th colspan=4 align=center>ESP32-C3</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>c_opt64</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="https://github.com/AsmOptC-RiscV/Assembly-Optimized-C-RiscV">Campos et al.</a></td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>RISC-V 32-bit</td><td>shift</td><td></td></tr>
      <tr><th colspan=4 align=center>riscvOVPsim+</th><tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>c_opt64</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="http://github.com/ascon/ascon-c">Ascon-C</a></td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>RISC-V 32-bit</td><td>shift</td><td><a href="https://github.com/AsmOptC-RiscV/Assembly-Optimized-C-RiscV">Campos et al.</a></td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>RISC-V 32-bit</td><td>shift</td><td></td></tr>
      <tr><td><code>asm_rv32_Zbb_shift</code>*</td><td>+<code>Zbb</code></td><td>shift</td><td>with <code>andn</code>, <code>orn</code>, <code>ror</code>, <code>rev8</code></td></tr>
      <tr><td><code>asm_rv32_Zbb_bi32_ror</code>*</td><td>+<code>Zbb</code></td><td>bit-interleaved, <code>ror</code></td><td>with <code>andn</code>, <code>orn</code>, <code>ror</code>, <code>rev8</code></td></tr>
      <tr><td><code>asm_rv32_Zbkb_bi32_ror</code>*</td><td>+<code>Zbkb</code></td><td>bit-interleaved, <code>ror</code></td><td>with <code>zip</code>, <code>unzip</code>, <code>pack</code></td></tr>
      <tr><td><code>asm_rv32_Zbp_bi32_ror</code>*</td><td>+<code>Zbp</code></td><td>bit-interleaved, <code>ror</code></td><td>with <code>packu</code></td></tr>
      <tr><td><code>asm_rv32_Zbt_fsr</code>*</td><td>+<code>Zbt</code></td><td><code>fsr</code></td><td>with <code>fsr</code></td></tr>
  </tbody>
</table>

Implementations marked with \* are new implementations. All implementations
implement Ascon128a, Ascon128, Ascon80pq, AsconHash, AsconHasha, AsconXof, and
AsconXofa, except `asm_rv32_campos`, which only implements Ascon128a.

## Benchmark Results

The benchmarking framework that was created for this thesis and the performance
results are available
[here](https://gitlab.tugraz.at/247B03DB02C337C2/lwc-cryptobench).


