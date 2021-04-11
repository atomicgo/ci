package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

func main() {
	readmeContent, err := ioutil.ReadFile("./README.md")
	if err != nil {
		log.Panic(err)
	}

	goModContent, err := ioutil.ReadFile("./go.mod")
	if err != nil {
		log.Panic(err)
	}

	repoNameMatches, _ := stringToMap(regexp.MustCompile(`(?m)module github\.com/atomicgo/(?P<repo>.*)`), string(goModContent))
	repoName := repoNameMatches["repo"]

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

	badges := strings.ReplaceAll(`<a href="https://github.com/atomicgo/%REPO%/releases">
<img src="https://img.shields.io/github/v/release/atomicgo/%REPO%?style=flat-square" alt="Latest Release">
</a>

<a href="https://codecov.io/gh/atomicgo/%REPO%" target="_blank">
<img src="https://img.shields.io/github/workflow/status/atomicgo/%REPO%/Go?label=tests&style=flat-square" alt="Tests">
</a>

<a href="https://codecov.io/gh/atomicgo/%REPO%" target="_blank">
<img src="https://img.shields.io/codecov/c/gh/atomicgo/%REPO%?color=magenta&logo=codecov&style=flat-square" alt="Coverage">
</a>

<a href="https://codecov.io/gh/atomicgo/%REPO%">
<!-- unittestcount:start --><img src="https://img.shields.io/badge/Unit_Tests-0-magenta?style=flat-square" alt="Unit test count"><!-- unittestcount:end -->
</a>

<a href="https://github.com/atomicgo/%REPO%/issues">
<img src="https://img.shields.io/github/issues/atomicgo/%REPO%.svg?style=flat-square" alt="Issues">
</a>`, "%REPO%", repoName)

	newReadmeContent = writeBetween("badges", newReadmeContent, badges)

	installScript := "```console\n# Execute this command inside your project\ngo get -u github.com/atomicgo/" + repoName + "\n```\n\n"

	newReadmeContent = writeBetween("install", installScript, badges)
	newReadmeContent = writeBetween("reponame", repoName, badges)

	select {
	case res := <-unittestTimeout:
		newReadmeContent = writeBetween("unittestcount", newReadmeContent, `<img src="https://img.shields.io/badge/Unit_Tests-`+res+`-magenta?style=flat-square" alt="Unit test count">`)
	case <-time.After(time.Second * 10):
		fmt.Println(4, "Timeout in counting unit tests!")
	}

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

func stringToMap(r *regexp.Regexp, s string) (map[string]string, error) {
	names := r.SubexpNames()
	result := r.FindAllStringSubmatch(s, -1)
	m := map[string]string{}
	for i, n := range result[0] {
		m[names[i]] = n
	}
	return m, nil
}
