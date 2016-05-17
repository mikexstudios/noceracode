// imp_gen
// NOTE: Generated mcr files need to be copy and pasted into CH Instrument's
// software since we are currently NOT writing the first byte to the file.
package main

import "fmt"
import "flag"

func main() {
	// What do we want to know?
	// NOTE: These are all pointers to the value, so use * to dereference it.
	ocp := flag.Float64("ocp", 0.0, "open circuit potential (starting V)")
	pstep := flag.Float64("pstep", 0.005, "potential value to increment/decrement (in V)")
	steps := flag.Int("steps", 4, "number of steps above and below the OCP")
	flag.Parse()

	fmt.Println(*ocp)
	fmt.Println(*pstep)
	fmt.Println(*steps)
}
