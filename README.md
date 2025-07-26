# UVLLM: An Automated Universal Verification Framework using Large Language Model

Modified from [https://github.com/amyuch/UVLLM].
Add simplified enviroment and pixi commands.

## Platform pre-requisities

1. An x86-64 system (more cores will improve simulation time).
2. Linux operating system (we used Ubuntu 20.04).

## Dependencies Installation

Require pixi from [https://pixi.sh/dev/].

``` sh
git submodule update --init --recursive
pixi install
pixi run cp-errorset 
```

## Copy ErrorSet

UVLLM modifies the source file in-place, so copy is required before execution. Use `pixi run cp-errorset` to copy the errorset.

## Enviroment Variables

+ ARK_API_KEY: api key
+ DPSK_V3_ARK_MODEL: name of the model

## Reproduction

Needs three input options for execution:

* `--benchmark/-b`: the benchmark name. (ErrorSet for the example)

* `--project/-p`: the project name of DUT in the benchmark. (accu for the example)

* `--version/-v`: the error index for the DUT. (1 for the example)

```
Example: pixi run fix -b ErrorSet -p accu -v 1
```

For the total benchmark test, use:

```
Example: pixi run fix -b ErrorSet
```
