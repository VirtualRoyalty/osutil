package osutil

import (
	"context"
	"io"
	"os"
	"os/signal"
	"syscall"
)

// ContextWithInterrupt returns a context which can be interrupted by signals "SIGTERM" and "SIGQUIT".
// If the signal is sent once, then the returned context is cancelled. If multiple signals are sent, then the program terminates via "os.Exit(1)".
func ContextWithInterrupt(ctx context.Context, logWriter io.Writer) (contextWithInterrupt context.Context, cancelContext context.CancelFunc) {
	contextWithInterrupt, cancelContext = context.WithCancel(ctx)

	c := make(chan os.Signal, 10)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGQUIT)
	go func() {
		count := 0
		for {
			switch <-c {
			case os.Interrupt, os.Kill:
				_, err := io.WriteString(logWriter, "Received termination signal")
				if err != nil {
					panic(err)
				}
				count++

				if count == 1 {
					_, err := io.WriteString(logWriter, "Canceling analysis and writing results")
					if err != nil {
						panic(err)
					}

					cancelContext()
				} else {
					_, err := io.WriteString(logWriter, "Exiting immediately")
					if err != nil {
						panic(err)
					}

					//revive:disable:deep-exit
					os.Exit(1)
					//revive:enable:deep-exit
				}
			}
		}
	}()

	return contextWithInterrupt, cancelContext
}
