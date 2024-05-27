# How to run
- [Install wasmtime](https://github.com/bytecodealliance/wasmtime/tree/main?tab=readme-ov-file#installation)
- [Download custom go runtime](https://github.com/asubiotto/go/tree/asubiotto-determinism)
- Build custom go binary by navigation to go/src and running `./all.bash`

`./entropy.sh` is the main script. Check out main.go for the toy program that
is run. For deterministic executions running on WASM, specify a GORANDSEED and
the path to the custom go runtime:

```
$ GORANDSEED=123 ./entropy.sh -r /Users/asubiotto/Developer/github.com/asubiotto/go
Building project
GORANDSEED set to 123. Remember to set this env var if you want deterministic execution
Running benchmark...
Processing results...
1 distinct executions out of 1024 executions: score: 100.00%
Benchmark completed and results processed.
```

To run the same program with your version of go installed, simply run
`./entropy.sh`:
```
$ ./entropy.sh
Building project
GORANDSEED set to . Remember to set this env var if you want deterministic execution
Running benchmark...
Processing results...
1024 distinct executions out of 1024 executions: score: 0.00%
Benchmark completed and results processed.
```

# Suggestions
Can you break determinism? Feel free to open an issue against this repo. We're
aware that this approach for deterministic execution in Go is likely incomplete
and open to improving it.
