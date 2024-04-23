package main

import "fmt"

// main spawns a couple of goroutines that each do some work and communicate
// over a channel to the main goroutine that records these interactions. The
// order is written to an external file that can be analyzed so that distinct
// run orders can be compared.
func main() {
	fmt.Println("Hello world")
}
