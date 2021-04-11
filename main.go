package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

func main() {
	readmeContent, err := ioutil.ReadFile("./README.md")
	if err != nil {
		log.Panic(err)
	}

	var newReadmeContent string
	fmt.Println(3, "### Counting unit tests...")

	unittestTimeout := make(chan string, 1)

	go func() {
		cmd := exec.Command("bash", "-c", "go test -v -p 1 ./...")
		json, _ := cmd.CombinedOutput()
		unitTestCount := fmt.Sprint(strings.Count(string(json), "RUN"))
		fmt.Println(4, "### Unit test count: "+unitTestCount)
		unittestTimeout <- unitTestCount
	}()

	fmt.Println(4, "#### Replacing strings in readme")

	newReadmeContent = string(readmeContent)

	select {
	case res := <-unittestTimeout:
		newReadmeContent = writeBetween("unittestcount", newReadmeContent, `<img src="https://img.shields.io/badge/Unit_Tests-`+res+`-magenta?style=flat-square" alt="Unit test count">`)
	case <-time.After(time.Second * 10):
		fmt.Println(4, "Timeout in counting unit tests!")
	}

	currentDir, _ := os.Getwd()
	currentDirName := filepath.Base(currentDir)

	newReadmeContent = writeBetween("reponame", newReadmeContent, currentDirName)

	fmt.Println(4, "### Writing readme")
	err = ioutil.WriteFile("./README.md", []byte(newReadmeContent), 0600)
	if err != nil {
		log.Panic(err)
	}
}

func writeBetween(name string, original string, insertText string) string {
	beforeRegex := regexp.MustCompile(`(?ms).*<!-- ` + name + `:start -->`)
	afterRegex := regexp.MustCompile(`(?ms)<!-- ` + name + `:end -->.*`)
	before := beforeRegex.FindAllString(original, 1)[0]
	after := afterRegex.FindAllString(original, 1)[0]

	ret := before
	ret += insertText
	ret += after

	return ret
}
