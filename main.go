package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/spf13/cobra"
)

const (
	workerFlagName = "workers"
	fileFlagName   = "file"
)

var dstCmd = &cobra.Command{
	Use: "dst",
	RunE: func(cmd *cobra.Command, args []string) error {
		nWorkers, err := cmd.Flags().GetInt(workerFlagName)
		if err != nil {
			return err
		}
		return dstInternal(nWorkers, os.Stdout)
	},
}

var entropyCmd = &cobra.Command{
	Use:  "entropy",
	Long: "Calculates the entropy of the file lines. If all lines are the same, result is 0, if all are different result is 100",
	RunE: func(cmd *cobra.Command, args []string) error {
		fileName, err := cmd.Flags().GetString(fileFlagName)
		if err != nil {
			return err
		}
		f, err := os.Open(fileName)
		if err != nil {
			return err
		}
		defer f.Close()
		s := bufio.NewScanner(f)
		distinct := make(map[string]struct{})
		lines := 0
		for s.Scan() {
			distinct[s.Text()] = struct{}{}
			lines++
		}
		fmt.Printf("%d distinct executions out of %d executions: score: %0.2f%% \n", len(distinct), lines, 101-(float64(len(distinct)-1)/float64(lines-1)*99+1))
		return nil
	},
}

func init() {
	dstCmd.Flags().Int(workerFlagName, 2, "Number of workers to spawn")
	entropyCmd.PersistentFlags().String(fileFlagName, "", "File to calculate entropy for")
	dstCmd.AddCommand(entropyCmd)
}

func main() {
	// runtime.GOMAXPROCS(1)
	if err := dstCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

// main spawns a couple of goroutines that each do some work and communicate
// over a channel to the main goroutine that records these interactions. The
// order is written to an external file that can be analyzed so that distinct
// run orders can be compared.
func dstInternal(nWorkers int, w io.Writer) error {
	orderChan := make(chan int, nWorkers)
	/*fmt.Println("sleeping in main goroutine")
	pprof.Lookup("goroutine").WriteTo(os.Stdout, 2)
	time.Sleep(10 * time.Second)*/
	var wg sync.WaitGroup
	wg.Add(nWorkers)
	for i := 0; i < nWorkers; i++ {
		id := i
		go func() {
			defer wg.Done()
			worker(id, orderChan)
		}()
	}
	wg.Wait()
	close(orderChan)
	order := make([]string, 0, nWorkers)
	for i := range orderChan {
		order = append(order, fmt.Sprintf("%d", i))
	}
	if _, err := w.Write([]byte(fmt.Sprintf("%s\n", strings.Join(order, "-")))); err != nil {
		return err
	}
	return nil
}

func worker(id int, orderChan chan<- int) {
	time.Sleep(1 * time.Millisecond)
	orderChan <- id
}
