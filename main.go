package main

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/pterm/pterm"
)

func main() {
	logger := pterm.DefaultLogger.WithLevel(pterm.LogLevelInfo)

	logger.Info("Reading readme", logger.Args("path", "./README.md"))
	readmeContent, err := os.ReadFile("./README.md")
	if err != nil {
		logger.Fatal("Could not read README.md", logger.Args("error", err))
	}

	var newReadmeContent string
	logger.Info("Counting unit tests...")

	unittestTimeout := make(chan string, 1)

	go func() {
		cmd := exec.Command("bash", "-c", "go test -v -p 1 ./...")
		output, _ := cmd.CombinedOutput()
		unitTestCount := fmt.Sprint(strings.Count(string(output), "RUN"))
		logger.Info("Counted unit tests", logger.Args("count", unitTestCount))
		unittestTimeout <- unitTestCount
	}()

	logger.Info("Replacing strings in readme")

	newReadmeContent = string(readmeContent)

	select {
	case res := <-unittestTimeout:
		newReadmeContent = writeBetween("unittestcount", newReadmeContent, `<img src="https://img.shields.io/badge/Unit_Tests-`+res+`-magenta?style=flat-square" alt="Unit test count">`)
	case <-time.After(time.Minute):
		logger.Error("Unit test count timed out")
	}

	logger.Info("Writing readme")
	err = os.WriteFile("./README.md", []byte(newReadmeContent), 0600)
	if err != nil {
		logger.Fatal("Could not write README.md", logger.Args("error", err))
	}
}

func writeBetween(name string, original string, insertText string) string {
	beforeRegex := regexp.MustCompile(`(?ms).*<!-- ` + name + `:start -->`)
	afterRegex := regexp.MustCompile(`(?ms)<!-- ` + name + `:end -->.*`)
	before := beforeRegex.FindString(original)
	after := afterRegex.FindString(original)

	ret := before
	ret += insertText
	ret += after

	return ret
}
