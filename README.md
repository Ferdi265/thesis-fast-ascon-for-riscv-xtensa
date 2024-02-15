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

The benchmarking framework that was created for this thesis is available
[here](https://gitlab.tugraz.at/247B03DB02C337C2/lwc-cryptobench).

<details>
  <summary>Performance in cycles per byte, for long inputs (32 kB)</summary>

  <table>
    <thead>
      <tr><th rowspan=2>Name</th><th rowspan=2>Ascon128a</th><th>Ascon128</th><th>AsconHasha</th><th>AsconHash</th></tr>
      <tr><th>Ascon80pq</th><th>AsconXofa</th><th>AsconXof</th></tr>
    </thead>
    <tbody>
      <tr><th colspan=5 align=center>ESP32</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>98.76 c/B</td><td>141.53 c/B</td><td>178.04 c/B</td><td>260.14 c/B</td></tr>
      <tr><td><code>c_opt64</code></td><td>85.01 c/B</td><td>127.49 c/B</td><td>156.95 c/B</td><td>230.07 c/B</td></tr>
      <tr><td><code>asm_xtensa_bi32_ror</code>*</td><td>70.87 c/B</td><td>100.09 c/B</td><td>115.47 c/B</td><td>166.54 c/B</td></tr>
      <tr><td><code>asm_xtensa_fsr</code>*</td><td>51.01 c/B</td><td>77.18 c/B</td><td>95.68 c/B</td><td>139.24 c/B</td></tr>
      <tr><th colspan=5 align=center>ESP32-C3</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>78.35 c/B</td><td>112.81 c/B</td><td>140.88 c/B</td><td>205.97 c/B</td></tr>
      <tr><td><code>c_opt64</code></td><td>70.83 c/B</td><td>102.90 c/B</td><td>129.44 c/B</td><td>194.27 c/B</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>70.13 c/B</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>66.30 c/B</td><td>97.35 c/B</td><td>124.00 c/B</td><td>183.34 c/B</td></tr>
      <tr><th colspan=5 align=center>riscvOVPsim+</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>76.18 c/B</td><td>110.36 c/B</td><td>138.66 c/B</td><td>202.70 c/B</td></tr>
      <tr><td><code>c_opt64</code></td><td>68.85 c/B</td><td>101.10 c/B</td><td>128.15 c/B</td><td>189.69 c/B</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>68.79 c/B</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>64.79 c/B</td><td>94.85 c/B</td><td>121.17 c/B</td><td>179.72 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbb_shift</code>*</td><td>58.65 c/B</td><td>87.59 c/B</td><td>114.91 c/B</td><td>171.46 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbb_bi32_ror</code>*</td><td>54.71 c/B</td><td>74.45 c/B</td><td>84.87 c/B</td><td>122.40 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbkb_bi32_ror</code>*</td><td>41.44 c/B</td><td>61.19 c/B</td><td>78.23 c/B</td><td>115.77 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbp_bi32_ror</code>*</td><td>40.94 c/B</td><td>60.69 c/B</td><td>77.98 c/B</td><td>115.52 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbt_fsr</code>*</td><td>38.62 c/B</td><td>57.56 c/B</td><td>74.85 c/B</td><td>111.39 c/B</td></tr>
    </tbody>
  </table>
</details>

<details>
  <summary>Performance in cycles per byte, for short inputs (16 B)</summary>

  <table>
    <thead>
      <tr><th rowspan=2>Name</th><th rowspan=2>Ascon128a</th><th>Ascon128</th><th>AsconHasha</th><th>AsconHash</th></tr>
      <tr><th>Ascon80pq</th><th>AsconXofa</th><th>AsconXof</th></tr>
    </thead>
    <tbody>
      <tr><th colspan=5 align=center>ESP32</th></tr>
      <tr><td><code>c_opt64</code></td><td>918.61 c/B</td><td>874.50 c/B</td><td>564.61 c/B</td><td>760.94 c/B</td></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>398.83 c/B</td><td>441.23 c/B</td><td>588.36 c/B</td><td>793.44 c/B</td></tr>
      <tr><td><code>asm_xtensa_bi32_ror</code>*</td><td>293.27 c/B</td><td>310.49 c/B</td><td>442.69 c/B</td><td>595.77 c/B</td></tr>
      <tr><td><code>asm_xtensa_fsr</code>*</td><td>214.51 c/B</td><td>239.00 c/B</td><td>365.68 c/B</td><td>496.25 c/B</td></tr>
      <tr><th colspan=5 align=center>ESP32-C3</th></tr>
      <tr><td><code>c_opt64</code></td><td>1548.91 c/B</td><td>942.02 c/B</td><td>902.54 c/B</td><td>7484.96 c/B</td></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>320.40 c/B</td><td>354.51 c/B</td><td>472.86 c/B</td><td>635.43 c/B</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>303.58 c/B</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>273.79 c/B</td><td>301.60 c/B</td><td>471.46 c/B</td><td>649.71 c/B</td></tr>
      <tr><th colspan=5 align=center>riscvOVPsim+</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>310.37 c/B</td><td>344.30 c/B</td><td>461.14 c/B</td><td>621.14 c/B</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>285.71 c/B</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>c_opt64</code></td><td>277.21 c/B</td><td>307.99 c/B</td><td>431.01 c/B</td><td>584.95 c/B</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>265.59 c/B</td><td>292.46 c/B</td><td>459.70 c/B</td><td>635.20 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbb_shift</code>*</td><td>240.77 c/B</td><td>268.84 c/B</td><td>435.08 c/B</td><td>604.58 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbb_bi32_ror</code>*</td><td>222.52 c/B</td><td>231.87 c/B</td><td>325.01 c/B</td><td>437.51 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbkb_bi32_ror</code>*</td><td>172.71 c/B</td><td>190.46 c/B</td><td>298.51 c/B</td><td>411.01 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbp_bi32_ror</code>*</td><td>170.84 c/B</td><td>189.27 c/B</td><td>297.51 c/B</td><td>410.01 c/B</td></tr>
      <tr><td><code>asm_rv32_Zbt_fsr</code>*</td><td>160.77 c/B</td><td>178.84 c/B</td><td>285.08 c/B</td><td>394.58 c/B</td></tr>
    </tbody>
  </table>
</details>

<details>
  <summary>Performance difference in percent, for long inputs (32 kB)</summary>

  <table>
    <thead>
      <tr><th rowspan=2>Name</th><th rowspan=2>Ascon128a</th><th>Ascon128</th><th>AsconHasha</th><th>AsconHash</th></tr>
      <tr><th>Ascon80pq</th><th>AsconXofa</th><th>AsconXof</th></tr>
    </thead>
    <tbody>
      <tr><th colspan=5 align=center>ESP32</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>$\color{red}\text{+13.93 \%}$</td><td>$\color{red}\text{+9.92 \%}$</td><td>$\color{red}\text{+11.84 \%}$</td><td>$\color{red}\text{+11.56 \%}$</td></tr>
      <tr><td><code>c_opt64</code></td><td>ref</td><td>ref</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>asm_xtensa_bi32_ror</code>*</td><td>$\color{green}\text{-19.95 \%}$</td><td>$\color{green}\text{-27.38 \%}$</td><td>$\color{green}\text{-35.93 \%}$</td><td>$\color{green}\text{-38.15 \%}$</td></tr>
      <tr><td><code>asm_xtensa_fsr</code>*</td><td>$\color{green}\text{-66.65 \%}$</td><td>$\color{green}\text{-65.19 \%}$</td><td>$\color{green}\text{-64.04 \%}$</td><td>$\color{green}\text{-65.23 \%}$</td></tr>
      <tr><th colspan=5 align=center>ESP32-C3</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>$\color{red}\text{+10.50 \%}$</td><td>$\color{red}\text{+8.79 \%}$</td><td>$\color{red}\text{+8.12 \%}$</td><td>$\color{red}\text{+5.68 \%}$</td></tr>
      <tr><td><code>c_opt64</code></td><td>$\color{red}\text{+0.99 \%}$</td><td>ref</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>ref</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>$\color{green}\text{-5.77 \%}$</td><td>$\color{green}\text{-5.70 \%}$</td><td>$\color{green}\text{-4.39 \%}$</td><td>$\color{green}\text{-5.96 \%}$</td></tr>
      <tr><th colspan=5 align=center>riscvOVPsim+</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>$\color{red}\text{+9.69 \%}$</td><td>$\color{red}\text{+8.39 \%}$</td><td>$\color{red}\text{+7.58 \%}$</td><td>$\color{red}\text{+6.42 \%}$</td></tr>
      <tr><td><code>c_opt64</code></td><td>$\color{red}\text{+0.08 \%}$</td><td>ref</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>ref</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>$\color{green}\text{-6.19 \%}$</td><td>$\color{green}\text{-6.59 \%}$</td><td>$\color{green}\text{-5.76 \%}$</td><td>$\color{green}\text{-5.55 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbb_shift</code>*</td><td>$\color{green}\text{-17.29 \%}$</td><td>$\color{green}\text{-15.43 \%}$</td><td>$\color{green}\text{-11.52 \%}$</td><td>$\color{green}\text{-10.63 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbb_bi32_ror</code>*</td><td>$\color{green}\text{-25.75 \%}$</td><td>$\color{green}\text{-35.79 \%}$</td><td>$\color{green}\text{-51.00 \%}$</td><td>$\color{green}\text{-54.97 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbkb_bi32_ror</code>*</td><td>$\color{green}\text{-66.01 \%}$</td><td>$\color{green}\text{-65.23 \%}$</td><td>$\color{green}\text{-63.80 \%}$</td><td>$\color{green}\text{-63.85 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbp_bi32_ror</code>*</td><td>$\color{green}\text{-68.04 \%}$</td><td>$\color{green}\text{-66.59 \%}$</td><td>$\color{green}\text{-64.33 \%}$</td><td>$\color{green}\text{-64.21 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbt_fsr</code>*</td><td>$\color{green}\text{-78.12 \%}$</td><td>$\color{green}\text{-75.65 \%}$</td><td>$\color{green}\text{-71.20 \%}$</td><td>$\color{green}\text{-70.30 \%}$</td></tr>
    </tbody>
  </table>
</details>

<details>
  <summary>Performance difference in percent, for short inputs (16 B)</summary>

  <table>
    <thead>
      <tr><th rowspan=2>Name</th><th rowspan=2>Ascon128a</th><th>Ascon128</th><th>AsconHasha</th><th>AsconHash</th></tr>
      <tr><th>Ascon80pq</th><th>AsconXofa</th><th>AsconXof</th></tr>
    </thead>
    <tbody>
      <tr><th colspan=5 align=center>ESP32</th></tr>
      <tr><td><code>c_opt64</code></td><td>$\color{red}\text{+56.58 \%}$</td><td>$\color{red}\text{+49.54 \%}$</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>ref</td><td>ref</td><td>$\color{red}\text{+4.04 \%}$</td><td>$\color{red}\text{+4.10 \%}$</td></tr>
      <tr><td><code>asm_xtensa_bi32_ror</code>*</td><td>$\color{green}\text{-35.99 \%}$</td><td>$\color{green}\text{-42.11 \%}$</td><td>$\color{green}\text{-27.54 \%}$</td><td>$\color{green}\text{-27.72 \%}$</td></tr>
      <tr><td><code>asm_xtensa_fsr</code>*</td><td>$\color{green}\text{-85.93 \%}$</td><td>$\color{green}\text{-84.61 \%}$</td><td>$\color{green}\text{-54.40 \%}$</td><td>$\color{green}\text{-53.34 \%}$</td></tr>
      <tr><th colspan=5 align=center>ESP32-C3</th></tr>
      <tr><td><code>c_opt64</code></td><td>$\color{red}\text{+80.40 \%}$</td><td>$\color{red}\text{+62.37 \%}$</td><td>$\color{red}\text{+47.61 \%}$</td><td>$\color{red}\text{+91.51 \%}$</td></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>$\color{red}\text{+5.25 \%}$</td><td>ref</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>ref</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>$\color{green}\text{-10.88 \%}$</td><td>$\color{green}\text{-17.54 \%}$</td><td>$\color{green}\text{-0.30 \%}$</td><td>$\color{red}\text{+2.20 \%}$</td></tr>
      <tr><th colspan=5 align=center>riscvOVPsim+</th></tr>
      <tr><td><code>c_opt64_lowsize</code></td><td>$\color{red}\text{+10.68 \%}$</td><td>$\color{red}\text{+10.55 \%}$</td><td>$\color{red}\text{+6.53 \%}$</td><td>$\color{red}\text{+5.83 \%}$</td></tr>
      <tr><td><code>asm_rv32_campos</code></td><td>$\color{red}\text{+2.98 \%}$</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>
      <tr><td><code>c_opt64</code></td><td>ref</td><td>ref</td><td>ref</td><td>ref</td></tr>
      <tr><td><code>asm_rv32_shift</code>*</td><td>$\color{green}\text{-4.38 \%}$</td><td>$\color{green}\text{-5.31 \%}$</td><td>$\color{red}\text{+6.24 \%}$</td><td>$\color{red}\text{+7.91 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbb_shift</code>*</td><td>$\color{green}\text{-15.13 \%}$</td><td>$\color{green}\text{-14.57 \%}$</td><td>$\color{red}\text{+0.93 \%}$</td><td>$\color{red}\text{+3.25 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbb_bi32_ror</code>*</td><td>$\color{green}\text{-24.58 \%}$</td><td>$\color{green}\text{-32.83 \%}$</td><td>$\color{green}\text{-32.61 \%}$</td><td>$\color{green}\text{-33.70 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbkb_bi32_ror</code>*</td><td>$\color{green}\text{-60.51 \%}$</td><td>$\color{green}\text{-61.71 \%}$</td><td>$\color{green}\text{-44.39 \%}$</td><td>$\color{green}\text{-42.32 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbp_bi32_ror</code>*</td><td>$\color{green}\text{-62.27 \%}$</td><td>$\color{green}\text{-62.72 \%}$</td><td>$\color{green}\text{-44.87 \%}$</td><td>$\color{green}\text{-42.67 \%}$</td></tr>
      <tr><td><code>asm_rv32_Zbt_fsr</code>*</td><td>$\color{green}\text{-72.42 \%}$</td><td>$\color{green}\text{-72.22 \%}$</td><td>$\color{green}\text{-51.19 \%}$</td><td>$\color{green}\text{-48.25 \%}$</td></tr>
    </tbody>
  </table>
</details>
